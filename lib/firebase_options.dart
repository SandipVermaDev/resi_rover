// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC9endmbZhQ_uRozvGCj4Gv-FcrcthnJx8',
    appId: '1:904777032259:web:2afdeca84131a1d87beaf6',
    messagingSenderId: '904777032259',
    projectId: 'resirover-1d24d',
    authDomain: 'resirover-1d24d.firebaseapp.com',
    storageBucket: 'resirover-1d24d.appspot.com',
    measurementId: 'G-F2XBYCES0X',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD3MhD5RMeeGTbRmr-b2f7m1FC_WhhfGEM',
    appId: '1:904777032259:android:579df8ff1fe038017beaf6',
    messagingSenderId: '904777032259',
    projectId: 'resirover-1d24d',
    storageBucket: 'resirover-1d24d.appspot.com',
  );
}
