import 'package:flutter/material.dart';

class LoadingStateWidget extends StatelessWidget {
  final AnimationController animation;

  const LoadingStateWidget({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: animation.value * 2 * 3.14159,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Initializing...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
