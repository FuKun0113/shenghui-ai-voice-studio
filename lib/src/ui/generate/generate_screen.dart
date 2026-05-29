import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../domain/generated_audio.dart';
import '../../domain/mimo_tag_catalog.dart';
import '../../domain/voice.dart';
import '../../services/document_text_extractor.dart';
import '../../services/audio_export_service.dart';
import '../../services/audio_playback_service.dart';
import '../../services/text_segmenter.dart';
import '../../state/app_state.dart';
import '../history/generated_audio_detail_screen.dart';
import 'mimo_tag_guide_screen.dart';
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
  static final List<String> _audioTags = flattenMimoTags(mimoAudioTagGroups);

  final _MimoTaggedTextEditingController _textController =
      _MimoTaggedTextEditingController();
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

  void _updateDraftText(String value, {int? selectionOffset}) {
    final offset = (selectionOffset ?? value.length)
        .clamp(0, value.length)
        .toInt();
    _textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: offset),
    );
    widget.appState.updateDraftText(value);
    setState(() {});
  }

  void _insertStyleTag(String tag) {
    final text = _textController.text;
    final selection = _textController.selection;
    final originalOffset = selection.isValid
        ? selection.baseOffset.clamp(0, text.length).toInt()
        : text.length;
    final leadingStyle = RegExp(r'^\s*[\(（]([^\)）]*)[\)）]').firstMatch(text);
    if (leadingStyle != null) {
      final tags = leadingStyle
          .group(1)!
          .split(RegExp(r'[，,\s|｜]+'))
          .where((item) => item.trim().isNotEmpty)
          .toList();
      tags.add(tag);
      final token = '(${tags.join(' ')})';
      final delta = token.length - (leadingStyle.end - leadingStyle.start);
      final nextOffset = originalOffset >= leadingStyle.end
          ? originalOffset + delta
          : token.length;
      _updateDraftText(
        text.replaceRange(leadingStyle.start, leadingStyle.end, token),
        selectionOffset: nextOffset,
      );
      return;
    }
    final token = '($tag)';
    _updateDraftText(
      '$token$text',
      selectionOffset: originalOffset + token.length,
    );
  }

  void _insertAudioTag(String tag) {
    final token = '[$tag]';
    final text = _textController.text;
    final selection = _textController.selection;
    final start = selection.isValid
        ? selection.start.clamp(0, text.length).toInt()
        : text.length;
    final end = selection.isValid
        ? selection.end.clamp(0, text.length).toInt()
        : start;
    final nextText = text.replaceRange(start, end, token);
    _updateDraftText(nextText, selectionOffset: start + token.length);
  }

  Set<String> _selectedStyleTags(String text) {
    final leadingStyle = RegExp(r'^\s*[\(（]([^\)）]*)[\)）]').firstMatch(text);
    if (leadingStyle == null) return const <String>{};
    return leadingStyle
        .group(1)!
        .split(RegExp(r'[，,\s|｜]+'))
        .where((item) => item.trim().isNotEmpty)
        .toSet();
  }

  Set<String> _selectedAudioTags(String text) {
    return _audioTags
        .where((tag) => text.contains('[$tag]') || text.contains('【$tag】'))
        .toSet();
  }

  Future<void> _openTagInsertSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MimoTagInsertSheet(
        styleGroups: mimoStyleTagGroups,
        audioGroups: mimoAudioTagGroups,
        selectedStyleTags: _selectedStyleTags(_textController.text),
        selectedAudioTags: _selectedAudioTags(_textController.text),
        onStyleTagSelected: _insertStyleTag,
        onAudioTagSelected: _insertAudioTag,
      ),
    );
  }

  Future<void> _openDraftFullscreenEditor() async {
    final value = await _openFullscreenTextEditor(
      context,
      title: '全屏编辑输入文本',
      initialText: _textController.text,
      hintText: '输入要生成语音的文本，长文也可以在这里集中编辑。',
    );
    if (value == null || !mounted) return;
    _updateDraftText(value);
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

  Future<void> _openTagGuide() async {
    final example = await Navigator.of(context).push<MimoAdvancedExample>(
      MaterialPageRoute<MimoAdvancedExample>(
        builder: (context) => const MimoTagGuideScreen(),
      ),
    );
    if (example == null) return;
    _styleController.text = example.stylePrompt;
    widget.appState.updateStylePrompt(example.stylePrompt);
    _updateDraftText(example.text);
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
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    TextButton.icon(
                                      key: const Key('tagGuideButton'),
                                      onPressed: _openTagGuide,
                                      icon: const AppHugeIcon(
                                        HugeIcons.strokeRoundedBookOpen01,
                                      ),
                                      label: const Text('高级案例'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _InstructField(
                                controller: _styleController,
                                onChanged: widget.appState.updateStylePrompt,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: AppFlatActionButton(
                                      prominent: true,
                                      onPressed: _importDocument,
                                      icon: HugeIcons.strokeRoundedFileUpload,
                                      label: '上传文档',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: AppFlatActionButton(
                                      onPressed: _openTagInsertSheet,
                                      icon: HugeIcons.strokeRoundedTags,
                                      label: '插入标签',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Stack(
                                children: <Widget>[
                                  TextField(
                                    key: const Key('draftTextField'),
                                    controller: _textController,
                                    minLines: 6,
                                    maxLines: 10,
                                    decoration: const InputDecoration(
                                      labelText: '输入文本',
                                      hintText: '例如：欢迎使用 AI 语音工作台。',
                                      contentPadding: EdgeInsets.fromLTRB(
                                        16,
                                        18,
                                        56,
                                        58,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      widget.appState.updateDraftText(value);
                                      setState(() {});
                                    },
                                    contextMenuBuilder: (context, editableTextState) {
                                      final items = <ContextMenuButtonItem>[
                                        ContextMenuButtonItem(
                                          label: '插入标签',
                                          onPressed: () {
                                            ContextMenuController.removeAny();
                                            unawaited(_openTagInsertSheet());
                                          },
                                        ),
                                        ...editableTextState
                                            .contextMenuButtonItems,
                                      ];
                                      return AdaptiveTextSelectionToolbar.buttonItems(
                                        anchors: editableTextState
                                            .contextMenuAnchors,
                                        buttonItems: items,
                                      );
                                    },
                                  ),
                                  Positioned(
                                    right: 8,
                                    bottom: 8,
                                    child: _FullscreenEditButton(
                                      tooltip: '全屏编辑输入文本',
                                      onPressed: _openDraftFullscreenEditor,
                                    ),
                                  ),
                                ],
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

class _MimoTaggedTextEditingController extends TextEditingController {
  static final RegExp _tagPattern = RegExp(
    r'[\(（][^\n\)）]{1,48}[\)）]|\[[^\n\]]{1,48}\]|【[^\n】]{1,48}】',
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in _tagPattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final token = match.group(0)!;
      final isAudioTag = token.startsWith('[') || token.startsWith('【');
      final color = isAudioTag ? scheme.tertiary : scheme.primary;
      final background = isAudioTag
          ? scheme.tertiaryContainer.withValues(alpha: 0.62)
          : scheme.primaryContainer.withValues(alpha: 0.72);
      spans.add(
        TextSpan(
          text: token,
          style: baseStyle.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            background: Paint()..color = background,
          ),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return TextSpan(style: baseStyle, children: spans);
  }
}

Future<String?> _openFullscreenTextEditor(
  BuildContext context, {
  required String title,
  required String initialText,
  required String hintText,
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      fullscreenDialog: true,
      builder: (context) => _FullscreenTextEditorPage(
        title: title,
        initialText: initialText,
        hintText: hintText,
      ),
    ),
  );
}

class _FullscreenTextEditorPage extends StatefulWidget {
  const _FullscreenTextEditorPage({
    required this.title,
    required this.initialText,
    required this.hintText,
  });

  final String title;
  final String initialText;
  final String hintText;

  @override
  State<_FullscreenTextEditorPage> createState() =>
      _FullscreenTextEditorPageState();
}

class _FullscreenTextEditorPageState extends State<_FullscreenTextEditorPage> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('完成'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            key: const Key('fullscreenTextEditorField'),
            controller: _controller,
            autofocus: true,
            expands: true,
            minLines: null,
            maxLines: null,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(hintText: widget.hintText),
          ),
        ),
      ),
    );
  }
}

class _FullscreenEditButton extends StatelessWidget {
  const _FullscreenEditButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 38,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: scheme.surface.withValues(alpha: 0.86),
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const AppHugeIcon(
          HugeIcons.strokeRoundedMaximizeScreen,
          size: 18,
        ),
      ),
    );
  }
}

class _InstructField extends StatefulWidget {
  const _InstructField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<_InstructField> createState() => _InstructFieldState();
}

class _InstructFieldState extends State<_InstructField> {
  final FocusNode _focusNode = FocusNode();
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocus);
    widget.controller.addListener(_syncPreview);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocus);
    widget.controller.removeListener(_syncPreview);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocus() {
    if (_focusNode.hasFocus && !_expanded) {
      setState(() => _expanded = true);
    }
  }

  void _syncPreview() {
    if (!_expanded && mounted) setState(() {});
  }

  void _openEditor() {
    setState(() => _expanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _closeEditor() {
    _focusNode.unfocus();
    setState(() => _expanded = false);
  }

  Future<void> _openFullscreenEditor() async {
    final value = await _openFullscreenTextEditor(
      context,
      title: '全屏编辑表演指令',
      initialText: widget.controller.text,
      hintText: '例如：整体自然亲切，像熟人当面提醒，语气不要太夸张。',
    );
    if (value == null || !mounted) return;
    widget.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    widget.onChanged(value);
    setState(() => _expanded = true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = widget.controller.text.trim();
    final preview = value.isEmpty
        ? '可选。这里会作为 MiMo 的 role:user Instruct 发送。'
        : value;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AppPanel(
        padding: const EdgeInsets.all(12),
        child: _expanded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      AppHugeIcon(
                        HugeIcons.strokeRoundedMagicWand02,
                        size: 20,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '表演指令 / Instruct',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      TextButton(
                        onPressed: _closeEditor,
                        child: const Text('收起'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    children: <Widget>[
                      TextField(
                        key: const Key('instructTextField'),
                        controller: widget.controller,
                        focusNode: _focusNode,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: '例如：整体自然亲切，像熟人当面提醒，语气不要太夸张。',
                          prefixIcon: AppPrefixIcon(
                            HugeIcons.strokeRoundedMagicWand02,
                          ),
                          contentPadding: EdgeInsets.fromLTRB(16, 18, 56, 58),
                        ),
                        onChanged: widget.onChanged,
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: _FullscreenEditButton(
                          tooltip: '全屏编辑表演指令',
                          onPressed: _openFullscreenEditor,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _openEditor,
                  child: Row(
                    children: <Widget>[
                      AppHugeIcon(
                        HugeIcons.strokeRoundedMagicWand02,
                        size: 20,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '表演指令 / Instruct',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: value.isEmpty
                                        ? scheme.onSurfaceVariant
                                        : scheme.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppHugeIcon(
                        HugeIcons.strokeRoundedEdit02,
                        size: 18,
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

class _MimoTagInsertSheet extends StatefulWidget {
  const _MimoTagInsertSheet({
    required this.styleGroups,
    required this.audioGroups,
    required this.selectedStyleTags,
    required this.selectedAudioTags,
    required this.onStyleTagSelected,
    required this.onAudioTagSelected,
  });

  final List<MimoTagGroup> styleGroups;
  final List<MimoTagGroup> audioGroups;
  final Set<String> selectedStyleTags;
  final Set<String> selectedAudioTags;
  final ValueChanged<String> onStyleTagSelected;
  final ValueChanged<String> onAudioTagSelected;

  @override
  State<_MimoTagInsertSheet> createState() => _MimoTagInsertSheetState();
}

class _MimoTagInsertSheetState extends State<_MimoTagInsertSheet> {
  static const List<String> _quickStyleTags = <String>[
    '粤语',
    '四川话',
    '温柔',
    '开心',
    '严肃',
    '唱歌',
  ];
  static const List<String> _quickAudioTags = <String>[
    '轻笑',
    '叹气',
    '深呼吸',
    '呼喊',
    '哽咽',
    '停顿',
  ];

  final TextEditingController _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _insertStyleTag(String tag) {
    widget.onStyleTagSelected(tag.trim());
    Navigator.of(context).pop();
  }

  void _insertAudioTag(String tag) {
    widget.onAudioTagSelected(tag.trim());
    Navigator.of(context).pop();
  }

  void _insertCustom({required bool audioTag}) {
    final tag = _customController.text.trim();
    if (tag.isEmpty) return;
    if (audioTag) {
      _insertAudioTag(tag);
    } else {
      _insertStyleTag(tag);
    }
  }

  List<MimoTagGroup> _groupsWithoutTags(
    List<MimoTagGroup> groups,
    List<String> tags,
  ) {
    final excluded = tags.toSet();
    return groups
        .map(
          (group) => MimoTagGroup(
            title: group.title,
            description: group.description,
            tags: group.tags.where((tag) => !excluded.contains(tag)).toList(),
          ),
        )
        .where((group) => group.tags.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
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
            maxHeight: MediaQuery.sizeOf(context).height * 0.78,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const SectionHeader(
                  title: '插入标签',
                  subtitle: '风格标签会合并到文本开头，音频标签会插入到当前光标位置。',
                ),
                const SizedBox(height: 14),
                _QuickTagRows(
                  styleTags: _quickStyleTags,
                  audioTags: _quickAudioTags,
                  selectedStyleTags: widget.selectedStyleTags,
                  selectedAudioTags: widget.selectedAudioTags,
                  onStyleTagSelected: _insertStyleTag,
                  onAudioTagSelected: _insertAudioTag,
                ),
                const SizedBox(height: 16),
                _CustomTagComposer(
                  controller: _customController,
                  onStylePressed: () => _insertCustom(audioTag: false),
                  onAudioPressed: () => _insertCustom(audioTag: true),
                ),
                const SizedBox(height: 16),
                _TagToolboxSection(
                  title: '风格标签',
                  subtitle: '重复点击也会重复插入，例如：(粤语 粤语)',
                  groups: _groupsWithoutTags(
                    widget.styleGroups,
                    _quickStyleTags,
                  ),
                  selectedTags: widget.selectedStyleTags,
                  isAudioTag: false,
                  onTagSelected: _insertStyleTag,
                ),
                const SizedBox(height: 14),
                _TagToolboxSection(
                  title: '音频标签',
                  subtitle: '插入到光标位置，例如：[轻笑]',
                  groups: _groupsWithoutTags(
                    widget.audioGroups,
                    _quickAudioTags,
                  ),
                  selectedTags: widget.selectedAudioTags,
                  isAudioTag: true,
                  onTagSelected: _insertAudioTag,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickTagRows extends StatelessWidget {
  const _QuickTagRows({
    required this.styleTags,
    required this.audioTags,
    required this.selectedStyleTags,
    required this.selectedAudioTags,
    required this.onStyleTagSelected,
    required this.onAudioTagSelected,
  });

  final List<String> styleTags;
  final List<String> audioTags;
  final Set<String> selectedStyleTags;
  final Set<String> selectedAudioTags;
  final ValueChanged<String> onStyleTagSelected;
  final ValueChanged<String> onAudioTagSelected;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '常用标签',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final tag in styleTags)
                _MimoTagChip(
                  tag: tag,
                  selected: selectedStyleTags.contains(tag),
                  isAudioTag: false,
                  onSelected: () => onStyleTagSelected(tag),
                ),
              for (final tag in audioTags)
                _MimoTagChip(
                  tag: tag,
                  selected: selectedAudioTags.contains(tag),
                  isAudioTag: true,
                  onSelected: () => onAudioTagSelected(tag),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomTagComposer extends StatelessWidget {
  const _CustomTagComposer({
    required this.controller,
    required this.onStylePressed,
    required this.onAudioPressed,
  });

  final TextEditingController controller;
  final VoidCallback onStylePressed;
  final VoidCallback onAudioPressed;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            key: const Key('customMimoTagField'),
            controller: controller,
            decoration: const InputDecoration(
              labelText: '自定义标签',
              hintText: '输入不带括号或方括号的标签',
              prefixIcon: AppPrefixIcon(HugeIcons.strokeRoundedTextAlignLeft01),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: AppFlatActionButton(
                  onPressed: onStylePressed,
                  icon: HugeIcons.strokeRoundedTags,
                  label: '作为风格',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppFlatActionButton(
                  prominent: true,
                  onPressed: onAudioPressed,
                  icon: HugeIcons.strokeRoundedAudioWave01,
                  label: '作为音频',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TagToolboxSection extends StatelessWidget {
  const _TagToolboxSection({
    required this.title,
    required this.subtitle,
    required this.groups,
    required this.selectedTags,
    required this.isAudioTag,
    required this.onTagSelected,
  });

  final String title;
  final String subtitle;
  final List<MimoTagGroup> groups;
  final Set<String> selectedTags;
  final bool isAudioTag;
  final ValueChanged<String> onTagSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = isAudioTag ? scheme.tertiary : scheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            AppHugeIcon(
              isAudioTag
                  ? HugeIcons.strokeRoundedAudioWave01
                  : HugeIcons.strokeRoundedTags,
              color: accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final group in groups) ...<Widget>[
          Text(
            group.title,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final tag in group.tags) ...<Widget>[
                  _MimoTagChip(
                    tag: tag,
                    selected: selectedTags.contains(tag),
                    isAudioTag: isAudioTag,
                    onSelected: () => onTagSelected(tag),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          if (group != groups.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MimoTagChip extends StatelessWidget {
  const _MimoTagChip({
    required this.tag,
    required this.selected,
    required this.isAudioTag,
    required this.onSelected,
  });

  final String tag;
  final bool selected;
  final bool isAudioTag;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = isAudioTag ? scheme.tertiary : scheme.primary;
    return FilterChip(
      label: Text(tag),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
      selectedColor:
          (isAudioTag ? scheme.tertiaryContainer : scheme.primaryContainer)
              .withValues(alpha: 0.76),
      labelStyle: TextStyle(
        color: selected ? accent : scheme.onSurface,
        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
      ),
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
