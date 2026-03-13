import 'package:path_provider/path_provider.dart';
import '../../objectbox.g.dart';
import 'package:path/path.dart' as p;

class ObjectBoxSetup {
  static late final Store store;

  static Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final storePath = p.join(docsDir.path, "office_time_tracker_db");

    if (Store.isOpen(storePath)) {
      store = Store.attach(getObjectBoxModel(), storePath);
    } else {
      store = await openStore(directory: storePath);
    }
  }
}
