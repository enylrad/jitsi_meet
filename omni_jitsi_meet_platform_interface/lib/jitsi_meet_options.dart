import 'dart:collection';

import 'feature_flag/feature_flag_enum.dart';
import 'feature_flag/feature_flag_helper.dart';

class JitsiMeetingOptions {
  JitsiMeetingOptions({
    required this.room,
  });

  final String room;
  String? serverURL;
  String? subject;
  String? token;
  bool? audioMuted;
  bool? audioOnly;
  bool? videoMuted;
  String? userDisplayName;
  String? userEmail;
  String? iosAppBarRGBAColor;
  String? userAvatarURL;

  Map<String, dynamic>? webOptions; // options for web
  Map<FeatureFlagEnum, dynamic> featureFlags = HashMap();

  /// Get feature flags Map with keys as String instead of Enum
  /// Useful as an argument sent to the Kotlin/Swift code
  Map<String?, dynamic> getFeatureFlags() {
    Map<String?, dynamic> featureFlagsWithStrings = HashMap();

    featureFlags.forEach((key, value) {
      featureFlagsWithStrings[FeatureFlagHelper.featureFlags[key]] = value;
    });

    return featureFlagsWithStrings;
  }

  @override
  String toString() {
    return 'OMNI_JITSI - JitsiMeetingOptions { room: $room, serverURL: $serverURL, '
        'subject: $subject, token: $token, audioMuted: $audioMuted, '
        'audioOnly: $audioOnly, videoMuted: $videoMuted, '
        'userDisplayName: $userDisplayName, userEmail: $userEmail }';
  }
}
