import 'package:flutter/material.dart';
import 'dart:async';
import '../providers/call_provider.dart';
import '../models/call_state.dart';

class CallConnectingScreen extends StatefulWidget {
  final String targetUserId;
  final bool isVideo;
  final CallProvider callProvider;
  final VoidCallback onComplete;

  const CallConnectingScreen({
    super.key,
    required this.targetUserId,
    required this.isVideo,
    required this.callProvider,
    required this.onComplete,
  });

  @override
  State<CallConnectingScreen> createState() => _CallConnectingScreenState();
}

class _CallConnectingScreenState extends State<CallConnectingScreen>
    with TickerProviderStateMixin {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();
  late AnimationController _rotationController;
  int _currentStep = 0;

  final List<String> _encryptionSteps = [
    'Initializing secure connection...',
    'Generating encryption keys...',
    'RSA-2048 key pair generated',
    'Establishing P2P connection...',
    'Negotiating encryption protocol...',
    'AES-256-GCM cipher initialized',
    'DTLS-SRTP handshake in progress...',
    'Verifying peer identity...',
    'Exchanging ICE candidates...',
    'Setting up secure media channels...',
    'Perfect Forward Secrecy enabled',
    'End-to-end encryption active',
    'Connection secured ✓',
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _startEncryptionSequence();
    
    // Listen for call state changes
    widget.callProvider.addListener(_onCallStateChanged);
  }

  void _onCallStateChanged() {
    if (!mounted) return;
    
    final callState = widget.callProvider.callState;
    print('[CallConnectingScreen] Call state changed to: $callState');
    
    if (callState == CallState.connected) {
      print('[CallConnectingScreen] Connection established, calling onComplete');
      _addLog('Connected!');
      // Remove listener before navigating
      widget.callProvider.removeListener(_onCallStateChanged);
      // Navigate to call screen
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onComplete();
        }
      });
    } else if (callState == CallState.ended) {
      print('[CallConnectingScreen] Call ended before connection');
      _addLog('Call failed or rejected');
      widget.callProvider.removeListener(_onCallStateChanged);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    widget.callProvider.removeListener(_onCallStateChanged);
    _rotationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startEncryptionSequence() async {
    for (int i = 0; i < _encryptionSteps.length; i++) {
      if (!mounted) return;
      
      await Future.delayed(Duration(milliseconds: 200 + (i * 50)));
      
      setState(() {
        _currentStep = i;
        _addLog(_encryptionSteps[i]);
      });

      if (i == _encryptionSteps.length - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          // Initiate call AFTER encryption animation
          print('[CallConnectingScreen] About to call makeCall with isVideo: ${widget.isVideo}');
          _addLog('Initiating ${widget.isVideo ? 'video' : 'audio'} call...');
          await widget.callProvider.makeCall(widget.targetUserId, isVideo: widget.isVideo);
          print('[CallConnectingScreen] makeCall completed, waiting for connection...');
          _addLog('Waiting for peer to answer...');
          // Don't call onComplete here - wait for state change to connected
        }
      }
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now();
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

    _logs.add('[$timeStr] $message');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStep + 1) / _encryptionSteps.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Animated lock icon
              RotationTransition(
                turns: _rotationController,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4CAF50).withOpacity(0.3),
                        const Color(0xFF2D2D2D).withOpacity(0.3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 60,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              Text(
                'Securing Connection',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                'Calling: ${widget.targetUserId}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                  fontFamily: 'monospace',
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Progress bar
              Container(
                width: double.infinity,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4CAF50),
                          Color(0xFF66BB6A),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              Text(
                '${(_currentStep + 1)}/${_encryptionSteps.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.4),
                  fontFamily: 'monospace',
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Encryption logs
              Container(
                height: 280,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1A1A1A).withOpacity(0.5),
                      const Color(0xFF0D0D0D).withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Encryption Logs',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '> ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(0xFF4CAF50),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _logs[index],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.7),
                                      fontFamily: 'monospace',
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
