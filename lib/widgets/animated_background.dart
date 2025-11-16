import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final List<Color> colors;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.colors = const [
      Color(0xFF1A1A1A),
      Color(0xFF0D0D0D),
    ],
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.colors[0].withOpacity(0.95 + _animation.value * 0.05),
                widget.colors[1].withOpacity(0.9 + _animation.value * 0.05),
                const Color(0xFF000000).withOpacity(0.95 - _animation.value * 0.05),
              ],
              stops: [
                0.0,
                0.5 + _animation.value * 0.2,
                1.0,
              ],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
