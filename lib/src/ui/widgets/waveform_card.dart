import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';

import '../../services/waveform_cache_store.dart';

class WaveformCard extends StatefulWidget {
  const WaveformCard({
    super.key,
    required this.audioPath,
    required this.child,
    this.height = 112,
    this.highlighted = false,
    this.playing = false,
    this.progress = 0,
    this.padding = const EdgeInsets.all(14),
  });

  final String audioPath;
  final Widget child;
  final double height;
  final bool highlighted;
  final bool playing;
  final double progress;
  final EdgeInsetsGeometry padding;

  @override
  State<WaveformCard> createState() => _WaveformCardState();
}

class _WaveformCardState extends State<WaveformCard> {
  final WaveformCacheStore _cacheStore = WaveformCacheStore();
  Waveform? _waveform;
  StreamSubscription<WaveformProgress>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadWaveform();
  }

  @override
  void didUpdateWidget(covariant WaveformCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioPath != widget.audioPath) {
      _subscription?.cancel();
      _waveform = null;
      _loadWaveform();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadWaveform() async {
    try {
      final audioFile = File(widget.audioPath);
      if (!await audioFile.exists()) return;
      final waveformFile = await _cacheStore.cacheFileForAudio(
        widget.audioPath,
      );
      if (await waveformFile.exists()) {
        final waveform = await JustWaveform.parse(waveformFile);
        if (!mounted || widget.audioPath != audioFile.path) return;
        setState(() => _waveform = waveform);
        return;
      }
      _subscription =
          JustWaveform.extract(
            audioInFile: audioFile,
            waveOutFile: waveformFile,
          ).listen(
            (progress) {
              if (!mounted) return;
              if (progress.waveform != null) {
                setState(() => _waveform = progress.waveform);
              }
            },
            onError: (_) {
              // Keep the fallback waveform when the platform extractor is absent.
            },
          );
    } on Object {
      // Fallback to decorative bars.
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(8);
    final progress = widget.progress.clamp(0, 1).toDouble();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: radius,
        border: Border.all(
          color: widget.highlighted
              ? scheme.primary.withValues(alpha: 0.32)
              : scheme.outlineVariant.withValues(alpha: 0.58),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (widget.highlighted ? scheme.primary : scheme.shadow)
                .withValues(alpha: widget.highlighted ? 0.18 : 0.085),
            blurRadius: widget.highlighted ? 30 : 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      scheme.surface,
                      scheme.primaryContainer.withValues(alpha: 0.42),
                      scheme.tertiaryContainer.withValues(alpha: 0.24),
                    ],
                    stops: const <double>[0, 0.62, 1],
                  ),
                ),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: widget.highlighted ? 0.68 : 0.48,
                  child: _waveform == null || _waveform!.length <= 0
                      ? _FallbackWaveLines(
                          color: scheme.primary,
                          accentColor: scheme.tertiary,
                          progress: progress,
                          playing: widget.playing,
                        )
                      : CustomPaint(
                          painter: _WaveformPainter(
                            waveform: _waveform!,
                            color: scheme.primary,
                            accentColor: scheme.tertiary,
                            inactiveColor: scheme.onSurfaceVariant,
                            progress: progress,
                            playing: widget.playing,
                          ),
                        ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: <Color>[
                        scheme.surface.withValues(alpha: 0.86),
                        scheme.surface.withValues(alpha: 0.55),
                        scheme.surface.withValues(alpha: 0.34),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(padding: widget.padding, child: widget.child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FallbackWaveLines extends StatelessWidget {
  const _FallbackWaveLines({
    required this.color,
    required this.accentColor,
    required this.progress,
    required this.playing,
  });

  final Color color;
  final Color accentColor;
  final double progress;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final heights = <double>[18, 36, 24, 48, 30, 54, 20, 42, 28, 50, 34];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (final entry in heights.indexed)
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: entry.$2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: entry.$1 / heights.length <= progress
                      ? (entry.$1.isEven ? color : accentColor)
                      : color.withValues(alpha: playing ? 0.34 : 0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.waveform,
    required this.color,
    required this.accentColor,
    required this.inactiveColor,
    required this.progress,
    required this.playing,
  });

  final Waveform waveform;
  final Color color;
  final Color accentColor;
  final Color inactiveColor;
  final double progress;
  final bool playing;

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = waveform.length;
    if (barCount <= 0) return;
    final step = size.width / barCount;
    final paint = Paint()..style = PaintingStyle.fill;
    final activeWidth = size.width * progress.clamp(0, 1);
    for (var i = 0; i < barCount; i++) {
      final min = waveform.getPixelMin(i).abs();
      final max = waveform.getPixelMax(i).abs();
      final amplitude = ((min + max) / 2).clamp(0, 32767) / 32767;
      final barHeight = amplitude * size.height;
      final x = i * step;
      final y = size.height - barHeight;
      final active = x <= activeWidth;
      paint.color = active
          ? (i.isEven ? color : accentColor)
          : inactiveColor.withValues(alpha: playing ? 0.34 : 0.26);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x + step * 0.18, y, step * 0.64, barHeight),
        const Radius.circular(999),
      );
      canvas.drawRRect(rrect, paint);
    }
    if (playing) {
      final playheadX = activeWidth.clamp(0, size.width).toDouble();
      paint.color = accentColor.withValues(alpha: 0.92);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(playheadX, 0, 2.5, size.height),
          const Radius.circular(999),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.waveform != waveform ||
        oldDelegate.color != color ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.progress != progress ||
        oldDelegate.playing != playing;
  }
}
