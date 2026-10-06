import 'package:flutter/foundation.dart';

abstract final class MapsConfig {
  static const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}
