import '../../../../objectbox/objectbox_setup.dart';
import '../../domain/entities/work_session.dart';
import '../../../../objectbox.g.dart'; // To be generated

class ObjectBoxService {
  late final Box<WorkSession> _sessionBox;

  ObjectBoxService() {
    _sessionBox = ObjectBoxSetup.store.box<WorkSession>();
  }

  Future<List<WorkSession>> getAllSessions(String userId) async {
    final query = _sessionBox.query(WorkSession_.userId.equals(userId)).build();
    return query.find();
  }

  Future<WorkSession?> getSessionByDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query = _sessionBox
        .query(
          WorkSession_.userId
              .equals(userId)
              .and(WorkSession_.date.betweenDate(startOfDay, endOfDay)),
        )
        .build();

    final sessions = query.find();
    if (sessions.isNotEmpty) return sessions.first;
    return null;
  }

  Future<void> saveSession(WorkSession session) async {
    _sessionBox.put(session);
  }

  Future<List<WorkSession>> getUnsyncedSessions() async {
    final query = _sessionBox
        .query(WorkSession_.isSyncedWithFirebase.equals(false))
        .build();
    return query.find();
  }
}
