import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../domain/generated_audio.dart';
import '../../domain/voice.dart';
import '../../services/document_text_extractor.dart';
import '../../services/audio_export_service.dart';
import '../../services/audio_playback_service.dart';
import '../../services/text_segmenter.dart';
import '../../state/app_state.dart';
import '../history/generated_audio_detail_screen.dart';
import '../widgets/app_panel.dart';
import '../widgets/generated_audio_player.dart';

class GenerateScreen extends StatefulWidget {
  GenerateScreen({
    super.key,
    required this.appState,
    this.onOpenSettings,
    AudioPlaybackController? playbackService,
    AudioExportController? exportService,
  }) : playbackService = playbackService ?? AudioPlaybackService.instance,
       exportService = exportService ?? AudioExportService.instance;

  final AppState appState;
  final VoidCallback? onOpenSettings;
  final AudioPlaybackController playbackService;
  final AudioExportController exportService;

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  static const List<String> _styleTags = <String>[
    '温柔',
    '开心',
    '高冷',
    '慵懒',
    '磁性',
    '清亮',
    '粤语',
    '四川话',
    '轻笑',
    '叹气',
  ];

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _styleController = TextEditingController();
  final DocumentTextExtractor _documentTextExtractor = DocumentTextExtractor();
  GeneratedAudio? _lastAudio;
  String? _error;
  String? _importedFileName;
  bool _needsSettings = false;

