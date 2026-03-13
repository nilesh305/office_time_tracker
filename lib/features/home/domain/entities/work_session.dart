import 'package:objectbox/objectbox.dart';

@Entity()
class WorkSession {
  @Id()
  int id;

  String userId;
  DateTime date;
  @Property(type: PropertyType.date)
  DateTime? checkInTime;
  @Property(type: PropertyType.date)
  DateTime? checkOutTime;
  @Property(type: PropertyType.date)
  DateTime? breakStartTime;

  int totalBreakDuration; // in seconds
  int workDuration; // in seconds
  bool isSyncedWithFirebase; // Sync flag
  String breakLogsJson;

  WorkSession({
    this.id = 0,
    required this.userId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.breakStartTime,
    this.totalBreakDuration = 0,
    this.workDuration = 0,
    this.isSyncedWithFirebase = false,
    this.breakLogsJson = '[]',
  });
}
