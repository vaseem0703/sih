import 'package:flutter/material.dart';
import '../app/theme.dart';

class AudioButton extends StatefulWidget {
  final String? audioAsset;
  final String? audioPath;
  final String label;
  final Color color;

  const AudioButton({
    super.key,
    this.audioAsset,
    this.audioPath,
    this.label = 'Play Audio',
    this.color = AppColors.purple,
  });

  @override
  State<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton> {
  bool _isPlaying = false;
  bool _isLoading = false;

  void _handlePlay() async {
    final hasAudio =
        (widget.audioAsset != null && widget.audioAsset!.isNotEmpty) ||
        (widget.audioPath != null && widget.audioPath!.isNotEmpty);

    if (!hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio not available for this item (Offline Demo)'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isPlaying = true;
    });

    // Simulate audio playing duration safely
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isPlaying || _isLoading ? null : _handlePlay,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                  ),
                )
              else
                Icon(
                  _isPlaying
                      ? Icons.volume_up_rounded
                      : Icons.play_arrow_rounded,
                  color: widget.color,
                  size: 24,
                ),
              const SizedBox(width: 8),
              Text(
                _isLoading
                    ? 'Loading...'
                    : _isPlaying
                    ? 'Playing Audio'
                    : widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
