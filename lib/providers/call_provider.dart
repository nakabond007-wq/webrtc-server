import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call_state.dart';
import '../services/signaling_service.dart';
import '../services/encryption_service.dart';

class CallProvider with ChangeNotifier {
  final SignalingService _signalingService = SignalingService();
  
  CallState _callState = CallState.idle;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isVideoCall = true;
  String? _mySocketId;
  String? _incomingCallerId;

  CallState get callState => _callState;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isVideoCall => _isVideoCall;
  String? get mySocketId => _mySocketId;
  String? get incomingCallerId => _incomingCallerId;
  String get myEncryptionKey => EncryptionService().getKeyFingerprint();

  CallProvider() {
    _signalingService.remoteStreamStream.listen((stream) {
      _remoteStream = stream;
      notifyListeners();
    });

    _signalingService.callStateStream.listen((state) {
      print('[CallProvider] ========== STATE CHANGED: $state ==========');
      switch (state) {
        case 'calling':
          _callState = CallState.calling;
          break;
        case 'connected':
          _callState = CallState.connected;
          break;
        case 'ended':
          print('[CallProvider] Received ended state');
          _callState = CallState.ended;
          _localStream = null;
          _remoteStream = null;
          _isVideoEnabled = true;
          _isMuted = false;
          break;
      }
      print('[CallProvider] Notifying listeners with state: $_callState');
      notifyListeners();
    });

    _signalingService.socketIdStream.listen((id) {
      _mySocketId = id;
      notifyListeners();
    });

    _signalingService.incomingCallStream.listen((callerId) {
      print('Incoming call notification from: $callerId');
      _incomingCallerId = callerId;
      _callState = CallState.ringing;
      notifyListeners();
    });
  }

  void connectToSignalingServer(String serverUrl) {
    _signalingService.connect(serverUrl);
  }

  Future<void> makeCall(String targetUserId, {bool isVideo = true}) async {
    print('[CallProvider] makeCall called with isVideo: $isVideo');
    _isVideoCall = isVideo;
    _isVideoEnabled = isVideo;
    _callState = CallState.calling;
    notifyListeners();
    
    await _signalingService.makeCall(targetUserId, enableVideo: isVideo);
    _localStream = _signalingService.localStream;
    print('[CallProvider] makeCall - localStream set, isVideoEnabled: $_isVideoEnabled');
    notifyListeners();
  }

  Future<void> makeVideoCall(String targetUserId) async {
    await makeCall(targetUserId, isVideo: true);
  }

  Future<void> makeAudioCall(String targetUserId) async {
    await makeCall(targetUserId, isVideo: false);
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _signalingService.toggleMute();
    notifyListeners();
  }

  Future<void> switchCamera() async {
    await _signalingService.switchCamera();
    notifyListeners();
  }

  void toggleVideo() {
    _isVideoEnabled = !_isVideoEnabled;
    _signalingService.toggleVideo(_isVideoEnabled);
    // Update local stream reference to trigger UI update
    _localStream = _signalingService.localStream;
    print('[CallProvider] Video toggled to: $_isVideoEnabled');
    notifyListeners();
  }

  Future<void> hangUp() async {
    await _signalingService.hangUp();
    _cleanup();
  }

  Future<void> acceptCall() async {
    _callState = CallState.connected;
    await _signalingService.acceptIncomingCall();
    
    // Wait a bit for streams to be ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    _localStream = _signalingService.localStream;
    _remoteStream = _signalingService.remoteStream;
    
    // Set video enabled based on call type
    _isVideoEnabled = _signalingService.isIncomingVideoCall;
    print('[CallProvider] acceptCall - isVideoEnabled set to: $_isVideoEnabled');
    
    notifyListeners();
  }

  Future<void> rejectCall() async {
    await _signalingService.hangUp();
    _cleanup();
  }

  void _cleanup() {
    _localStream = null;
    _remoteStream = null;
    _callState = CallState.idle;
    _isMuted = false;
    _isVideoEnabled = true;
    _isVideoCall = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _signalingService.dispose();
    super.dispose();
  }
}
