import 'package:wakelock_plus/wakelock_plus.dart';

class ScreenAwakeService {
  Future<void> setEnabled(bool enabled) => WakelockPlus.toggle(enable: enabled);
}
