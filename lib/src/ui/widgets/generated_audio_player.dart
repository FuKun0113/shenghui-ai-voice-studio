import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../domain/generated_audio.dart';
import 'mimo_tagged_text.dart';
import 'waveform_card.dart';

class GeneratedAudioCapsule extends StatelessWidget {
  const GeneratedAudioCapsule({
    super.key,
    required this.audio,
    required this.isPlaying,
    required this.playbackProgress,
    required this.onTogglePlay,
    required this.onOpen,
    required this.onDownload,
    required this.onShare,
    required this.onDelete,
    required this.onRegenerate,
    this.isRegenerating = false,
  });

  final GeneratedAudio audio;
  final bool isPlaying;
  final double playbackProgress;
  final VoidCallback onTogglePlay;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onRegenerate;
  final bool isRegenerating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showTextPreview = audio.text.trim() != audio.displayTitle.trim();
    return AnimatedScale(
      scale: isPlaying ? 1.01 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(8),
          child: WaveformCard(
            key: ValueKey<String>('generated-audio-card-${audio.id}'),
            audioPath: audio.audioPath,
            height: 108,
            highlighted: isPlaying,
            playing: isPlaying,
            progress: playbackProgress,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                _PlayToggleButton(
                  isPlaying: isPlaying,
                  onPressed: onTogglePlay,
                  size: 42,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      MimoTaggedText(
                        audio.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedVoice,
                            size: 15,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${formatGeneratedAudioTime(audio.createdAt)} · ${audio.voiceName} · ${formatAudioDuration(audio.durationMs)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (showTextPreview || isRegenerating) ...<Widget>[
                        const SizedBox(height: 8),
                        isRegenerating
                            ? const _RegeneratingIndicator(
                                key: Key('audioRegeneratingIndicator'),
                              )
                            : MimoTaggedText(
                                audio.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 168),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: _AudioActionRow(
                      actions: <_AudioCardAction>[
                        _AudioCardAction(
                          tooltip: '下载',
                          icon: HugeIcons.strokeRoundedDownload01,
                          onPressed: onDownload,
                        ),
                        _AudioCardAction(
                          tooltip: '分享',
                          icon: HugeIcons.strokeRoundedShare01,
                          onPressed: onShare,
                        ),
                        _AudioCardAction(
                          tooltip: '重生成',
                          icon: isRegenerating
                              ? HugeIcons.strokeRoundedLoading03
                              : HugeIcons.strokeRoundedRefresh,
                          spinning: isRegenerating,
                          onPressed: isRegenerating ? null : onRegenerate,
                        ),
                        _AudioCardAction(
                          tooltip: '删除',
                          icon: HugeIcons.strokeRoundedDelete01,
                          danger: true,
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LargeGeneratedAudioPlayer extends StatelessWidget {
  const LargeGeneratedAudioPlayer({
    super.key,
    required this.audio,
    required this.isPlaying,
    required this.playbackProgress,
    required this.onTogglePlay,
  });

  final GeneratedAudio audio;
  final bool isPlaying;
  final double playbackProgress;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return WaveformCard(
      key: ValueKey<String>('generated-audio-detail-player-${audio.id}'),
      audioPath: audio.audioPath,
      height: 224,
      highlighted: isPlaying,
      playing: isPlaying,
      progress: playbackProgress,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox.square(
                dimension: 42,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedAudioWave01,
                  size: 23,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MimoTaggedText(
                      audio.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${formatGeneratedAudioTime(audio.createdAt)} · ${audio.voiceName} · ${formatAudioDuration(audio.durationMs)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: _PlayToggleButton(
              isPlaying: isPlaying,
              onPressed: onTogglePlay,
              size: 66,
              iconSize: 30,
            ),
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              HugeIcon(
                icon: isPlaying
                    ? HugeIcons.strokeRoundedVolumeHigh
                    : HugeIcons.strokeRoundedMusicNote01,
                size: 18,
                color: isPlaying ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                isPlaying ? '正在播放' : '点击播放',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isPlaying ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AudioActionButton extends StatelessWidget {
  const AudioActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.danger = false,
    this.spinning = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onPressed;
  final bool danger;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? scheme.error : scheme.primary;
    final actionIcon = HugeIcon(icon: icon, size: 18, color: color);
    return Expanded(
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: spinning
            ? actionIcon
                  .animate(onPlay: (controller) => controller.repeat())
                  .rotate(duration: 900.ms, curve: Curves.linear)
            : actionIcon,
        label: FittedBox(child: Text(label)),
        style: FilledButton.styleFrom(
          foregroundColor: color,
          backgroundColor:
              (danger ? scheme.errorContainer : scheme.primaryContainer)
                  .withValues(alpha: danger ? 0.64 : 0.7),
          minimumSize: const Size.fromHeight(46),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _AudioActionRow extends StatelessWidget {
  const _AudioActionRow({required this.actions});

  final List<_AudioCardAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final entry in actions.indexed) ...<Widget>[
          if (entry.$1 != 0) const SizedBox(width: 6),
          _MiniActionButton(action: entry.$2),
        ],
      ],
    );
  }
}

class _AudioCardAction {
  const _AudioCardAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.danger = false,
    this.spinning = false,
  });

  final String tooltip;
  final List<List<dynamic>> icon;
  final VoidCallback? onPressed;
  final bool danger;
  final bool spinning;
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({required this.action});

  final _AudioCardAction action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = action.danger ? scheme.error : scheme.primary;
    final icon = HugeIcon(icon: action.icon, size: 18, color: color);
    return SizedBox.square(
      dimension: 36,
      child: IconButton(
        tooltip: action.tooltip,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          foregroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: action.onPressed,
        icon: action.spinning
            ? icon
                  .animate(onPlay: (controller) => controller.repeat())
                  .rotate(duration: 900.ms, curve: Curves.linear)
            : icon,
      ),
    );
  }
}

class _RegeneratingIndicator extends StatelessWidget {
  const _RegeneratingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              size: 15,
              color: scheme.primary,
            )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 900.ms, curve: Curves.linear),
        const SizedBox(width: 6),
        Text(
              '正在重生成',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .fade(begin: 0.55, end: 1, duration: 700.ms),
      ],
    );
  }
}

class _PlayToggleButton extends StatelessWidget {
  const _PlayToggleButton({
    required this.isPlaying,
    required this.onPressed,
    this.size = 48,
    this.iconSize = 22,
  });

  final bool isPlaying;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = isPlaying ? scheme.primary : scheme.onSurfaceVariant;
    return AnimatedScale(
      scale: isPlaying ? 1.08 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isPlaying
              ? scheme.primaryContainer.withValues(alpha: 0.88)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isPlaying
              ? <BoxShadow>[
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: IconButton(
          tooltip: isPlaying ? '暂停' : '播放',
          onPressed: onPressed,
          style: IconButton.styleFrom(
            foregroundColor: foreground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: HugeIcon(
            icon: isPlaying
                ? HugeIcons.strokeRoundedPause
                : HugeIcons.strokeRoundedPlay,
            size: iconSize,
            color: foreground,
          ),
        ),
      ),
    );
  }
}

String formatAudioDuration(int durationMs) {
  if (durationMs <= 0) return '时长待识别';
  final totalSeconds = (durationMs / 1000).round();
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  if (minutes == 0) return '$seconds 秒';
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String formatGeneratedAudioTime(DateTime createdAt, {DateTime? now}) {
  final localCreatedAt = createdAt.toLocal();
  final localNow = (now ?? DateTime.now()).toLocal();
  final createdDate = DateTime(
    localCreatedAt.year,
    localCreatedAt.month,
    localCreatedAt.day,
  );
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final time =
      '${localCreatedAt.hour.toString().padLeft(2, '0')}:${localCreatedAt.minute.toString().padLeft(2, '0')}';
  final dayDelta = today.difference(createdDate).inDays;
  if (dayDelta == 0) return '今天 $time';
  if (dayDelta == 1) return '昨天 $time';
  if (localCreatedAt.year == localNow.year) {
    return '${localCreatedAt.month}月${localCreatedAt.day}日 $time';
  }
  return '${localCreatedAt.year}年${localCreatedAt.month}月${localCreatedAt.day}日 $time';
}
