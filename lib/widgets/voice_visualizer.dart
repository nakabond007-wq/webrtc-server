import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class VoiceVisualizer extends StatefulWidget {
  const VoiceVisualizer({super.key});

  @override
  State<VoiceVisualizer> createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<VoiceVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _bars = List.generate(30, (_) => 0.2);
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();

    _updateTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) {
        setState(() {
          for (var i = 0; i < _bars.length; i++) {
            _bars[i] = 0.1 + Random().nextDouble() * 0.9;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(_bars.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          width: 6,
          height: _bars[index] * 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                const Color(0xFF4CAF50),
                const Color(0xFF4CAF50).withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
