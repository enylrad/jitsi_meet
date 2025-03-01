import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'jitsi_meet_platform_interface.dart';

const MethodChannel _channel = MethodChannel('jitsi_meet');

const EventChannel _eventChannel = const EventChannel('jitsi_meet_events');

/// An implementation of [JitsiMeetPlatform] that uses method channels.
class MethodChannelJitsiMeet extends JitsiMeetPlatform {
  bool _eventChannelIsInitialized = false;
  JitsiMeetingListener? _listener;

  @override
  Future<JitsiMeetingResponse> joinMeeting(
    JitsiMeetingOptions options, {
    JitsiMeetingListener? listener,
  }) async {
    // Attach a listener if it exists. The key is based on the serverURL + room
    _listener = listener;

    if (!_eventChannelIsInitialized) {
      _initialize();
    }

    Map<String, dynamic> _options = {
      'room': options.room.trim(),
      'serverURL': options.serverURL?.trim(),
      'subject': options.subject,
      'token': options.token,
      'audioMuted': options.audioMuted,
      'audioOnly': options.audioOnly,
      'videoMuted': options.videoMuted,
      'featureFlags': options.getFeatureFlags(),
      'userDisplayName': options.userDisplayName,
      'userEmail': options.userEmail,
      'iosAppBarRGBAColor': options.iosAppBarRGBAColor,
    };

    return await _channel
        .invokeMethod<String>('joinMeeting', _options)
        .then((message) => JitsiMeetingResponse(
              isSuccess: true,
              message: message,
            ))
        .catchError(
      (error) {
        return JitsiMeetingResponse(
          isSuccess: true,
          message: error.toString(),
          error: error,
        );
      },
    );
  }

  void _initialize() {
    _eventChannel.receiveBroadcastStream().listen((message) {
      final data = message['data'];
      switch (message['event']) {
        case "opened":
          _listener?.onOpened?.call();
          break;
        case "onPictureInPictureWillEnter":
          _listener?.onPictureInPictureWillEnter?.call();
          break;
        case "onPictureInPictureTerminated":
          _listener?.onPictureInPictureTerminated?.call();
          break;
        case "conferenceWillJoin":
          _listener?.onConferenceWillJoin?.call(data["url"]);
          break;
        case "conferenceJoined":
          _listener?.onConferenceJoined?.call(data["url"]);
          break;
        case "conferenceTerminated":
          _listener?.onConferenceTerminated?.call(data["url"], data["error"]);
          break;
        case "audioMutedChanged":
          _listener?.onAudioMutedChanged?.call(parseBool(data["muted"]));
          break;
        case "videoMutedChanged":
          _listener?.onVideoMutedChanged?.call(parseBool(data["muted"]));
          break;
        case "screenShareToggled":
          _listener?.onScreenShareToggled
              ?.call(data["participantId"], parseBool(data["sharing"]));
          break;
        case "participantJoined":
          _listener?.onParticipantJoined?.call(
            data["email"],
            data["name"],
            data["role"],
            data["participantId"],
          );
          break;
        case "participantLeft":
          _listener?.onParticipantLeft?.call(data["participantId"]);
          break;
        case "participantsInfoRetrieved":
          _listener?.onParticipantsInfoRetrieved?.call(
            data["participantsInfo"],
            data["requestId"],
          );
          break;
        case "chatMessageReceived":
          _listener?.onChatMessageReceived?.call(
            data["senderId"],
            data["message"],
            parseBool(data["isPrivate"]),
          );
          break;
        case "chatToggled":
          _listener?.onChatToggled?.call(parseBool(data["isOpen"]));
          break;
        case "closed":
          _listener?.onClosed?.call();
          _listener = null;
          break;
      }
    }).onError((error) {
      debugPrint(
          "OMNI_JITSI: Error receiving data from the event channel: $error");
      _listener?.onError?.call(error);
    });
    _eventChannelIsInitialized = true;
  }

  @override
  closeMeeting() {
    _channel.invokeMethod('closeMeeting');
  }

  @override
  void executeCommand(String command, List<String> args) {}

  @override
  Widget buildView(List<String> extraJS) => const SizedBox.shrink();
}

bool parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) return value == 'true';
  if (value is num) return value != 0;
  throw ArgumentError('OMNI_JITSI: Unsupported type: $value');
}
