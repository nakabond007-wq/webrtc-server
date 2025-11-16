import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/call_provider.dart';
import 'call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callerId;
  
  const IncomingCallScreen({super.key, required this.callerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 80),
            // Caller Info
            Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2D2D2D),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Входящий звонок',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  callerId.length > 20 
                      ? '${callerId.substring(0, 20)}...'
                      : callerId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Answer/Decline Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline Button
                  _AnimatedCallButton(
                    onTap: () async {
                      final callProvider = Provider.of<CallProvider>(
                        context,
                        listen: false,
                      );
                      await callProvider.rejectCall();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    color: const Color(0xFF2D2D2D),
                    icon: Icons.call_end,
                    label: 'Отклонить',
                  ),
                  
                  // Accept Button
                  _AnimatedCallButton(
                    onTap: () async {
                      final callProvider = Provider.of<CallProvider>(
                        context,
                        listen: false,
                      );
                      await callProvider.acceptCall();
                      if (context.mounted) {
                        // Navigate to call screen
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const CallScreen(),
                          ),
                        );
                      }
                    },
                    color: const Color(0xFF5D5D5D),
                    icon: Icons.call,
                    label: 'Принять',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCallButton extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;
  final IconData icon;
  final String label;

  const _AnimatedCallButton({
    required this.onTap,
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  State<_AnimatedCallButton> createState() => _AnimatedCallButtonState();
}

class _AnimatedCallButtonState extends State<_AnimatedCallButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.90 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
              child: Icon(
                widget.icon,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
