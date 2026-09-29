import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBwOYAgMNUmcNcDMv9JLhZZvB4J00FoEVQ',
    appId: '1:357048757419:web:a9fe37ed8c5814b8de1bee',
    messagingSenderId: '357048757419',
    projectId: 'sereno-ya',
    authDomain: 'sereno-ya.firebaseapp.com',
    storageBucket: 'sereno-ya.firebasestorage.app',
    measurementId: 'G-FHVT2X124Y',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDnm0evY5D2J910hIFo3PyKBEa8G4dBoos',
    appId: '1:357048757419:android:82d41e9bc581ac5ade1bee',
    messagingSenderId: '357048757419',
    projectId: 'sereno-ya',
    storageBucket: 'sereno-ya.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDD1WXmN7u0WkhU-HN4RAwhKa-uQ9dz72k',
    appId: '1:357048757419:ios:b75f4f65d127452fde1bee',
    messagingSenderId: '357048757419',
    projectId: 'sereno-ya',
    storageBucket: 'sereno-ya.firebasestorage.app',
    androidClientId: '357048757419-uikq8duo22h3ebhdr8fr1j4hn7cn5r27.apps.googleusercontent.com',
    iosClientId: '357048757419-tjlq0o78h9t29oore77mk3rh9arnd82e.apps.googleusercontent.com',
    iosBundleId: 'com.example.serenoYa',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDD1WXmN7u0WkhU-HN4RAwhKa-uQ9dz72k',
    appId: '1:357048757419:ios:b75f4f65d127452fde1bee',
    messagingSenderId: '357048757419',
    projectId: 'sereno-ya',
    storageBucket: 'sereno-ya.firebasestorage.app',
    androidClientId: '357048757419-uikq8duo22h3ebhdr8fr1j4hn7cn5r27.apps.googleusercontent.com',
    iosClientId: '357048757419-tjlq0o78h9t29oore77mk3rh9arnd82e.apps.googleusercontent.com',
    iosBundleId: 'com.example.serenoYa',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBwOYAgMNUmcNcDMv9JLhZZvB4J00FoEVQ',
    appId: '1:357048757419:web:80e1f3b1fc2c0085de1bee',
    messagingSenderId: '357048757419',
    projectId: 'sereno-ya',
    authDomain: 'sereno-ya.firebaseapp.com',
    storageBucket: 'sereno-ya.firebasestorage.app',
    measurementId: 'G-RR58262L19',
  );
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDnm0evY5D2J910hIFo3PyKBEa8G4dBoos',
    appId: '1:357048757419:web:1e164f5792cb5d4d7df1a3',
    messagingSenderId: '357048757419',
    projectId: 'sereno-ya',
    authDomain: 'sereno-ya.firebaseapp.com',
    storageBucket: 'sereno-ya.firebasestorage.app',
  );
}
