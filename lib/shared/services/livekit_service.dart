import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveKitService {
  // TODO: Replace with your Render/Railway deployed URL
  static const String _serverUrl = 'https://vibecall-server.onrender.com';

  Room? _room;
  LocalVideoTrack? _localVideo;
  LocalAudioTrack? _localAudio;
  EventsListener<RoomEvent>? _roomListener;

  Room? get room => _room;
  LocalVideoTrack? get localVideo => _localVideo;
  LocalAudioTrack? get localAudio => _localAudio;
  bool get isConnected => _room?.connectionState == ConnectionState.connected;

  List<RemoteParticipant> get remoteParticipants =>
      _room?.remoteParticipants.values.toList() ?? [];

  // Callbacks
  void Function(RemoteParticipant)? onRemoteConnected;
  void Function(RemoteParticipant)? onRemoteDisconnected;

  // ─── GET TOKEN FROM SERVER ────────────────────────────────────
  Future<String> _getToken({
    required String roomName,
    String? metadata,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final identity = user?.uid ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    final name = user?.displayName ?? 'User';

    final response = await http.post(
      Uri.parse('$_serverUrl/api/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identity': identity,
        'name': name,
        'roomName': roomName,
        'metadata': metadata ?? '',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['token'];
    }
    throw Exception('Failed to get token: ${response.body}');
  }

  // ─── JOIN MATCH QUEUE (Server-side) ──────────────────────────
  Future<Map<String, dynamic>> joinMatchQueue({
    String callType = 'video',
    String gender = '',
    int age = 18,
    List<String> interests = const [],
    String genderFilter = 'All',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final identity = user?.uid ?? 'anonymous';

    final response = await http.post(
      Uri.parse('$_serverUrl/api/match/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identity': identity,
        'name': user?.displayName ?? 'User',
        'gender': gender,
        'age': age,
        'interests': interests,
        'genderFilter': genderFilter,
        'callType': callType,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Match queue error: ${response.body}');
  }

  // ─── LEAVE MATCH QUEUE ──────────────────────────────────────
  Future<void> leaveMatchQueue({String callType = 'video'}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final identity = user?.uid ?? 'anonymous';

      await http.post(
        Uri.parse('$_serverUrl/api/match/leave'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identity': identity,
          'callType': callType,
        }),
      );
    } catch (_) {}
  }

  // ─── CONNECT TO ROOM ────────────────────────────────────────
  Future<Room> connectToRoom({
    required String roomName,
    String? token,
    bool enableVideo = true,
    bool enableAudio = true,
  }) async {
    // Get token from server if not provided
    final authToken = token ?? await _getToken(roomName: roomName);

    final roomOptions = RoomOptions(
      adaptiveStream: true,
      dynacast: true,
    );

    _room = Room(roomOptions: roomOptions);
    _roomListener = _room!.createListener();

    // Listen for participant events
    _roomListener!.on<ParticipantConnectedEvent>((event) {
      onRemoteConnected?.call(event.participant as RemoteParticipant);
    });

    _roomListener!.on<ParticipantDisconnectedEvent>((event) {
      onRemoteDisconnected?.call(event.participant as RemoteParticipant);
    });

    await _room!.connect(
      'wss://${Uri.parse(_serverUrl).host}',
      authToken,
    );

    if (enableVideo) {
      _localVideo = await LocalVideoTrack.createCameraTrack();
      await _room!.localParticipant!.publishVideoTrack(_localVideo!);
    }

    if (enableAudio) {
      _localAudio = await LocalAudioTrack.create();
      await _room!.localParticipant!.publishAudioTrack(_localAudio!);
    }

    return _room!;
  }

  // ─── DISCONNECT ──────────────────────────────────────────────
  Future<void> disconnect() async {
    try {
      await _localVideo?.stop();
      await _localAudio?.stop();
      _localVideo?.dispose();
      _localAudio?.dispose();
      _localVideo = null;
      _localAudio = null;
      _roomListener?.dispose();
      await _room?.disconnect();
      _room = null;
    } catch (_) {}
  }

  // ─── TOGGLE CAMERA ──────────────────────────────────────────
  Future<void> toggleCamera() async {
    if (_localVideo != null) {
      final enabled = _localVideo!.mediaStreamTrack.enabled;
      _localVideo!.mediaStreamTrack.enabled = !enabled;
    }
  }

  // ─── TOGGLE MIC ─────────────────────────────────────────────
  Future<void> toggleMic() async {
    if (_localAudio != null) {
      final enabled = _localAudio!.mediaStreamTrack.enabled;
      _localAudio!.mediaStreamTrack.enabled = !enabled;
    }
  }

  // ─── FLIP CAMERA ────────────────────────────────────────────
  Future<void> flipCamera() async {
    if (_localVideo != null) {
      // ignore: avoid_dynamic_calls
      await (_localVideo! as dynamic).switchCamera();
    }
  }

  // ─── SEND DATA (for chat, reactions) ────────────────────────
  Future<void> sendData(String data) async {
    if (_room?.localParticipant != null) {
      await _room!.localParticipant!.publishData(
        utf8.encode(data),
      );
    }
  }
}
