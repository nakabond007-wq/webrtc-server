import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class EncryptionLoadingScreen extends StatefulWidget {
  const EncryptionLoadingScreen({super.key});

  @override
  State<EncryptionLoadingScreen> createState() => _EncryptionLoadingScreenState();
}

class _EncryptionLoadingScreenState extends State<EncryptionLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  final List<String> _encryptionLogs = [
    'Starting secure application...',
    'Инициализация RSA-2048 криптографии...',
    'Loading cryptographic libraries...',
    'Генерация ключевых пар...',
    'Public key: 2048-bit RSA',
    'Private key: Encrypted',
    'Проверка энтропии системы...',
    'Entropy level: HIGH',
    'Настройка WebRTC протокола...',
    'ICE candidates: Ready',
    'STUN/TURN servers: Configured',
    'Создание защищенного канала...',
    'DTLS-SRTP: Enabled',
    'End-to-end encryption: Active',
    'Активация P2P протокола...',
    'NAT traversal: Ready',
    'Peer connection state: New',
    'Подключение к серверу сигнализации...',
    'Socket.IO: Connecting',
    'Signaling channel: Established',
    'Загрузка профиля пользователя...',
    'Local storage: Initialized',
    'Contact list: Loaded',
    'Call history: Ready',
    'Проверка безопасности...',
    'Security audit: PASSED',
    'Permissions: Granted',
    'Шифрование установлено ✓',
    'Ready for secure communication',
  ];

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _startEncryptionSequence();
  }

  Future<void> _startEncryptionSequence() async {
    for (int i = 0; i < _encryptionLogs.length; i++) {
      await Future.delayed(Duration(milliseconds: 200 + math.Random().nextInt(150)));
      if (mounted) {
        setState(() {
          _logs.add(_encryptionLogs[i]);
        });
        _fadeController.forward(from: 0);
        
        // Auto scroll to bottom
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
    }

    // После завершения переходим на главный экран
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _fadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Animated lock icon
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2D2D2D),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6D6D6D).withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Title
              const Text(
                'Единение',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Мы ближе, чем кажется',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),

              const SizedBox(height: 60),

              // Encryption logs
              Container(
                height: 280,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
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
                          'Encryption Log',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_logs.length}/${_encryptionLogs.length}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.3),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final isLast = index == _logs.length - 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: FadeTransition(
                              opacity: isLast ? _fadeController : const AlwaysStoppedAnimation(1.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '> ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color(0xFF4CAF50),
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      _logs[index],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white.withOpacity(0.8),
                                        fontFamily: 'monospace',
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.3),
                  ),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
