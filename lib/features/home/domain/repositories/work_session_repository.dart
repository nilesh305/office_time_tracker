import '../../domain/entities/work_session.dart';

abstract class WorkSessionRepository {
  Future<List<WorkSession>> getAllSessions(String userId);
  Future<WorkSession?> getSessionByDate(String userId, DateTime date);
  Future<void> saveSession(WorkSession session);
  Future<List<WorkSession>> getUnsyncedSessions();
  Future<void> markAsSynced(int sessionId);
  Future<void> syncDownSessions(String userId);
}
