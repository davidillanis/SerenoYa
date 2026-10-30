import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/services/api/notification_service.dart';

void main() {
  test(
    'el canal y las notificaciones en primer plano usan el sonido Serenoya',
    () {
      expect(notificationChannel.id, 'serenoya_alerts_v1');
      expect(notificationChannel.name, 'Notificaciones Serenoya');
      expect(notificationChannel.description, 'Avisos de Serenoya');
      expect(notificationChannel.importance, Importance.high);
      expect(notificationChannel.playSound, isTrue);
      expect(
        notificationChannel.sound,
        isA<RawResourceAndroidNotificationSound>(),
      );
      expect(notificationChannel.sound?.sound, 'serenoya');

      expect(foregroundAndroidDetails.channelId, notificationChannel.id);
      expect(foregroundAndroidDetails.channelName, notificationChannel.name);
      expect(foregroundAndroidDetails.icon, 'ic_stat_notification');
      expect(
        foregroundAndroidDetails.channelDescription,
        notificationChannel.description,
      );
      expect(foregroundAndroidDetails.importance, Importance.high);
      expect(foregroundAndroidDetails.priority, Priority.high);
      expect(foregroundAndroidDetails.playSound, isTrue);
      expect(
        foregroundAndroidDetails.sound,
        isA<RawResourceAndroidNotificationSound>(),
      );
      expect(foregroundAndroidDetails.sound?.sound, 'serenoya');
    },
  );
}
