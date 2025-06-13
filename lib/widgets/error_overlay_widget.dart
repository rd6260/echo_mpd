import 'package:echo_mpd/widgets/dialog_buttons.dart';
import 'package:flutter/material.dart';

class ErrorOverlayWidget extends StatelessWidget {
  final AnimationController animation;
  final String errorMessage;
  final VoidCallback onTryAgain;
  final VoidCallback onCancel;

  const ErrorOverlayWidget({
    super.key,
    required this.animation,
    required this.errorMessage,
    required this.onTryAgain,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final errorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.elasticOut));

    return AnimatedBuilder(
      animation: errorAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: errorAnimation.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.9),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF333333), width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF333333)),
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Connection Failed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage.isNotEmpty
                          ? errorMessage
                          : 'Could not connect to MPD server.\nPlease check your settings and try again.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    DialogButtons(
                      isConnecting: false,
                      onConnect: onTryAgain,
                      onCancel: onCancel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
