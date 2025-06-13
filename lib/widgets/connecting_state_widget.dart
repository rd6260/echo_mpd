import 'package:flutter/material.dart';

class ConnectingStateWidget extends StatelessWidget {
  final AnimationController animation;
  final String host;
  final String port;

  const ConnectingStateWidget({
    super.key,
    required this.animation,
    required this.host,
    required this.port,
  });

  @override
  Widget build(BuildContext context) {
    final pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wifi, size: 48, color: Colors.white),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Connecting to MPD Server...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$host:$port',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
