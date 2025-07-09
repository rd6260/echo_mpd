import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:echo_mpd/service/settings.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

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
    await MpdRemoteService.instance.seekToPosition(Duration(milliseconds: (value * 1000).round()));
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
        AnimatedWavySlider(
          value: widget.totalDuration > 0
              ? (sliderValue / widget.totalDuration).clamp(0.0, 1.0)
              : 0.0,
          onChanged: (normalizedValue) {
            _onSliderChanged(normalizedValue * widget.totalDuration);
          },
          onChangeStart: (normalizedValue) {
            _onSliderChangeStart(normalizedValue * widget.totalDuration);
          },
          onChangeEnd: (normalizedValue) {
            _onSliderChangeEnd(normalizedValue * widget.totalDuration);
          },
          activeColor: const Color(Settings.primaryColor),
          // inactiveColor: Colors.grey[700]!,
          inactiveColor: const Color(Settings.primaryColor),
          thumbColor: const Color(Settings.primaryColor),
          height: 40,
          width: MediaQuery.of(context).size.width - 32,
          waveFrequency:
              10.0, // Control wave period (lower = longer waves, higher = shorter waves)
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(sliderValue),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                _formatTime(widget.totalDuration),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AnimatedWavySlider extends StatefulWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final double width;
  final double height;
  final double waveFrequency; // Controls wave period

  const AnimatedWavySlider({
    super.key,
    required this.value,
    this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.activeColor = Colors.green,
    this.inactiveColor = Colors.grey,
    this.thumbColor = Colors.green,
    this.width = 250,
    this.height = 40,
    this.waveFrequency = 6.0, // Default frequency
  });

  @override
  State<AnimatedWavySlider> createState() => _AnimatedWavySliderState();
}

class _AnimatedWavySliderState extends State<AnimatedWavySlider>
    with TickerProviderStateMixin {
  bool _isDragging = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });

    // RenderBox renderBox = context.findRenderObject() as RenderBox;
    double localX = details.localPosition.dx;
    double newValue = (localX / widget.width).clamp(0.0, 1.0);

    widget.onChangeStart?.call(newValue);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // RenderBox renderBox = context.findRenderObject() as RenderBox;
    double localX = details.localPosition.dx;
    double newValue = (localX / widget.width).clamp(0.0, 1.0);

    widget.onChanged?.call(newValue);
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    widget.onChangeEnd?.call(widget.value);
  }

  void _handleTapDown(TapDownDetails details) {
    // RenderBox renderBox = context.findRenderObject() as RenderBox;
    double localX = details.localPosition.dx;
    double newValue = (localX / widget.width).clamp(0.0, 1.0);

    widget.onChangeStart?.call(newValue);
    widget.onChanged?.call(newValue);
    widget.onChangeEnd?.call(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onTapDown: _handleTapDown,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: AnimatedWavySliderPainter(
                value: widget.value,
                activeColor: widget.activeColor,
                inactiveColor: widget.inactiveColor,
                thumbColor: widget.thumbColor,
                isDragging: _isDragging,
                animationValue: _animationController.value,
                waveFrequency:
                    widget.waveFrequency, // Pass frequency to painter
              ),
            );
          },
        ),
      ),
    );
  }
}

class AnimatedWavySliderPainter extends CustomPainter {
  final double value;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final bool isDragging;
  final double animationValue;
  final double waveFrequency; // Wave frequency parameter

  AnimatedWavySliderPainter({
    required this.value,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    this.isDragging = false,
    required this.animationValue,
    required this.waveFrequency, // Required parameter
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final activeWidth = size.width * value;

    // Parameters for the wave
    final waveAmplitude = 4.0;
    final animationOffset = animationValue * 2 * math.pi;

    // Draw active wavy section (left of the thumb)
    if (activeWidth > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      Path wavePath = Path();
      bool hasStarted = false;

      // Create animated wave path only for the active section
      for (double x = 0; x <= activeWidth; x += 1) {
        double progress = x / size.width;
        double y =
            centerY +
            waveAmplitude *
                math.sin(
                  progress * waveFrequency * 2 * math.pi + animationOffset,
                );

        if (!hasStarted) {
          wavePath.moveTo(x, y);
          hasStarted = true;
        } else {
          wavePath.lineTo(x, y);
        }
      }

      canvas.drawPath(wavePath, activePaint);
    }

    // Draw inactive (background) track - straight line ONLY for the right side (after the thumb)
    if (activeWidth < size.width) {
      final inactivePaint = Paint()
        ..color = inactiveColor
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(activeWidth, centerY),
        Offset(size.width, centerY),
        inactivePaint,
      );
    }

    // Draw thumb at a fixed position on the centerY (no wobbling)
    if (activeWidth > 0) {
      double thumbX = activeWidth;
      double thumbY = centerY; // Fixed Y position - no wobbling

      // Thumb size changes when dragging
      double thumbRadius = isDragging ? 12.0 : 10.0;

      // Draw thumb glow when dragging
      if (isDragging) {
        final glowPaint = Paint()
          ..color = activeColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(thumbX, thumbY), thumbRadius + 6, glowPaint);
      }

      // Draw thumb
      final thumbPaint = Paint()
        ..color = thumbColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(thumbX, thumbY), thumbRadius, thumbPaint);

      // Draw thumb border
      final thumbBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(Offset(thumbX, thumbY), thumbRadius, thumbBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
