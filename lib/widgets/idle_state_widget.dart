import 'package:echo_mpd/widgets/info_card.dart';
import 'package:flutter/material.dart';

class IdleStateWidget extends StatelessWidget {
  final VoidCallback onConfigurePressed;

  const IdleStateWidget({super.key, required this.onConfigurePressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.music_note,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Music Player Daemon',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to your MPD server to start streaming music',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: onConfigurePressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings_input_antenna),
                  SizedBox(width: 12),
                  Text(
                    'Configure Connection',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const InfoCard(),
          ],
        ),
      ),
    );
  }
}