  @override
  void initState() {
    super.initState();
    _textController.text = widget.appState.draftText;
    _styleController.text = widget.appState.stylePrompt;
    widget.appState.addListener(_sync);
    widget.playbackService.playbackState.addListener(_syncPlayback);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_sync);
    widget.playbackService.playbackState.removeListener(_syncPlayback);
    _textController.dispose();
    _styleController.dispose();
    super.dispose();
  }

  void _sync() => setState(() {});

  void _syncPlayback() {
    if (mounted) setState(() {});
  }

  Future<void> _importDocument() async {
    setState(() => _error = null);
    try {
      final imported = await _documentTextExtractor.pickAndExtract();
      if (imported == null) return;
      _textController.text = imported.text;
      widget.appState.updateDraftText(imported.text);
      setState(() => _importedFileName = imported.name);
    } on Object catch (error) {
      setState(() => _error = '文档读取失败：$error');
    }
  }

  void _toggleStyleTag(String tag) {
    final tags = _styleController.text
        .split(RegExp(r'[，,\s]+'))
        .where((item) => item.trim().isNotEmpty)
        .toList();
    if (tags.contains(tag)) {
      tags.remove(tag);
    } else {
      tags.add(tag);
    }
    final value = tags.join('，');
    _styleController.text = value;
    widget.appState.updateStylePrompt(value);
    setState(() {});
  }

  Future<void> _generate() async {
    if (!widget.appState.serviceConfig.hasApiKey) {
      setState(() {
        _error = null;
        _needsSettings = false;
      });
      _showSettingsGuidance();
      return;
    }
    setState(() {
      _error = null;
      _needsSettings = false;
    });
    try {
      final audio = await widget.appState.generateCurrentVoice();
      setState(() => _lastAudio = audio);
      await widget.playbackService.playFile(audio.audioPath);
    } on StateError catch (error) {
      setState(() => _error = error.message);
    } on Object catch (error) {
      if (_lastAudio == null) {
        setState(() => _error = error.toString());
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已生成，但自动播放失败：$error')));
      }
    }
  }

  Future<void> _generateAllSegments(List<String> segments) async {
    if (!widget.appState.serviceConfig.hasApiKey) {
      setState(() {
        _error = null;
        _needsSettings = false;
      });
      _showSettingsGuidance();
      return;
    }
    setState(() {
      _error = null;
      _needsSettings = false;
    });
    try {
      GeneratedAudio? last;
      for (final segment in segments) {
        last = await widget.appState.generateText(segment);
      }
      final generated = last;
      if (generated != null) {
        setState(() {
          _lastAudio = generated;
        });
        await widget.playbackService.playFile(generated.audioPath);
      }
    } on StateError catch (error) {
      setState(() => _error = error.message);
    } on Object catch (error) {
      setState(() => _error = error.toString());
    }
  }

  void _showSettingsGuidance() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('请先填写 MiMo API Key'),
        action: SnackBarAction(
          label: '去设置',
          onPressed: () => widget.onOpenSettings?.call(),
        ),
      ),
    );
  }

  Future<void> _toggleGeneratedPlayback(GeneratedAudio audio) async {
    if (_isAudioPlaying(audio)) {
      await widget.playbackService.pause();
      return;
    }
    try {
      await widget.playbackService.playFile(audio.audioPath);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('播放失败：$error')));
    }
  }

  Future<void> _downloadAudio(GeneratedAudio audio) async {
    try {
      final path = await widget.exportService.exportAudio(audio);
      if (path == null || !mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('语音已保存')));
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }

  Future<void> _shareAudio(GeneratedAudio audio) async {
    try {
      await widget.exportService.shareAudio(audio);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('分享失败：$error')));
    }
  }

  void _deleteAudio(GeneratedAudio audio) {
    if (widget.playbackService.playbackState.value.path == audio.audioPath) {
      unawaited(widget.playbackService.stop());
    }
    widget.appState.deleteHistoryItem(audio.id);
    setState(() {
      if (_lastAudio?.id == audio.id) _lastAudio = null;
    });
  }

  Future<void> _regenerateAudio(GeneratedAudio audio) async {
    setState(() {
      _error = null;
      _needsSettings = false;
    });
    try {
      final regenerated = await widget.appState.regenerateAudio(audio);
      setState(() => _lastAudio = regenerated);
      await widget.playbackService.playFile(regenerated.audioPath);
    } on StateError catch (error) {
      setState(() => _error = error.message);
    } on Object catch (error) {
      setState(() => _error = error.toString());
    }
  }

  void _openAudioDetail(GeneratedAudio audio) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GeneratedAudioDetailScreen(
          audio: audio,
          appState: widget.appState,
          playbackService: widget.playbackService,
          exportService: widget.exportService,
          onAudioChanged: (newAudio) => setState(() {
            _lastAudio = newAudio;
          }),
        ),
      ),
    );
  }

  bool _isAudioPlaying(GeneratedAudio audio) {
    return widget.playbackService.playbackState.value.isPlayingPath(
      audio.audioPath,
    );
  }

  double _playbackProgressFor(GeneratedAudio audio) {
    final state = widget.playbackService.playbackState.value;
    if (state.path != audio.audioPath) return 0;
    final totalMs = state.duration?.inMilliseconds ?? audio.durationMs;
    if (totalMs <= 0) return state.progress;
    return (state.position.inMilliseconds / totalMs).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final selectedVoice = widget.appState.selectedVoice;
    final selectedTags = _styleController.text
        .split(RegExp(r'[，,\s]+'))
        .where((item) => item.trim().isNotEmpty)
        .toSet();
    final segments = const TextSegmenter().segment(_textController.text);
    final charCount = _textController.text.trim().length;
    final estimatedSeconds = (charCount / 4).ceil();

    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:
                  <Widget>[
                        AppPanel(
                          emphasized: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const IconBadge(
                                    icon: HugeIcons.strokeRoundedVoice,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SectionHeader(
                                      title: '选择音色',
                                      subtitle:
                                          selectedVoice?.tags
                                              .take(3)
                                              .join(' · ') ??
                                          '请选择一个用于生成的音色',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _VoiceSelectorField(
                                voices: widget.appState.voices,
                                selectedVoiceId: selectedVoice?.id,
                                onSelected: widget.appState.selectVoice,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        AppPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              SectionHeader(
                                title: '文本生成',
                                subtitle: _importedFileName == null
                                    ? '输入文本，或上传 Word/PDF/TXT 自动读取正文。'
                                    : '已导入 $_importedFileName',
                                trailing: IconButton(
                                  tooltip: '上传文档',
                                  onPressed: _importDocument,
                                  icon: const AppHugeIcon(
                                    HugeIcons.strokeRoundedFileUpload,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AppFlatActionButton(
                                  prominent: true,
                                  onPressed: _importDocument,
                                  icon: HugeIcons.strokeRoundedFileUpload,
                                  label: '上传文档',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _textController,
                                minLines: 6,
                                maxLines: 10,
                                decoration: const InputDecoration(
                                  labelText: '输入文本',
                                  hintText: '例如：欢迎使用 AI 语音工作台。',
                                  prefixIcon: AppPrefixIcon(
                                    HugeIcons.strokeRoundedEdit02,
                                  ),
                                ),
                                onChanged: widget.appState.updateDraftText,
                              ),
                              const SizedBox(height: 12),
                              AppPanel(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: <Widget>[
                                    AppHugeIcon(
                                      HugeIcons.strokeRoundedInformationCircle,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        segments.length > 1
                                            ? '已分为 ${segments.length} 段 · $charCount 字 · 约 $estimatedSeconds 秒'
                                            : '$charCount 字 · 约 $estimatedSeconds 秒',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                    if (segments.length > 1)
                                      OutlinedButton(
                                        onPressed: widget.appState.isGenerating
                                            ? null
                                            : () => _generateAllSegments(
                                                segments,
                                              ),
                                        child: const Text('生成全部'),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _styleController,
                                decoration: const InputDecoration(
                                  labelText: '风格提示',
                                  hintText: '自然、亲切、新闻播报、情绪更强...',
                                  prefixIcon: AppPrefixIcon(
                                    HugeIcons.strokeRoundedMagicWand02,
                                  ),
                                ),
                                onChanged: widget.appState.updateStylePrompt,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  for (final tag in _styleTags)
                                    FilterChip(
                                      label: Text(tag),
                                      selected: selectedTags.contains(tag),
                                      onSelected: (_) => _toggleStyleTag(tag),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 12),
                          AppPanel(
                            child: Row(
                              children: <Widget>[
                                AppHugeIcon(
                                  HugeIcons.strokeRoundedAlertCircle,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                ),
                                if (_needsSettings)
                                  TextButton(
                                    onPressed: widget.onOpenSettings,
                                    child: const Text('去设置'),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        if (_lastAudio != null) ...<Widget>[
                          const SizedBox(height: 16),
                          GeneratedAudioCapsule(
                                audio: _lastAudio!,
                                isPlaying: _isAudioPlaying(_lastAudio!),
                                playbackProgress: _playbackProgressFor(
                                  _lastAudio!,
                                ),
                                onTogglePlay: () =>
                                    _toggleGeneratedPlayback(_lastAudio!),
                                onOpen: () => _openAudioDetail(_lastAudio!),
                                onDownload: () => _downloadAudio(_lastAudio!),
                                onShare: () => _shareAudio(_lastAudio!),
                                onDelete: () => _deleteAudio(_lastAudio!),
                                onRegenerate: () =>
                                    _regenerateAudio(_lastAudio!),
                              )
                              .animate()
                              .fadeIn(duration: 260.ms)
                              .slideY(
                                begin: 0.08,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),
                        ],
                      ]
                      .animate(interval: 55.ms)
                      .fadeIn(duration: 260.ms)
                      .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: AnimatedScale(
            scale: widget.appState.isGenerating ? 0.98 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: FilledButton.icon(
              onPressed: widget.appState.isGenerating ? null : _generate,
              icon: AppHugeIcon(
                widget.appState.isGenerating
                    ? HugeIcons.strokeRoundedAudioWave01
                    : HugeIcons.strokeRoundedMagicWand02,
              ),
              label: Text(widget.appState.isGenerating ? '生成中...' : '生成语音'),
            ),
          ),
        ),
      ],
    );
  }
}

class _VoiceSelectorField extends StatelessWidget {
  const _VoiceSelectorField({
    required this.voices,
    required this.selectedVoiceId,
    required this.onSelected,
  });

  final List<Voice> voices;
  final String? selectedVoiceId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selectedVoice = voices.where((voice) {
      return voice.id == selectedVoiceId;
    }).firstOrNull;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const Key('voiceSelectorField'),
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openVoiceSheet(context),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                const AppHugeIcon(HugeIcons.strokeRoundedVoiceId),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '当前音色',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedVoice?.name ?? '选择音色',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppHugeIcon(
                  HugeIcons.strokeRoundedArrowDown01,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openVoiceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.68,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Row(
                      children: <Widget>[
                        const AppHugeIcon(HugeIcons.strokeRoundedVoiceId),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '选择音色',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                      itemCount: voices.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: scheme.outlineVariant.withValues(alpha: 0.46),
                      ),
                      itemBuilder: (context, index) {
                        final voice = voices[index];
                        final selected = voice.id == selectedVoiceId;
                        return ListTile(
                          title: Text(
                            voice.name,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(voice.tags.take(3).join(' · ')),
                          leading: IconBadge(
                            icon: selected
                                ? HugeIcons.strokeRoundedCheckmarkCircle02
                                : HugeIcons.strokeRoundedVoice,
                            selected: selected,
                          ),
                          trailing: selected
                              ? AppHugeIcon(
                                  HugeIcons.strokeRoundedCheckmarkCircle02,
                                  color: scheme.primary,
                                )
                              : null,
                          onTap: () {
                            onSelected(voice.id);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
