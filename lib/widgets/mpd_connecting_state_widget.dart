

import 'package:flutter/material.dart';

class MpdConnectingStateWidget extends StatefulWidget {
  const MpdConnectingStateWidget({super.key});

  @override
  State<MpdConnectingStateWidget> createState() => _MpdConnectingStateWidgetState();
}

class _MpdConnectingStateWidgetState extends State<MpdConnectingStateWidget> with TickerProviderStateMixin{
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

  }

  @override
  void dispose() {
    _pulseController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.wifi,
                            size: 48,
                            color: Colors.white,
                          ),
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
                    '${_ipController.text}:${_portController.text}',
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