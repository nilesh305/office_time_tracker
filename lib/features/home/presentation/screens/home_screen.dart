import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/home_providers.dart';
import '../viewmodels/time_viewmodel.dart';
import '../../../../core/constants/fonts.gen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 0) return "00:00:00";
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    return DateFormat('hh:mm a').format(time);
  }

  void _showBreakLogsSheet(
    BuildContext context,
    TimeViewModel viewModel,
    String logsJson,
  ) {
    try {
      final List<dynamic> logs = jsonDecode(logsJson);
      final breakList = logs.map((e) => e as Map<String, dynamic>).toList();

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Break Logs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (breakList.isEmpty)
                    const Text('No breaks taken today.')
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: breakList.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final log = breakList[index];
                          final start = DateTime.parse(log['startTime']);
                          final end = log['endTime'] != null
                              ? DateTime.parse(log['endTime'])
                              : null;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Start: ',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final time = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.fromDateTime(
                                              start,
                                            ),
                                          );
                                          if (time != null) {
                                            viewModel.updateBreakLog(
                                              index,
                                              DateTime(
                                                start.year,
                                                start.month,
                                                start.day,
                                                time.hour,
                                                time.minute,
                                              ),
                                              end,
                                            );
                                            Navigator.pop(
                                              context,
                                            ); // Refresh UI
                                          }
                                        },
                                        child: Text(
                                          _formatTime(start),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'End:   ',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      if (end != null)
                                        GestureDetector(
                                          onTap: () async {
                                            final time = await showTimePicker(
                                              context: context,
                                              initialTime:
                                                  TimeOfDay.fromDateTime(end),
                                            );
                                            if (time != null) {
                                              viewModel.updateBreakLog(
                                                index,
                                                start,
                                                DateTime(
                                                  end.year,
                                                  end.month,
                                                  end.day,
                                                  time.hour,
                                                  time.minute,
                                                ),
                                              );
                                              Navigator.pop(
                                                context,
                                              ); // Refresh UI
                                            }
                                          },
                                          child: Text(
                                            _formatTime(end),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      else
                                        const Text(
                                          'Active',
                                          style: TextStyle(
                                            color: Colors.orange,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              if (end != null)
                                Text(
                                  _formatDuration(
                                    end.difference(start).inSeconds,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeState = ref.watch(timeViewModelProvider);
    final timeViewModel = ref.read(timeViewModelProvider.notifier);

    final todayStr = DateFormat('EEEE, MMMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Office Time Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Section
              Text(
                'Today',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(todayStr, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 32),

              // Main Card
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(
                      'Work Time',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _formatDuration(timeState.workDuration),
                      style: const TextStyle(
                        fontFamily: FontFamily.inter,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Time',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDuration(
                                timeState.workDuration +
                                    timeState.totalBreakTime,
                              ),
                              style: const TextStyle(
                                fontFamily: FontFamily.inter,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            if (timeState.breakLogsJson == '[]') return;
                            _showBreakLogsSheet(
                              context,
                              timeViewModel,
                              timeState.breakLogsJson,
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  if (timeState.breakLogsJson != '[]')
                                    const Icon(
                                      Icons.list,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  Text(
                                    ' Break Time',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDuration(timeState.totalBreakTime),
                                style: const TextStyle(
                                  fontFamily: FontFamily.inter,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Sub-card for Check In / Check Out details
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        if (timeState.checkInTime == null) return;
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            timeState.checkInTime!,
                          ),
                        );
                        if (time != null) {
                          final now = DateTime.now();
                          timeViewModel.updateCheckInTime(
                            DateTime(
                              now.year,
                              now.month,
                              now.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Check In ',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                              const Icon(
                                Icons.edit,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(timeState.checkInTime),
                            style: const TextStyle(
                              fontFamily: FontFamily.inter,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        if (timeViewModel.isCompleted) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            final now = DateTime.now();
                            timeViewModel.updateCheckOutTime(
                              DateTime(
                                now.year,
                                now.month,
                                now.day,
                                time.hour,
                                time.minute,
                              ),
                            );
                          }
                        } else if (timeState.isWorking) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please Check Out first to edit check-out time.',
                              ),
                            ),
                          );
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              if (timeViewModel.isCompleted)
                                const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              Text(
                                ' Check Out',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeViewModel.isCompleted ? 'Completed' : 'Active',
                            style: TextStyle(
                              fontFamily: FontFamily.inter,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: timeViewModel.isCompleted
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Buttons Section
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: timeViewModel.isCompleted
                            ? Colors.grey.shade300
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: timeViewModel.isCompleted
                            ? Colors.grey.shade600
                            : Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: timeViewModel.isCompleted
                          ? null
                          : () {
                              if (!timeState.isWorking) {
                                timeViewModel.checkIn();
                              } else {
                                timeViewModel.checkOut();
                              }
                            },
                      child: Text(
                        timeViewModel.isCompleted
                            ? 'Completed'
                            : (timeState.isWorking ? 'Check Out' : 'Check In'),
                        style: const TextStyle(
                          fontFamily: FontFamily.poppins,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor:
                            (!timeState.isWorking || timeViewModel.isCompleted)
                            ? Colors.grey.shade300
                            : (timeState.isOnBreak
                                  ? Colors.blue
                                  : Colors.orange),
                        foregroundColor:
                            (!timeState.isWorking || timeViewModel.isCompleted)
                            ? Colors.grey.shade600
                            : Colors.white,
                      ),
                      onPressed:
                          (!timeState.isWorking || timeViewModel.isCompleted)
                          ? null
                          : () {
                              if (timeState.isOnBreak) {
                                timeViewModel.endBreak();
                              } else {
                                timeViewModel.startBreak();
                              }
                            },
                      child: Text(
                        timeState.isOnBreak ? 'End Break' : 'Start Break',
                        style: const TextStyle(
                          fontFamily: FontFamily.poppins,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
