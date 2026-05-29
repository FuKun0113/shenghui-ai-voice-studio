import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../domain/generated_audio.dart';
import '../../domain/mimo_tag_catalog.dart';
import '../../services/audio_playback_service.dart';
import '../widgets/app_panel.dart';
import '../widgets/generated_audio_player.dart';
import '../widgets/mimo_tagged_text.dart';

class MimoTagGuideScreen extends StatelessWidget {
  const MimoTagGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      AppPanel(
        emphasized: true,
        child: Row(
          children: <Widget>[
            const IconBadge(icon: HugeIcons.strokeRoundedAiAudio),
            const SizedBox(width: 12),
            Expanded(
              child: SectionHeader(
                title: '标签与高级案例',
                subtitle: '风格标签写在文本开头，音频标签插入到具体句子位置。',
              ),
            ),
          ],
        ),
      ),
      const _TagLegendPanel(),
      const _AdvancedExamplesPanel(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('标签与高级案例')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final entry in sections.indexed) ...<Widget>[
                if (entry.$1 != 0) const SizedBox(height: 12),
                entry.$2
                    .animate()
                    .fadeIn(duration: 220.ms, delay: (entry.$1 * 35).ms)
                    .slideY(begin: 0.03, end: 0, curve: Curves.easeOutCubic),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TagLegendPanel extends StatelessWidget {
  const _TagLegendPanel();

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const <Widget>[
          SectionHeader(
            title: '标签规则',
            subtitle: '这些标签会进入待合成文本，因此会随文本一起发给语音服务。',
          ),
          SizedBox(height: 12),
          _LegendRow(
            title: '风格标签',
            sample: '(粤语 温柔)',
            description: '用于整段风格，建议放在文本最开头。',
            isAudioTag: false,
          ),
          SizedBox(height: 8),
          _LegendRow(
            title: '音频标签',
            sample: '[轻笑]',
            description: '用于局部表达，可以插在任意句子前后。',
            isAudioTag: true,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.title,
    required this.sample,
    required this.description,
    required this.isAudioTag,
  });

  final String title;
  final String sample;
  final String description;
  final bool isAudioTag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isAudioTag ? scheme.tertiary : scheme.primary;
    final background = isAudioTag
        ? scheme.tertiaryContainer.withValues(alpha: 0.62)
        : scheme.primaryContainer.withValues(alpha: 0.72);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Text(
              sample,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdvancedExamplesPanel extends StatelessWidget {
  const _AdvancedExamplesPanel();

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SectionHeader(
            title: '高级使用案例',
            subtitle: '点击案例查看表演指令、生成文本和内置试听，再套用到生成页改写。',
          ),
          const SizedBox(height: 12),
          for (final entry in mimoAdvancedExamples.indexed) ...<Widget>[
            _ExampleCard(index: entry.$1, example: entry.$2),
            if (entry.$1 != mimoAdvancedExamples.length - 1)
              const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.index, required this.example});

  final int index;
  final MimoAdvancedExample example;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final selected = await Navigator.of(context)
              .push<MimoAdvancedExample>(
                MaterialPageRoute<MimoAdvancedExample>(
                  builder: (context) =>
                      MimoExampleDetailScreen(index: index, example: example),
                ),
              );
          if (selected != null && context.mounted) {
            Navigator.of(context).pop(selected);
          }
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                const AppHugeIcon(HugeIcons.strokeRoundedAiAudio),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        example.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        example.scenario,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppHugeIcon(
                  HugeIcons.strokeRoundedArrowRight01,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MimoExampleDetailScreen extends StatefulWidget {
  MimoExampleDetailScreen({
    super.key,
    required this.index,
    required this.example,
    AudioPlaybackController? playbackService,
  }) : playbackService = playbackService ?? AudioPlaybackService.instance;

  final int index;
  final MimoAdvancedExample example;
  final AudioPlaybackController playbackService;

  @override
  State<MimoExampleDetailScreen> createState() =>
      _MimoExampleDetailScreenState();
}

class _MimoExampleDetailScreenState extends State<MimoExampleDetailScreen> {
  late final GeneratedAudio _audio = GeneratedAudio(
    id: 'mimo-example-${widget.index}',
    text: widget.example.text,
    voiceId: 'mimo-example',
    voiceName: widget.example.voiceName,
    audioPath: widget.example.audioPath,
    durationMs: widget.example.durationMs,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    title: widget.example.title,
    stylePrompt: widget.example.stylePrompt,
  );

  @override
  void initState() {
    super.initState();
    widget.playbackService.playbackState.addListener(_syncPlayback);
  }

  @override
  void dispose() {
    widget.playbackService.playbackState.removeListener(_syncPlayback);
    if (widget.playbackService.playbackState.value.path == _audio.audioPath) {
      unawaited(Future<void>.microtask(widget.playbackService.stop));
    }
    super.dispose();
  }

  void _syncPlayback() {
    if (mounted) setState(() {});
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await widget.playbackService.pause();
      return;
    }
    try {
      await widget.playbackService.playFile(_audio.audioPath);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('播放失败：$error')));
    }
  }

  bool get _isPlaying {
    return widget.playbackService.playbackState.value.isPlayingPath(
      _audio.audioPath,
    );
  }

  double get _playbackProgress {
    final state = widget.playbackService.playbackState.value;
    if (state.path != _audio.audioPath) return 0;
    final totalMs = state.duration?.inMilliseconds ?? _audio.durationMs;
    if (totalMs <= 0) return state.progress;
    return (state.position.inMilliseconds / totalMs).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('案例详情')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LargeGeneratedAudioPlayer(
                audio: _audio,
                isPlaying: _isPlaying,
                playbackProgress: _playbackProgress,
                onTogglePlay: _togglePlay,
                showCreatedAt: false,
              ),
              const SizedBox(height: 12),
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SectionHeader(
                      title: widget.example.title,
                      subtitle: widget.example.scenario,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.example.notes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      key: Key('useMimoExample-${widget.index}'),
                      onPressed: () =>
                          Navigator.of(context).pop(widget.example),
                      icon: const AppHugeIcon(
                        HugeIcons.strokeRoundedMagicWand02,
                      ),
                      label: const Text('套用文本'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CopyableTaggedTextBlock(
                title: '表演指令',
                text: widget.example.stylePrompt,
                maxHeight: 180,
                collapsible: true,
              ),
              const SizedBox(height: 12),
              CopyableTaggedTextBlock(
                title: '生成文本',
                text: widget.example.text,
                maxHeight: 260,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
