import 'dart:io';
import 'package:flutter/services.dart';

class SystemBridge {
  static const MethodChannel _channel = MethodChannel('com.chessd.app/system');

  static Future<bool> openExternalUrl(String url) async {
    try {
      if (Platform.isAndroid) {
        final opened = await _channel.invokeMethod<bool>('openUrl', {'url': url});
        return opened ?? false;
      } else if (Platform.isWindows) {
        await Process.start('cmd', ['/c', 'start', '', url], mode: ProcessStartMode.detached);
        return true;
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
        return true;
      } else if (Platform.isMacOS) {
        await Process.start('open', [url], mode: ProcessStartMode.detached);
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  static Future<void> requestAndroidNotificationPermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('requestNotificationPermission');
    } catch (_) {}
  }

  static Future<bool> showAndroidUpdateNotification({
    required String title,
    required String body,
    required String url,
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final shown = await _channel.invokeMethod<bool>('showUpdateNotification', {
        'title': title,
        'body': body,
        'url': url,
      });
      return shown ?? false;
    } catch (_) {
      return false;
    }
  }
}
