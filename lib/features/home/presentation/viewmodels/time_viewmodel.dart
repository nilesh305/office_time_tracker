import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/work_session.dart';
import '../../domain/repositories/work_session_repository.dart';
import '../providers/home_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class TimeState {
  final bool isWorking;
  final bool isOnBreak;
  final DateTime? checkInTime;
  final DateTime? breakStartTime;
  final int totalBreakTime; // in seconds
  final int workDuration; // in seconds
  final String breakLogsJson;

  TimeState({
    this.isWorking = false,
    this.isOnBreak = false,
    this.checkInTime,
    this.breakStartTime,
    this.totalBreakTime = 0,
    this.workDuration = 0,
    this.breakLogsJson = '[]',
  });

  TimeState copyWith({
    bool? isWorking,
    bool? isOnBreak,
    DateTime? checkInTime,
    DateTime? breakStartTime,
    int? totalBreakTime,
    int? workDuration,
    String? breakLogsJson,
  }) {
    return TimeState(
      isWorking: isWorking ?? this.isWorking,
      isOnBreak: isOnBreak ?? this.isOnBreak,
      checkInTime: checkInTime ?? this.checkInTime,
      breakStartTime: breakStartTime ?? this.breakStartTime,
      totalBreakTime: totalBreakTime ?? this.totalBreakTime,
      workDuration: workDuration ?? this.workDuration,
      breakLogsJson: breakLogsJson ?? this.breakLogsJson,
    );
  }
}

class TimeViewModel extends Notifier<TimeState> {
  late final WorkSessionRepository _repository;
  late final String _userId;
  WorkSession? _currentSession;
  Timer? _ticker;

  String get userId => _userId;

  @override
  TimeState build() {
    _repository = ref.watch(workSessionRepositoryProvider);
    final authState = ref.watch(authViewModelProvider);
    _userId = authState.user?.id ?? 'unknown_user';

    // We launch initial load asynchronously
    Future.microtask(() => _loadCurrentSession());
    return TimeState();
  }

  Future<void> _loadCurrentSession() async {
    // Run sync down in background or await it to ensure we have latest history
    try {
      await _repository.syncDownSessions(_userId);
    } catch (_) {}

    final today = DateTime.now();
    _currentSession = await _repository.getSessionByDate(_userId, today);

    if (_currentSession != null) {
      state = state.copyWith(
        isWorking:
            _currentSession!.checkOutTime == null &&
            _currentSession!.checkInTime != null,
        isOnBreak: _currentSession!.breakStartTime != null,
        checkInTime: _currentSession!.checkInTime,
        breakStartTime: _currentSession!.breakStartTime,
        totalBreakTime: _currentSession!.totalBreakDuration,
        workDuration: _currentSession!.workDuration,
        breakLogsJson: _currentSession!.breakLogsJson,
      );
      if (state.isWorking) {
        _startTicker();
      } else if (isCompleted) {
        state = state.copyWith(isWorking: false, isOnBreak: false);
      }
    }
  }

