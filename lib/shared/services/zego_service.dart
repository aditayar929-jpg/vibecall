import 'package:firebase_auth/firebase_auth.dart';

/// ZEGOCLOUD video/audio call service.
///
/// Get your AppID + AppSign from https://console.zegocloud.com
/// Then uncomment zego_uikit_prebuilt_call in pubspec.yaml
/// and add the imports below:
///
///   import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
///   import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
class ZegoService {
  // TODO: Replace with your ZEGOCLOUD credentials
  static const int appID = 0; // e.g. 123456789
  static const String appSign = ''; // e.g. 'abc123...'

  static bool _initialized = false;

  /// Initialize ZEGOCLOUD with Firebase user
  static Future<void> initialize() async {
    if (_initialized) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // TODO: Uncomment after adding zego_uikit_prebuilt_call to pubspec.yaml
    // ZegoUIKitPrebuiltCallInvitationService().init(
    //   appID: appID,
    //   appSign: appSign,
    //   userID: user.uid,
    //   userName: user.displayName ?? 'User_${user.uid.substring(0, 6)}',
    //   plugins: [
    //     ZegoUIKitSignalingPlugin(),
    //   ],
    // );

    _initialized = true;
  }

  /// Get current user ID for ZEGOCLOUD
  static String get userId {
    return FirebaseAuth.instance.currentUser?.uid ??
        'guest_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String get userName {
    return FirebaseAuth.instance.currentUser?.displayName ?? 'User';
  }

  /// Dispose ZEGOCLOUD
  static void dispose() {
    // TODO: Uncomment after adding zego_uikit_prebuilt_call to pubspec.yaml
    // ZegoUIKitPrebuiltCallInvitationService().uninit();
    _initialized = false;
  }
}
