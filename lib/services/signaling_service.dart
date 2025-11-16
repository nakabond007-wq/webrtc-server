import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SignalingService {
  late IO.Socket socket;
  late RTCPeerConnection peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? mySocketId;
  dynamic _incomingOffer; // Store incoming offer data
  bool _incomingCallIsVideo = true; // Store incoming call type
  
  final StreamController<MediaStream> _remoteStreamController = StreamController<MediaStream>.broadcast();
  final StreamController<String> _callStateController = StreamController<String>.broadcast();
  final StreamController<String> _socketIdController = StreamController<String>.broadcast();
  final StreamController<String> _incomingCallController = StreamController<String>.broadcast();
  
  Stream<MediaStream> get remoteStreamStream => _remoteStreamController.stream;
  Stream<String> get callStateStream => _callStateController.stream;
  Stream<String> get socketIdStream => _socketIdController.stream;
  Stream<String> get incomingCallStream => _incomingCallController.stream;
  bool get isIncomingVideoCall => _incomingCallIsVideo;

  final Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
          'stun:stun3.l.google.com:19302',
          'stun:stun4.l.google.com:19302',
        ]
      },
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject'
      }
    ]
  };

  final Map<String, dynamic> offerSdpConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  SignalingService();

  void connect(String serverUrl) {
    // Use Render.com server URL
    final String productionServer = 'https://webrtc-server-rtre.onrender.com';
    
    socket = IO.io(productionServer, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to signaling server');
      mySocketId = socket.id;
      print('My Socket ID: $mySocketId');
    });

    socket.on('short-id', (data) {
      mySocketId = data.toString();
      print('My Short ID: $mySocketId');
      _socketIdController.add(mySocketId!);
    });

    socket.onDisconnect((_) {
      print('Disconnected from signaling server');
    });

    socket.onReconnect((_) {
      print('Reconnected to signaling server');
    });

    socket.on('offer', (data) async {
      print('Incoming call from: ${data['callerId']}');
      _incomingCallIsVideo = data['isVideo'] ?? true;
      print('Call type: ${_incomingCallIsVideo ? "video" : "audio"}');
      _incomingCallController.add(data['callerId']);
      _incomingOffer = data; // Store offer to process later when user accepts
    });

    socket.on('answer', (data) async {
      await handleAnswer(data);
    });

    socket.on('ice-candidate', (data) async {
      await handleIceCandidate(data);
    });

    socket.on('call-ended', (_) {
      print('[SignalingService] ========== RECEIVED call-ended FROM SERVER ==========');
      cleanup();
    });
  }

  Future<void> initializePeerConnection() async {
    peerConnection = await createPeerConnection(configuration);

    peerConnection.onIceCandidate = (RTCIceCandidate candidate) {
      socket.emit('ice-candidate', {
        'candidate': candidate.toMap(),
      });
    };

    peerConnection.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
        _remoteStreamController.add(remoteStream!);
      }
    };

    peerConnection.onIceConnectionState = (RTCIceConnectionState state) {
      print('ICE connection state: $state');
    };
  }

  Future<void> openUserMedia({bool enableVideo = true}) async {
    print('[SignalingService] openUserMedia called with enableVideo: $enableVideo');
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': enableVideo ? {
        'facingMode': 'user',
      } : false,
    };
    print('[SignalingService] mediaConstraints: $mediaConstraints');

    try {
      localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      
      localStream!.getTracks().forEach((track) {
        peerConnection.addTrack(track, localStream!);
      });
    } catch (e) {
      print('Error accessing media devices: $e');
    }
  }

  Future<void> makeCall(String targetUserId, {bool enableVideo = true}) async {
    print('[SignalingService] makeCall called with enableVideo: $enableVideo');
    await initializePeerConnection();
    await openUserMedia(enableVideo: enableVideo);

    RTCSessionDescription offer = await peerConnection.createOffer(offerSdpConstraints);
    await peerConnection.setLocalDescription(offer);

    socket.emit('offer', {
      'targetUserId': targetUserId,
      'offer': offer.toMap(),
      'isVideo': enableVideo,
    });

    _callStateController.add('calling');
  }

  Future<void> handleOffer(dynamic data) async {
    print('[SignalingService] handleOffer called, data[isVideo]: ${data['isVideo']}, _incomingCallIsVideo: $_incomingCallIsVideo');
    await initializePeerConnection();
    final isVideo = data['isVideo'] ?? _incomingCallIsVideo;
    print('[SignalingService] handleOffer computed isVideo: $isVideo');
    await openUserMedia(enableVideo: isVideo);

    RTCSessionDescription offer = RTCSessionDescription(
      data['offer']['sdp'],
      data['offer']['type'],
    );

    await peerConnection.setRemoteDescription(offer);

    RTCSessionDescription answer = await peerConnection.createAnswer(offerSdpConstraints);
    await peerConnection.setLocalDescription(answer);

    socket.emit('answer', {
      'targetUserId': data['callerId'],
      'answer': answer.toMap(),
    });

    _callStateController.add('connected');
  }

  Future<void> handleAnswer(dynamic data) async {
    // Check signaling state before setting remote description
    final signalingState = await peerConnection.getSignalingState();
    print('[SignalingService] handleAnswer - Current signaling state: $signalingState');
    
    if (signalingState == RTCSignalingState.RTCSignalingStateStable) {
      print('[SignalingService] Already in stable state, connection already established');
      _callStateController.add('connected');
      return;
    }
    
    if (signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      print('[SignalingService] Wrong state for answer: $signalingState, expected HaveLocalOffer');
      return;
    }
    
    try {
      RTCSessionDescription answer = RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );

      await peerConnection.setRemoteDescription(answer);
      print('[SignalingService] Remote description set successfully');
      _callStateController.add('connected');
    } catch (e) {
      print('[SignalingService] Error setting remote description: $e');
      // Even if setting description fails, if we're already connected, continue
      final iceState = await peerConnection.getConnectionState();
      if (iceState == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        print('[SignalingService] Connection already established despite error');
        _callStateController.add('connected');
      }
    }
  }

  Future<void> handleIceCandidate(dynamic data) async {
    if (!_isPeerConnectionInitialized) {
      print('PeerConnection not initialized yet, skipping ICE candidate');
      return;
    }
    
    RTCIceCandidate candidate = RTCIceCandidate(
      data['candidate']['candidate'],
      data['candidate']['sdpMid'],
      data['candidate']['sdpMLineIndex'],
    );

    await peerConnection.addCandidate(candidate);
  }

  Future<void> acceptIncomingCall() async {
    if (_incomingOffer != null) {
      await handleOffer(_incomingOffer);
      _incomingOffer = null;
    }
  }

  bool get _isPeerConnectionInitialized {
    try {
      // ignore: unnecessary_null_comparison
      return peerConnection != null;
    } catch (e) {
      return false;
    }
  }

  void toggleMute() {
    if (localStream != null) {
      final audioTrack = localStream!.getAudioTracks().first;
      audioTrack.enabled = !audioTrack.enabled;
    }
  }

  void toggleVideo(bool enabled) {
    if (localStream != null && localStream!.getVideoTracks().isNotEmpty) {
      final videoTrack = localStream!.getVideoTracks().first;
      videoTrack.enabled = enabled;
      print('[SignalingService] Video track enabled: $enabled');
    }
  }

  Future<void> switchCamera() async {
    if (localStream != null) {
      final videoTrack = localStream!.getVideoTracks().first;
      await Helper.switchCamera(videoTrack);
    }
  }

  Future<void> hangUp() async {
    print('[SignalingService] ========== HANG UP CALLED ==========');
    
    // Notify server that we're ending the call
    try {
      socket.emit('call-ended', {'fromUserId': mySocketId});
      print('[SignalingService] Sent call-ended event to server');
    } catch (e) {
      print('[SignalingService] Error sending call-ended: $e');
    }
    
    // Clean up local resources
    await _performCleanup();
  }

  Future<void> cleanup() async {
    print('[SignalingService] ========== CLEANUP (from remote) ==========');
    await _performCleanup();
  }

  Future<void> _performCleanup() async {
    print('[SignalingService] Performing cleanup...');
    
    try {
      localStream?.getTracks().forEach((track) {
        track.stop();
      });
    } catch (e) {
      print('[SignalingService] Error stopping local tracks: $e');
    }
    
    try {
      remoteStream?.getTracks().forEach((track) {
        track.stop();
      });
    } catch (e) {
      print('[SignalingService] Error stopping remote tracks: $e');
    }

    try {
      if (_isPeerConnectionInitialized) {
        await peerConnection.close();
      }
    } catch (e) {
      print('[SignalingService] Error closing peer connection: $e');
    }
    
    try {
      localStream?.dispose();
      remoteStream?.dispose();
    } catch (e) {
      print('[SignalingService] Error disposing streams: $e');
    }
    
    localStream = null;
    remoteStream = null;
    
    print('[SignalingService] Broadcasting ended state');
    _callStateController.add('ended');
    print('[SignalingService] ========== CLEANUP COMPLETE ==========');
  }

  void dispose() {
    socket.disconnect();
    socket.dispose();
    _remoteStreamController.close();
    _callStateController.close();
    _socketIdController.close();
    _incomingCallController.close();
  }
}
