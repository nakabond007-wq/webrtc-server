import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../models/call_state.dart';
import '../providers/call_provider.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    setState(() {
      _renderersInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent going back without ending call
        final callProvider = Provider.of<CallProvider>(context, listen: false);
        if (callProvider.callState != CallState.ended) {
          await callProvider.hangUp();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Consumer<CallProvider>(
            builder: (context, callProvider, child) {
              if (_renderersInitialized) {
                if (callProvider.localStream != null) {
                  _localRenderer.srcObject = callProvider.localStream;
                  // Log video track status
                  final videoTracks = callProvider.localStream!.getVideoTracks();
                  if (videoTracks.isNotEmpty) {
                    print('[CallScreen] Local video track enabled: ${videoTracks.first.enabled}');
                  }
                }
                if (callProvider.remoteStream != null) {
                  _remoteRenderer.srcObject = callProvider.remoteStream;
                  // Log remote video track status
                  final videoTracks = callProvider.remoteStream!.getVideoTracks();
                  if (videoTracks.isNotEmpty) {
                    print('[CallScreen] Remote video track enabled: ${videoTracks.first.enabled}');
                  }
                }
              }

              if (callProvider.callState == CallState.ended) {
                print('[CallScreen] Call ended, popping screen');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && Navigator.canPop(context)) {
                    print('[CallScreen] Navigating back to home');
                    Navigator.of(context).pop();
                  }
                });
                // Show black screen while transitioning
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              return Stack(
              children: [
                // Remote video (full screen)
                if (_renderersInitialized && callProvider.remoteStream != null)
                  Positioned.fill(
                    child: RTCVideoView(
                      _remoteRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  )
                else
                  // Waiting state
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade800,
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            size: 60,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _getCallStateText(callProvider.callState),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ],
                    ),
                  ),

                // Status bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.0),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getStateColor(callProvider.callState),
                            boxShadow: [
                              BoxShadow(
                                color: _getStateColor(callProvider.callState),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getCallStateText(callProvider.callState),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Local video preview
                if (_renderersInitialized && callProvider.localStream != null && callProvider.isVideoEnabled)
                  Positioned(
                    top: 80,
                    right: 20,
                    child: Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: RTCVideoView(
                          _localRenderer,
                          mirror: true,
                          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    ),
                  ),

                // Controls
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.black.withOpacity(0.0),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Microphone
                        _buildControlButton(
                          icon: callProvider.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          onPressed: callProvider.toggleMute,
                          isActive: !callProvider.isMuted,
                        ),

                        // Camera
                        _buildControlButton(
                          icon: callProvider.isVideoEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                          onPressed: callProvider.toggleVideo,
                          isActive: callProvider.isVideoEnabled,
                        ),

                        // Switch camera
                        _buildControlButton(
                          icon: Icons.flip_camera_ios_rounded,
                          onPressed: callProvider.switchCamera,
                          isActive: true,
                        ),

                        // End call
                        _buildEndCallButton(
                          onPressed: () async {
                            await callProvider.hangUp();
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ), // SafeArea
    ), // Scaffold (child of WillPopScope)
    ); // WillPopScope
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive 
              ? Colors.white.withOpacity(0.2) 
              : Colors.red.withOpacity(0.3),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildEndCallButton({required VoidCallback onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.call_end_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }

  Color _getStateColor(CallState state) {
    switch (state) {
      case CallState.calling:
        return Colors.orange;
      case CallState.ringing:
        return Colors.blue;
      case CallState.connected:
        return Colors.green;
      case CallState.ended:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCallStateText(CallState state) {
    switch (state) {
      case CallState.calling:
        return 'Вызов...';
      case CallState.ringing:
        return 'Звонит...';
      case CallState.connected:
        return 'Соединено';
      case CallState.ended:
        return 'Завершено';
      default:
        return 'Ожидание';
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }
}
