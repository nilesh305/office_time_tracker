import 'dart:async';

import '../../domain/entities/work_session.dart';
import '../../domain/repositories/work_session_repository.dart';
import '../datasources/local_datasource.dart';
import '../datasources/remote_datasource.dart';

class WorkSessionRepositoryImpl implements WorkSessionRepository {
  final ObjectBoxService _localDataSource;
  final FirebaseService _remoteDataSource;

  WorkSessionRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<List<WorkSession>> getAllSessions(String userId) {
    return _localDataSource.getAllSessions(userId);
  }

  @override
  Future<WorkSession?> getSessionByDate(String userId, DateTime date) {
    return _localDataSource.getSessionByDate(userId, date);
  }

  @override
  Future<void> saveSession(WorkSession session) async {
    session.isSyncedWithFirebase = false;
    await _localDataSource.saveSession(session);
    unawaited(_syncSessionInBackground(session));
  }

  @override
  Future<List<WorkSession>> getUnsyncedSessions() {
    return _localDataSource.getUnsyncedSessions();
  }

  @override
  Future<void> markAsSynced(int sessionId) async {
    // ... Implement if needed, though handled in saveSession mostly ...
  }

  @override
  Future<void> syncDownSessions(String userId) async {
    try {
      final remoteSessionsMap = await _remoteDataSource.fetchAllUserSessionsMap(
        userId,
      );
      for (var map in remoteSessionsMap) {
        if (map['date'] != null) {
          final date = DateTime.parse(map['date'] as String);
          final existingSession = await _localDataSource.getSessionByDate(
            userId,
            date,
          );

          if (existingSession == null) {
            // Restore from Firebase
            final newSession = WorkSession(
              userId: userId,
              date: date,
              checkInTime: map['checkIn'] != null
                  ? DateTime.tryParse(map['checkIn'])
                  : null,
              checkOutTime: map['checkOut'] != null
                  ? DateTime.tryParse(map['checkOut'])
                  : null,
              totalBreakDuration: map['breakDuration'] as int? ?? 0,
              workDuration: map['workDuration'] as int? ?? 0,
              breakLogsJson: map['breakLogsJson'] as String? ?? '[]',
              isSyncedWithFirebase: true,
            );
            await _localDataSource.saveSession(newSession);
          } else if (existingSession.isSyncedWithFirebase) {
            existingSession.checkInTime = map['checkIn'] != null
                ? DateTime.tryParse(map['checkIn'] as String)
                : null;
            existingSession.checkOutTime = map['checkOut'] != null
                ? DateTime.tryParse(map['checkOut'] as String)
                : null;
            existingSession.totalBreakDuration =
                map['breakDuration'] as int? ?? 0;
            existingSession.workDuration = map['workDuration'] as int? ?? 0;
            existingSession.breakLogsJson =
                map['breakLogsJson'] as String? ?? '[]';
            existingSession.isSyncedWithFirebase = true;
            await _localDataSource.saveSession(existingSession);
          }
        }
      }
    } catch (e) {
      // Sync down failed (offline or other issue), gracefully ignore
    }
  }

  Future<void> _syncSessionInBackground(WorkSession session) async {
    try {
      await _remoteDataSource.syncSession(session);
      session.isSyncedWithFirebase = true;
      await _localDataSource.saveSession(session);
    } catch (_) {
      // Keep the session marked as unsynced for a later retry.
    }
  }
}
