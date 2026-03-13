import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/home_providers.dart';
import '../../../../core/constants/fonts.gen.dart';

final historyProvider = FutureProvider((ref) async {
  final repo = ref.watch(workSessionRepositoryProvider);
  final timeViewModel = ref.read(timeViewModelProvider.notifier);
  // TimeViewModel sets the user id in _userId, let's extract it or use auth
  return repo.getAllSessions(timeViewModel.userId);
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 0) return "00:00:00";
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Work History')),
      body: historyAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(child: Text('No work history found.'));
          }

          // Sort by date descending
          sessions.sort((a, b) => b.date.compareTo(a.date));

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final dateStr = DateFormat('MMM d, yyyy').format(session.date);
              final checkInStr = session.checkInTime != null
                  ? DateFormat('hh:mm a').format(session.checkInTime!)
                  : '--:--';
              final checkOutStr = session.checkOutTime != null
                  ? DateFormat('hh:mm a').format(session.checkOutTime!)
                  : 'Active';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateStr,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontFamily: FontFamily.poppins,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: session.checkOutTime != null
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              session.checkOutTime != null
                                  ? 'Completed'
                                  : 'Active',
                              style: TextStyle(
                                color: session.checkOutTime != null
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimeColumn(context, 'Check In', checkInStr),
                          _buildTimeColumn(context, 'Check Out', checkOutStr),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Work: ${_formatDuration(session.workDuration)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: FontFamily.inter,
                            ),
                          ),
                          Text(
                            'Break: ${_formatDuration(session.totalBreakDuration)}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontFamily: FontFamily.inter,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTimeColumn(BuildContext context, String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontFamily: FontFamily.inter,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
