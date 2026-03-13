import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/work_session.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> syncSession(WorkSession session) async {
    final dateStr =
        "${session.date.year}-${session.date.month.toString().padLeft(2, '0')}-${session.date.day.toString().padLeft(2, '0')}";
    final docRef = _firestore
        .collection('users')
        .doc(session.userId)
        .collection('sessions')
        .doc(dateStr);

    await docRef.set({
      'sessionId': session.id,
      'checkIn': session.checkInTime?.toIso8601String(),
      'checkOut': session.checkOutTime?.toIso8601String(),
      'breakDuration': session.totalBreakDuration,
      'workDuration': session.workDuration,
      'date': session.date.toIso8601String(),
      'breakLogsJson': session.breakLogsJson,
    });
  }

  Future<List<Map<String, dynamic>>> fetchAllUserSessionsMap(
    String userId,
  ) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }
}
