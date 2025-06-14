import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:flutter/material.dart';

class ProgressSliderWidget extends StatefulWidget {
  final double totalDuration;
  final double currentElapsed;

  const ProgressSliderWidget({
    super.key,
    required this.totalDuration,
    required this.currentElapsed,
  });

  @override
  State<ProgressSliderWidget> createState() => _ProgressSliderWidgetState();
}

class _ProgressSliderWidgetState extends State<ProgressSliderWidget> {
  bool isUserDragging = false;
  double dragValue = 0.0;

  void _onSliderChanged(double value) {
    setState(() {
      dragValue = value;
    });
  }

  void _onSliderChangeStart(double value) {
    setState(() {
      isUserDragging = true;
      dragValue = value;
    });
  }

  void _onSliderChangeEnd(double value) async {
    setState(() {
      isUserDragging = false;
    });
    await MpdRemoteService.instance.seekToPosition(value);
  }

  String _formatTime(double seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sliderValue = isUserDragging ? dragValue : widget.currentElapsed;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFFE91E63),
            inactiveTrackColor: Colors.grey[800],
            thumbColor: const Color(0xFFE91E63),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 16,
            ),
            trackHeight: 4,
          ),
          child: Slider(
            value: sliderValue.clamp(0.0, widget.totalDuration),
            min: 0,
            max: widget.totalDuration,
            onChanged: _onSliderChanged,
            onChangeStart: _onSliderChangeStart,
            onChangeEnd: _onSliderChangeEnd,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(sliderValue),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              Text(
                _formatTime(widget.totalDuration),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}