import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/call_state.dart';
import '../models/call_history.dart';
import '../providers/call_provider.dart';
import '../services/notification_service.dart';
import '../services/call_history_service.dart';
import '../services/encryption_service.dart';
import '../services/contact_service.dart';
import '../services/theme_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/neon_button.dart';
import 'call_screen.dart';
import 'call_history_screen.dart';
import 'contacts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _serverController = TextEditingController(
    text: 'http://10.0.2.2:3000', // Android emulator localhost
  );
  final TextEditingController _targetUserController = TextEditingController();
  CallProvider? _callProvider;
  final NotificationService _notificationService = NotificationService();
  final CallHistoryService _historyService = CallHistoryService();
  final EncryptionService _encryptionService = EncryptionService();
  final ContactService _contactService = ContactService();
  bool _hasShownDialog = false;
  String _myEncryptionKey = '';
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize notifications and request permission
    _initializeNotifications();
    _initializeEncryption();
    _loadContacts();
    
    // Connect to signaling server on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _callProvider = Provider.of<CallProvider>(context, listen: false);
      _callProvider!.connectToSignalingServer(_serverController.text);
      _addLog('Connecting to signaling server...');
    });
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    _addLog('Notifications initialized');
  }

  Future<void> _initializeEncryption() async {
    await _encryptionService.generateKeyPair();
    setState(() {
      _myEncryptionKey = _encryptionService.getKeyFingerprint();
    });
    _addLog('Encryption key generated: $_myEncryptionKey');
  }

  Future<void> _loadContacts() async {
    await _contactService.loadContacts();
    _addLog('Contacts loaded: ${_contactService.contacts.length} contacts');
  }

  void _addLog(String message) {
    final timestamp = DateTime.now();
    final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    setState(() {
      _logs.add('[$timeStr] $message');
      if (_logs.length > 50) {
        _logs.removeAt(0);
      }
    });
    // Auto scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for incoming calls
    final callProvider = Provider.of<CallProvider>(context);
    
    if (callProvider.callState == CallState.ringing && 
        !_hasShownDialog && 
        callProvider.incomingCallerId != null) {
      _hasShownDialog = true;
      _addLog('Incoming call from ${callProvider.incomingCallerId}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showIncomingCallDialog(callProvider);
          // Show notification
          _notificationService.showIncomingCallNotification(
            callerId: callProvider.incomingCallerId!,
            onAccept: () async {
              await callProvider.acceptCall();
            },
            onDecline: () async {
              await callProvider.rejectCall();
            },
          );
        }
      });
    } else if (callProvider.callState != CallState.ringing) {
      _hasShownDialog = false;
      _notificationService.cancelIncomingCallNotification();
    }
  }

  void _showIncomingCallDialog(CallProvider callProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade600.withOpacity(0.95),
                    Colors.indigo.shade700.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Входящий звонок',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      callProvider.incomingCallerId ?? "Неизвестный",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildIncomingCallButton(
                        icon: Icons.call_end_rounded,
                        color: const Color(0xFF2D2D2D),
                        label: 'Отклонить',
                        onPressed: () async {
                          Navigator.pop(context);
                          _notificationService.cancelIncomingCallNotification();
                          
                          final myId = callProvider.mySocketId ?? 'Unknown';
                          final callerId = callProvider.incomingCallerId ?? 'Unknown';
                          await _historyService.addCall(CallHistory(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            callerId: callerId,
                            receiverId: myId,
                            timestamp: DateTime.now(),
                            duration: Duration.zero,
                            type: CallType.incoming,
                            status: CallStatus.rejected,
                          ));
                          
                          await callProvider.rejectCall();
                          _hasShownDialog = false;
                        },
                      ),
                      _buildIncomingCallButton(
                        icon: Icons.videocam_rounded,
                        color: const Color(0xFF4D4D4D),
                        label: 'Видео',
                        onPressed: () async {
                          await _acceptCall(callProvider, context, isVideo: true);
                        },
                      ),
                      _buildIncomingCallButton(
                        icon: Icons.phone_rounded,
                        color: const Color(0xFF5D5D5D),
                        label: 'Аудио',
                        onPressed: () async {
                          await _acceptCall(callProvider, context, isVideo: false);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomingCallButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(35),
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(35),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _acceptCall(CallProvider callProvider, BuildContext context, {required bool isVideo}) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    _notificationService.cancelIncomingCallNotification();
    _hasShownDialog = false;
    
    final myId = callProvider.mySocketId ?? 'Unknown';
    final callerId = callProvider.incomingCallerId ?? 'Unknown';
    _addLog('Accepting ${isVideo ? 'video' : 'audio'} call from $callerId');
    
    await _historyService.addCall(CallHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      callerId: callerId,
      receiverId: myId,
      timestamp: DateTime.now(),
      duration: Duration.zero,
      type: CallType.incoming,
      status: CallStatus.completed,
    ));
    
    // If accepting as audio-only, disable video before accepting
    if (!isVideo && callProvider.isVideoEnabled) {
      callProvider.toggleVideo();
    }
    
    await callProvider.acceptCall();
    await Future.delayed(const Duration(milliseconds: 100));
    navigator.push(
      MaterialPageRoute(
        builder: (context) => const CallScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final theme = themeService.currentTheme;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'WebRTC Call',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.contacts_rounded, color: Colors.white),
            tooltip: 'Контакты',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactsScreen(),
                ),
              );
              if (result != null && result is Map) {
                _targetUserController.text = result['id'];
                _startCall(context, isVideo: result['isVideo'] ?? true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.security_rounded, color: Colors.white),
            tooltip: 'Ключ шифрования',
            onPressed: () => _showEncryptionKeyDialog(context),
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? AnimatedBackground(
              colors: [
                theme.primaryColor,
                theme.accentColor,
              ],
              child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Connection Status Card
                Consumer<CallProvider>(
                  builder: (context, callProvider, _) {
                    final isConnected = callProvider.mySocketId != null;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2D2D2D),
                            const Color(0xFF1A1A1A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(theme.borderRadius),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isConnected ? const Color(0xFF4CAF50) : const Color(0xFF4D4D4D),
                                  shape: BoxShape.circle,
                                  boxShadow: isConnected ? [
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50).withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ] : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isConnected ? 'Подключено' : 'Подключение...',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isConnected) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${callProvider.mySocketId}',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isConnected)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 24),
                            ],
                          ),
                          if (isConnected && _myEncryptionKey.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.security_rounded,
                                    color: Color(0xFF4CAF50),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ключ шифрования',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _myEncryptionKey,
                                          style: const TextStyle(
                                            color: Color(0xFF4CAF50),
                                            fontSize: 12,
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                
                // Application Logs
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(theme.borderRadius),
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
                            'Application Logs',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.5),
                              fontFamily: 'monospace',
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_logs.length} entries',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.3),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _logs.isEmpty
                            ? Center(
                                child: Text(
                                  'Waiting for events...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.3),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _logScrollController,
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
                
                const SizedBox(height: 32),
                
                // ID Input Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2D2D2D).withOpacity(0.9),
                        const Color(0xFF1A1A1A).withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(theme.borderRadius),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'ID собеседника',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _targetUserController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Введите ID пользователя',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          prefixIcon: const Icon(Icons.badge_rounded, color: Colors.white),
                          filled: true,
                          fillColor: const Color(0xFF1A1A1A).withOpacity(0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Call Buttons with Neon Effect
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    NeonButton(
                      icon: Icons.videocam_rounded,
                      label: 'Видео',
                      colors: [const Color(0xFF4D4D4D), const Color(0xFF3D3D3D)],
                      onPressed: () => _startCall(context, isVideo: true),
                    ),
                    NeonButton(
                      icon: Icons.phone_rounded,
                      label: 'Аудио',
                      colors: [const Color(0xFF5D5D5D), const Color(0xFF4D4D4D)],
                      onPressed: () => _startCall(context, isVideo: false),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Quick Actions
                const Text(
                  'Быстрый доступ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.contacts_rounded,
                        label: 'Контакты',
                        color: const Color(0xFF3D3D3D),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ContactsScreen()),
                          );
                          if (result != null && result is Map) {
                            _targetUserController.text = result['id'];
                            _startCall(context, isVideo: result['isVideo'] ?? true);
                          }
                        },
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.history_rounded,
                        label: 'История',
                        color: const Color(0xFF4D4D4D),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CallHistoryScreen()),
                          );
                        },
                        theme: theme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      )
          : const CallHistoryScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: const Color(0xFF1A1A1A).withOpacity(0.95),
        selectedItemColor: const Color(0xFF6D6D6D),
        unselectedItemColor: Colors.white.withOpacity(0.3),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'История',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required theme,
  }) {
    return _AnimatedButton(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
          ),
          borderRadius: BorderRadius.circular(theme.borderRadius),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startCall(BuildContext context, {bool isVideo = true}) async {
    print('[HomeScreen] _startCall called with isVideo: $isVideo');
    if (_targetUserController.text.isEmpty) {
      _addLog('ERROR: Target user ID is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a target user ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final callProvider = Provider.of<CallProvider>(context, listen: false);
    
    // Update server URL if changed
    if (_serverController.text.isNotEmpty) {
      callProvider.connectToSignalingServer(_serverController.text);
    }

    final targetId = _targetUserController.text;
    _addLog('Initiating ${isVideo ? 'video' : 'audio'} call to $targetId');

    // Save outgoing call to history
    final myId = callProvider.mySocketId ?? 'Unknown';
    await _historyService.addCall(CallHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      callerId: myId,
      receiverId: _targetUserController.text,
      timestamp: DateTime.now(),
      duration: Duration.zero,
      type: CallType.outgoing,
      status: CallStatus.completed,
    ));

    // Сохраняем контакт если его нет
    if (_contactService.getContactName(targetId) == null) {
      await _contactService.addContact(targetId, 'User $targetId');
      _addLog('Contact saved: User $targetId');
    }

    // Initiate call and navigate directly to call screen
    if (!mounted) return;
    
    print('[HomeScreen] Starting call to $targetId');
    await callProvider.makeCall(targetId, isVideo: isVideo);
    
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CallScreen(),
      ),
    );
  }

  void _showEncryptionKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 8),
            Text('Ключ шифрования'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ваш публичный ключ:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _myEncryptionKey.isNotEmpty ? _myEncryptionKey : 'Загрузка...',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Этот ключ используется для шифрования ваших звонков.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _serverController.dispose();
    _targetUserController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }
}

class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
