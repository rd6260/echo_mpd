import 'package:flutter/material.dart';


/// initial Loading widget
class AnimatedConnectingMpdWidget extends StatefulWidget {
  const AnimatedConnectingMpdWidget({super.key,});

  @override
  State<AnimatedConnectingMpdWidget> createState() =>
      _AnimatedConnectingMpdWidgetState();
}

class _AnimatedConnectingMpdWidgetState
    extends State<AnimatedConnectingMpdWidget> with TickerProviderStateMixin {
  late Animation<double> _loadingAnimation;
  late AnimationController _loadingController;

  @override
  void initState() {

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
    super.initState();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingAnimation.value * 2 * 3.14159,
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
