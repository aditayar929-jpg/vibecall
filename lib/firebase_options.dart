import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAplllPz9sZLAW_0PfNYQEbg6nL-z4_BJ4',
    appId: '1:737125569121:android:42e4d895ccf227f1e51020',
    messagingSenderId: '737125569121',
    projectId: 'vibecall-524e2',
    storageBucket: 'vibecall-524e2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '737125569121',
    projectId: 'vibecall-524e2',
    storageBucket: 'vibecall-524e2.firebasestorage.app',
    iosBundleId: 'com.vibecall.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: '737125569121',
    projectId: 'vibecall-524e2',
    storageBucket: 'vibecall-524e2.firebasestorage.app',
    authDomain: 'vibecall-524e2.firebaseapp.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: '737125569121',
    projectId: 'vibecall-524e2',
    storageBucket: 'vibecall-524e2.firebasestorage.app',
    iosBundleId: 'com.vibecall.app',
  );
}
