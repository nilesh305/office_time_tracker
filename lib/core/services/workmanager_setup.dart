import 'package:workmanager/workmanager.dart';
import '../../objectbox/objectbox_setup.dart';
import '../../features/home/data/datasources/local_datasource.dart';
import '../../features/home/data/datasources/remote_datasource.dart';

const workTimerUpdateTask = 'workTimerUpdate';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == workTimerUpdateTask) {
      // Background logic
      await ObjectBoxSetup.init();
      final local = ObjectBoxService();
      final remote = FirebaseService();

      final unsynced = await local.getUnsyncedSessions();
      for (var session in unsynced) {
        if (session.checkOutTime != null) {
          try {
            await remote.syncSession(session);
            session.isSyncedWithFirebase = true;
            await local.saveSession(session);
          } catch (e) {
            // failed to sync
          }
        }
      }

      // Update home widget logic here if applicable
    }
    return Future.value(true);
  });
}

class WorkmanagerSetup {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);

    // Register a periodic task
    await Workmanager().registerPeriodicTask(
      'workTimerUpdate-id',
      workTimerUpdateTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
