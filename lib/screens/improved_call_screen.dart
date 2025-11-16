import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../providers/call_provider.dart';
import '../services/encryption_service.dart';

class ImprovedCallScreen extends StatefulWidget {
  const ImprovedCallScreen({super.key});

  @override
  State<ImprovedCallScreen> createState() => _ImprovedCallScreenState();
}

class _ImprovedCallScreenState extends State<ImprovedCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final EncryptionService _encryption = EncryptionService();
  bool _showEncryptionInfo = false;
  DateTime? _callStartTime;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _callStartTime = DateTime.now();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _encryption.generateKeyPair();
    setState(() {});
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<CallProvider>(
        builder: (context, callProvider, child) {
          if (callProvider.localStream != null) {
            _localRenderer.srcObject = callProvider.localStream;
          }
          if (callProvider.remoteStream != null) {
            _remoteRenderer.srcObject = callProvider.remoteStream;
          }

          return Stack(
            children: [
              // Remote video (full screen)
              if (callProvider.remoteStream != null)
                Positioned.fill(
                  child: RTCVideoView(_remoteRenderer, mirror: false),
                )
              else
                Container(
                  color: Colors.grey[900],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue[700],
                          child: const Icon(Icons.person, size: 80, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Ожидание подключения...',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),

              // Top bar with encryption info
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                    bottom: 24,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock, color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            StreamBuilder(
                              stream: Stream.periodic(const Duration(seconds: 1)),
                              builder: (context, snapshot) {
                                if (_callStartTime == null) return const Text('');
                                final duration = DateTime.now().difference(_callStartTime!);
                                return Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _showEncryptionInfo = !_showEncryptionInfo;
                          });
                        },
                        icon: const Icon(Icons.info_outline, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Encryption info overlay
              if (_showEncryptionInfo)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showEncryptionInfo = false;
                      });
                    },
                    child: Container(
                      color: Colors.black87,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user,
                                color: Colors.green,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Сквозное шифрование',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildKeyInfo('Ваш ключ', _encryption.getKeyFingerprint()),
                              const SizedBox(height: 16),
                              _buildKeyInfo(
                                'Ключ собеседника',
                                _encryption.getPeerKeyFingerprint() ?? 'Недоступен',
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Сверьте ключи с собеседником для подтверждения безопасности',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _showEncryptionInfo = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text('Закрыть'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Local video (small preview)
              if (callProvider.localStream != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Switch to full screen local video
                    },
                    child: Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: RTCVideoView(_localRenderer, mirror: true),
                      ),
                    ),
                  ),
                ),

              // Bottom controls
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 24,
                    top: 40,
                    left: 24,
                    right: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(
                        icon: callProvider.isMuted ? Icons.mic_off : Icons.mic,
                        label: callProvider.isMuted ? 'Вкл. микрофон' : 'Выкл. микрофон',
                        onPressed: () => callProvider.toggleMute(),
                        color: callProvider.isMuted ? Colors.red : Colors.white,
                      ),
                      _buildControlButton(
                        icon: Icons.cameraswitch,
                        label: 'Камера',
                        onPressed: () => callProvider.switchCamera(),
                      ),
                      _buildControlButton(
                        icon: callProvider.isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                        label: callProvider.isVideoEnabled ? 'Выкл. видео' : 'Вкл. видео',
                        onPressed: () => callProvider.toggleVideo(),
                        color: callProvider.isVideoEnabled ? Colors.white : Colors.red,
                      ),
                      _buildControlButton(
                        icon: Icons.call_end,
                        label: 'Завершить',
                        onPressed: () async {
                          await callProvider.hangUp();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        color: Colors.red,
                        isLarge: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKeyInfo(String title, String fingerprint) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  fingerprint,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: Colors.blue),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: fingerprint));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ключ скопирован')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.white,
    bool isLarge = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isLarge ? 70 : 56,
          height: isLarge ? 70 : 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color == Colors.red ? Colors.red : Colors.white24,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: isLarge ? 32 : 24),
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
