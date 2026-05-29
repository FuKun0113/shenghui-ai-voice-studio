import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../domain/voice.dart';
import 'app_panel.dart';

class VoiceCard extends StatelessWidget {
  const VoiceCard({
    super.key,
    required this.voice,
    required this.selected,
    required this.onUse,
    required this.onPreview,
    required this.onFavorite,
    this.isPreviewing = false,
    this.onDelete,
  });

  final Voice voice;
  final bool selected;
  final VoidCallback onUse;
  final VoidCallback onPreview;
  final VoidCallback onFavorite;
  final bool isPreviewing;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? scheme.primary.withValues(alpha: 0.42)
              : scheme.outlineVariant.withValues(alpha: 0.58),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.shadow.withValues(alpha: selected ? 0.08 : 0.04),
            blurRadius: selected ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            IconBadge(
              icon: selected
                  ? HugeIcons.strokeRoundedCheckmarkCircle02
                  : _iconForType(voice.type),
              selected: selected,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    voice.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      _TypeChip(label: _labelForType(voice.type)),
                      for (final tag in voice.tags.take(3))
                        _TypeChip(label: tag, subtle: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 2,
              children: <Widget>[
                IconButton(
                  tooltip: voice.favorite ? '取消收藏' : '收藏',
                  onPressed: onFavorite,
                  icon: AppHugeIcon(
                    voice.favorite
                        ? HugeIcons.strokeRoundedFavourite
                        : HugeIcons.strokeRoundedFavouriteCircle,
                  ),
                ),
                IconButton(
                  tooltip: isPreviewing ? '暂停' : '播放',
                  onPressed: onPreview,
                  icon: AppHugeIcon(
                    isPreviewing
                        ? HugeIcons.strokeRoundedPause
                        : HugeIcons.strokeRoundedPlay,
                  ),
                ),
                IconButton(
                  tooltip: '使用',
                  onPressed: onUse,
                  icon: const AppHugeIcon(
                    HugeIcons.strokeRoundedCheckmarkCircle02,
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    tooltip: '删除',
                    onPressed: onDelete,
                    icon: const AppHugeIcon(HugeIcons.strokeRoundedDelete01),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<List<dynamic>> _iconForType(VoiceType type) {
    return switch (type) {
      VoiceType.builtin => HugeIcons.strokeRoundedVoice,
      VoiceType.cloned => HugeIcons.strokeRoundedMic01,
      VoiceType.designed => HugeIcons.strokeRoundedMagicWand02,
    };
  }

  String _labelForType(VoiceType type) {
    return switch (type) {
      VoiceType.builtin => '默认音色',
      VoiceType.cloned => '克隆音色',
      VoiceType.designed => '设计音色',
    };
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, this.subtle = false});

  final String label;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: subtle
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.72)
            : scheme.secondaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: subtle
                ? scheme.onSurfaceVariant
                : scheme.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
