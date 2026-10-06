import 'dart:js_interop';

@JS('loadSerenoGoogleMaps')
external JSPromise<JSAny?> _loadGoogleMaps(JSString apiKey);

Future<void> loadGoogleMaps(String apiKey) async {
  await _loadGoogleMaps(apiKey.toJS).toDart;
}