  bool get isCompleted => _currentSession?.checkOutTime != null;

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isWorking && !state.isOnBreak) {
        computeWorkingTime();
      } else if (state.isOnBreak && state.breakStartTime != null) {
        final currentBreakDur = DateTime.now()
            .difference(state.breakStartTime!)
            .inSeconds;
        state = state.copyWith(
          totalBreakTime:
              (_currentSession?.totalBreakDuration ?? 0) + currentBreakDur,
        );
      }
    });
  }

  Future<void> checkIn() async {
    if (isCompleted) return; // Only 1 session per day allowed
    final now = DateTime.now();
    // If a session exists but isn't completed, we just resume it (handled by load)
    if (_currentSession == null) {
      _currentSession = WorkSession(
        userId: _userId,
        date: now,
        checkInTime: now,
      );
      await _repository.saveSession(_currentSession!);
    }

    state = state.copyWith(
      isWorking: true,
      checkInTime: _currentSession!.checkInTime,
    );
    _startTicker();
  }

  Future<void> startBreak() async {
    if (!state.isWorking || state.isOnBreak || isCompleted) return;

    final now = DateTime.now();
    _currentSession?.breakStartTime = now;

    // Add new incomplete break loop to JSON logs
    final logs = _parseBreakLogs(_currentSession!.breakLogsJson);
    logs.add({'startTime': now.toIso8601String(), 'endTime': null});
    _currentSession!.breakLogsJson = jsonEncode(logs);

    await _repository.saveSession(_currentSession!);

    state = state.copyWith(isOnBreak: true, breakStartTime: now);
  }

  Future<void> endBreak() async {
    if (!state.isOnBreak ||
        _currentSession?.breakStartTime == null ||
        isCompleted)
      return;

    final now = DateTime.now();

    // Close off the last opened break block in JSON
    final logs = _parseBreakLogs(_currentSession!.breakLogsJson);
    if (logs.isNotEmpty && logs.last['endTime'] == null) {
      logs.last['endTime'] = now.toIso8601String();
    }

    _updateBreakLogsAndDuration(logs);
    _currentSession!.breakStartTime = null;
    await _repository.saveSession(_currentSession!);

    state = state.copyWith(
      isOnBreak: false,
      breakStartTime: null,
      totalBreakTime: _currentSession!.totalBreakDuration,
    );
    computeWorkingTime();
  }

  Future<void> checkOut() async {
    if (!state.isWorking || isCompleted) return;

    final now = DateTime.now();
    if (state.isOnBreak) {
      await endBreak();
    }

    computeWorkingTime(); // Final calculation

    _currentSession!.checkOutTime = now;
    _currentSession!.workDuration = state.workDuration;
    await _repository.saveSession(_currentSession!);

    state = state.copyWith(isWorking: false);
    _ticker?.cancel();
  }

  void computeWorkingTime() {
    if (state.checkInTime == null) return;

    final endToUse = _currentSession?.checkOutTime ?? DateTime.now();

    int currentBreakToSubtract = state.totalBreakTime;

    final elapsed = endToUse.difference(state.checkInTime!).inSeconds;
    final workSeconds = elapsed - currentBreakToSubtract;

    state = state.copyWith(workDuration: workSeconds > 0 ? workSeconds : 0);
  }

  List<Map<String, dynamic>> _parseBreakLogs(String jsonStr) {
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  void _updateBreakLogsAndDuration(List<Map<String, dynamic>> newLogs) {
    if (_currentSession == null) return;

    _currentSession!.breakLogsJson = jsonEncode(newLogs);

    // Recalculate total break duration based on completed logs
    int totalDur = 0;
    for (var log in newLogs) {
      if (log['endTime'] != null) {
        final start = DateTime.parse(log['startTime']);
        final end = DateTime.parse(log['endTime']);
        totalDur += end.difference(start).inSeconds;
      }
    }
    _currentSession!.totalBreakDuration = totalDur;
    state = state.copyWith(totalBreakTime: totalDur);
  }

  Future<void> updateCheckInTime(DateTime newCheckIn) async {
    if (_currentSession == null) return;

    // Prevent check in from being after checkout
    if (_currentSession!.checkOutTime != null &&
        newCheckIn.isAfter(_currentSession!.checkOutTime!))
      return;

    _currentSession!.checkInTime = newCheckIn;
    state = state.copyWith(checkInTime: newCheckIn);
    computeWorkingTime();

    if (_currentSession!.checkOutTime != null) {
      _currentSession!.workDuration = state.workDuration;
    }

    await _repository.saveSession(_currentSession!);
  }

  Future<void> updateCheckOutTime(DateTime newCheckOut) async {
    if (_currentSession == null || _currentSession!.checkOutTime == null)
      return;

    if (newCheckOut.isBefore(_currentSession!.checkInTime!)) return;

    _currentSession!.checkOutTime = newCheckOut;
    computeWorkingTime();
    _currentSession!.workDuration = state.workDuration;

    await _repository.saveSession(_currentSession!);
  }

  Future<void> updateBreakLog(
    int index,
    DateTime newStart,
    DateTime? newEnd,
  ) async {
    if (_currentSession == null) return;

    final logs = _parseBreakLogs(_currentSession!.breakLogsJson);
    if (index >= 0 && index < logs.length) {
      logs[index]['startTime'] = newStart.toIso8601String();
      if (newEnd != null) logs[index]['endTime'] = newEnd.toIso8601String();

      _updateBreakLogsAndDuration(logs);
      computeWorkingTime();
      if (_currentSession!.checkOutTime != null) {
        _currentSession!.workDuration = state.workDuration;
      }
      await _repository.saveSession(_currentSession!);
    }
  }

  void dispose() {
    _ticker?.cancel();
  }
}
