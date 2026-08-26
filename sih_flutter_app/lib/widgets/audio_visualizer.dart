import 'package:flutter/material.dart';
import '../app/theme.dart';

class AudioVisualizerWidget extends StatefulWidget {
  final bool isRecording;
  final bool isPlaying;
  final Color activeColor;

  const AudioVisualizerWidget({
    super.key,
    this.isRecording = false,
    this.isPlaying = false,
    this.activeColor = AppColors.blue,
  });

  @override
  State<AudioVisualizerWidget> createState() => _AudioVisualizerWidgetState();
}

class _AudioVisualizerWidgetState extends State<AudioVisualizerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isRecording || widget.isPlaying;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(16, (index) {
            double height;
            if (active) {
              final val = (index % 4 + 1) * 0.2 + (_controller.value * 0.4);
              height = 12.0 + (val * 24.0);
            } else {
              height = 12.0 + (index % 3) * 6.0;
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3.5,
              height: height,
              decoration: BoxDecoration(
                color: active
                    ? widget.activeColor
                    : widget.activeColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}
