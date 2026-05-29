import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../services/audio_input_service.dart';
import '../../services/audio_playback_service.dart';
import '../../services/audio_validator.dart';
import '../../state/app_state.dart';
import '../widgets/app_panel.dart';

class VoiceCreationSheet extends StatefulWidget {
  const VoiceCreationSheet({
    super.key,
    required this.appState,
    this.audioInputService,
    this.showHeader = true,
  });

  final AppState appState;
  final AudioInputController? audioInputService;
  final bool showHeader;

  @override
  State<VoiceCreationSheet> createState() => _VoiceCreationSheetState();
}

class VoiceCreationScreen extends StatelessWidget {
  const VoiceCreationScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('创建音色')),
      body: SafeArea(
        child: VoiceCreationSheet(appState: appState, showHeader: false),
      ),
    );
  }
}

class _VoiceCreationSheetState extends State<VoiceCreationSheet> {
  static const String _readAloudPrompt = '今天阳光很好，窗外有微风。我用平稳清楚的声音，慢慢说完这段话。';

  bool _designMode = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _styleController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  late final AudioInputController _audioInputService =
      widget.audioInputService ?? AudioInputService();
  String _gender = '不限定';
  bool _recording = false;
  bool _referencePlaying = false;
  bool _saving = false;
  bool _generatingPreview = false;
  bool _generatingClonePreview = false;
  bool _designPreviewPlaying = false;
  bool _clonePreviewPlaying = false;
  String? _designPreviewPath;
  String? _clonePreviewPath;
  String? _managedReferencePath;
  String? _formError;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    AudioPlaybackService.instance.playbackState.addListener(_syncPlaybackState);
  }

  @override
  void dispose() {
    AudioPlaybackService.instance.playbackState.removeListener(
      _syncPlaybackState,
    );
    _nameController.dispose();
    _styleController.dispose();
    _pathController.dispose();
    unawaited(_audioInputService.dispose());
    super.dispose();
  }

  void _syncPlaybackState() {
    if (!mounted) return;
    final playback = AudioPlaybackService.instance.playbackState.value;
    final referencePath = _pathController.text.trim();
    final nextReferencePlaying =
        referencePath.isNotEmpty && playback.isPlayingPath(referencePath);
    final designPath = _designPreviewPath;
    final nextDesignPreviewPlaying =
        designPath != null && playback.isPlayingPath(designPath);
    final clonePath = _clonePreviewPath;
    final nextClonePreviewPlaying =
        clonePath != null && playback.isPlayingPath(clonePath);
    if (_referencePlaying == nextReferencePlaying &&
        _designPreviewPlaying == nextDesignPreviewPlaying &&
        _clonePreviewPlaying == nextClonePreviewPlaying) {
      return;
    }
    setState(() {
      _referencePlaying = nextReferencePlaying;
      _designPreviewPlaying = nextDesignPreviewPlaying;
      _clonePreviewPlaying = nextClonePreviewPlaying;
    });
  }

  Future<void> _pickReferenceAudio() async {
    final path = await _audioInputService.pickReferenceAudio();
    if (path != null) {
      await _setReferencePath(path);
    }
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _audioInputService.stopRecording();
      setState(() {
        _recording = false;
      });
      if (path != null) await _setReferencePath(path);
    } else {
      await _audioInputService.startRecording();
      setState(() {
        _recording = true;
      });
    }
  }

  Future<void> _toggleReferencePlayback() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    if (_referencePlaying) {
      await AudioPlaybackService.instance.stop();
      if (mounted) setState(() => _referencePlaying = false);
      return;
    }
    setState(() => _referencePlaying = true);
    try {
      await AudioPlaybackService.instance.playFile(path);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _referencePlaying = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('参考音频播放失败：$error')));
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _formError = '请输入音色名称');
      return;
    }
    if (!_designMode) {
      final path = _pathController.text.trim();
      if (path.isEmpty) {
        setState(() => _formError = '请先录制或上传参考音频');
        return;
      }
      final validation = await AudioValidator.validateReferenceFile(path);
      if (!validation.isValid) {
        setState(() {
          _formError = validation.message;
          _validationMessage = validation.message;
        });
        return;
      }
    }
    setState(() => _saving = true);
    if (_designMode) {
      final previewPath =
          _designPreviewPath ??
          await widget.appState.previewDesignedVoice(
            stylePrompt: _styleController.text.trim(),
          );
      await widget.appState.saveDesignedVoice(
        name: name,
        stylePrompt: _styleController.text.trim(),
        referenceAudioPath: previewPath,
        gender: _gender,
      );
    } else {
      await widget.appState.saveClonedVoice(
        name: name,
        referenceAudioPath:
            _managedReferencePath ?? _pathController.text.trim(),
        previewAudioPath: _clonePreviewPath,
        gender: _gender,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _generateDesignPreview() async {
    final stylePrompt = _styleController.text.trim();
    if (stylePrompt.isEmpty) {
      setState(() => _formError = '请先填写音色描述');
      return;
    }
    setState(() {
      _formError = null;
      _generatingPreview = true;
      _designPreviewPlaying = false;
    });
    try {
      final path = await widget.appState.previewDesignedVoice(
        stylePrompt: stylePrompt,
      );
      if (!mounted) return;
      setState(() {
        _designPreviewPath = path;
        _generatingPreview = false;
      });
      await AudioPlaybackService.instance.playFile(path);
      if (mounted) setState(() => _designPreviewPlaying = true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _generatingPreview = false;
        _formError = '试听生成失败：$error';
      });
    }
  }

  Future<void> _toggleDesignPreviewPlayback() async {
    final path = _designPreviewPath;
    if (path == null || path.isEmpty) return;
    if (_designPreviewPlaying) {
      await AudioPlaybackService.instance.stop();
      if (mounted) setState(() => _designPreviewPlaying = false);
      return;
    }
    try {
      await AudioPlaybackService.instance.playFile(path);
      if (mounted) setState(() => _designPreviewPlaying = true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _designPreviewPlaying = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('试听播放失败：$error')));
    }
  }

  Future<void> _generateClonePreview() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      setState(() => _formError = '请先录制或上传参考音频');
      return;
    }
    final validation = await AudioValidator.validateReferenceFile(path);
    if (!validation.isValid) {
      setState(() {
        _formError = validation.message;
        _validationMessage = validation.message;
      });
      return;
    }
    setState(() {
      _formError = null;
      _generatingClonePreview = true;
      _clonePreviewPlaying = false;
    });
    try {
      final preview = await widget.appState.previewClonedVoice(
        name: _nameController.text.trim(),
        referenceAudioPath: path,
        gender: _gender,
      );
      if (!mounted) return;
      setState(() {
        _managedReferencePath = preview.referenceAudioPath;
        _pathController.text = preview.referenceAudioPath;
        _clonePreviewPath = preview.previewAudioPath;
        _generatingClonePreview = false;
        _validationMessage = '参考音频已保存到本机，可用于后续生成';
      });
      await AudioPlaybackService.instance.playFile(preview.previewAudioPath);
      if (mounted) setState(() => _clonePreviewPlaying = true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _generatingClonePreview = false;
        _formError = '试听生成失败：$error';
      });
    }
  }

  Future<void> _toggleClonePreviewPlayback() async {
    final path = _clonePreviewPath;
    if (path == null || path.isEmpty) return;
    if (_clonePreviewPlaying) {
      await AudioPlaybackService.instance.stop();
      if (mounted) setState(() => _clonePreviewPlaying = false);
      return;
    }
    try {
      await AudioPlaybackService.instance.playFile(path);
      if (mounted) setState(() => _clonePreviewPlaying = true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _clonePreviewPlaying = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('试听播放失败：$error')));
    }
  }

  Future<void> _setReferencePath(String path) async {
    final validation = await AudioValidator.validateReferenceFile(path);
    setState(() {
      _pathController.text = path;
      _validationMessage = validation.message;
      _formError = validation.isValid ? null : validation.message;
      _referencePlaying = false;
      _clonePreviewPlaying = false;
      _clonePreviewPath = null;
      _managedReferencePath = null;
    });
  }

  void _applyDesignTemplate(String value) {
    _styleController.text = value;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.showHeader) ...<Widget>[
            const SectionHeader(
              title: '创建音色',
              subtitle: '设计音色会先生成试听参考音频，再用克隆能力复用。',
            ),
            const SizedBox(height: 14),
          ] else ...<Widget>[
            Text(
              '设计音色会先生成试听参考音频，再用克隆能力复用。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
          ],
          _FlatSegmentedPicker<bool>(
            value: _designMode,
            items: const <_FlatSegmentItem<bool>>[
              _FlatSegmentItem<bool>(
                value: true,
                icon: HugeIcons.strokeRoundedMagicWand02,
                label: '设计音色',
              ),
              _FlatSegmentItem<bool>(
                value: false,
                icon: HugeIcons.strokeRoundedMic01,
                label: '克隆音色',
              ),
            ],
            onChanged: (value) => setState(() => _designMode = value),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('voiceNameField'),
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '音色名称',
              prefixIcon: AppPrefixIcon(HugeIcons.strokeRoundedBadge),
            ),
          ),
          const SizedBox(height: 12),
          _FlatSegmentedPicker<String>(
            value: _gender,
            items: const <_FlatSegmentItem<String>>[
              _FlatSegmentItem<String>(
                value: '不限定',
                icon: HugeIcons.strokeRoundedSettings05,
                label: '不限定',
              ),
              _FlatSegmentItem<String>(
                value: '男声',
                icon: HugeIcons.strokeRoundedMale02,
                label: '男声',
                key: Key('maleVoiceSegment'),
              ),
              _FlatSegmentItem<String>(
                value: '女声',
                icon: HugeIcons.strokeRoundedFemale02,
                label: '女声',
                key: Key('femaleVoiceSegment'),
              ),
            ],
            onChanged: (value) => setState(() => _gender = value),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: _designMode
                ? Column(
                    key: const ValueKey<String>('designModeFields'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _VoiceDesignGuidance(
                        onTemplateSelected: _applyDesignTemplate,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('stylePromptField'),
                        controller: _styleController,
                        minLines: 4,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: '音色描述',
                          hintText: '写清年龄/性别、音色质感、语气情绪、语速节奏、角色人设或场景。',
                          prefixIcon: AppPrefixIcon(
                            HugeIcons.strokeRoundedEdit02,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: AppFlatActionButton(
                              prominent: true,
                              onPressed: _generatingPreview
                                  ? null
                                  : _generateDesignPreview,
                              icon: _generatingPreview
                                  ? HugeIcons.strokeRoundedLoading03
                                  : HugeIcons.strokeRoundedMagicWand02,
                              label: _generatingPreview ? '生成试听中...' : '生成试听',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppFlatActionButton(
                              onPressed: _designPreviewPath == null
                                  ? null
                                  : _toggleDesignPreviewPlayback,
                              icon: _designPreviewPlaying
                                  ? HugeIcons.strokeRoundedStop
                                  : HugeIcons.strokeRoundedPlay,
                              label: _designPreviewPlaying ? '停止试听' : '播放试听',
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey<String>('cloneModeFields'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        child: _recording
                            ? const _RequirementBox(
                                key: ValueKey<String>('recordingPrompt'),
                                icon: HugeIcons.strokeRoundedVoice,
                                title: '正在录音，请自然朗读',
                                text: _readAloudPrompt,
                                active: true,
                              )
                            : const _RequirementBox(
                                key: ValueKey<String>('uploadRequirements'),
                                icon: HugeIcons.strokeRoundedFileAudio,
                                title: '上传音频要求',
                                text:
                                    '建议 10-30 秒清晰单人声；安静环境录制；支持 mp3/wav；文件小于 5 MB；避免背景音乐、多人声和明显噪音。',
                              ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: AppFlatActionButton(
                              onPressed: _pickReferenceAudio,
                              icon: HugeIcons.strokeRoundedFileUpload,
                              label: '上传音频',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppFlatActionButton(
                              prominent: true,
                              onPressed: _toggleRecording,
                              icon: _recording
                                  ? HugeIcons.strokeRoundedStop
                                  : HugeIcons.strokeRoundedMic01,
                              label: _recording ? '停止录音' : '立即录音',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AppFlatActionButton(
                        key: const Key('referencePathField'),
                        onPressed: _pathController.text.trim().isEmpty
                            ? null
                            : _toggleReferencePlayback,
                        icon: _referencePlaying
                            ? HugeIcons.strokeRoundedStop
                            : HugeIcons.strokeRoundedPlay,
                        label: _pathController.text.trim().isEmpty
                            ? '参考音频'
                            : _referencePlaying
                            ? '停止参考音频'
                            : '播放参考音频',
                      ),
                      if (_validationMessage != null) ...<Widget>[
                        const SizedBox(height: 8),
                        Text(
                          _validationMessage!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: AppFlatActionButton(
                              onPressed: _generatingClonePreview
                                  ? null
                                  : _generateClonePreview,
                              icon: _generatingClonePreview
                                  ? HugeIcons.strokeRoundedLoading03
                                  : HugeIcons.strokeRoundedMagicWand02,
                              label: _generatingClonePreview
                                  ? '生成试听中...'
                                  : '生成试听',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppFlatActionButton(
                              onPressed: _clonePreviewPath == null
                                  ? null
                                  : _toggleClonePreviewPlayback,
                              icon: _clonePreviewPlaying
                                  ? HugeIcons.strokeRoundedStop
                                  : HugeIcons.strokeRoundedPlay,
                              label: _clonePreviewPlaying ? '停止试听' : '播放试听',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          if (_formError != null) ...<Widget>[
            Text(
              _formError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 10),
          ],
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const AppHugeIcon(HugeIcons.strokeRoundedCheckmarkCircle02),
            label: Text(
              _saving
                  ? '保存中...'
                  : _designMode && _designPreviewPath != null
                  ? '保存音色'
                  : '生成并保存',
            ),
          ),
        ],
      ),
    );
  }
}

class _FlatSegmentItem<T> {
  const _FlatSegmentItem({
    required this.value,
    required this.icon,
    required this.label,
    this.key,
  });

  final T value;
  final List<List<dynamic>> icon;
  final String label;
  final Key? key;
}

class _FlatSegmentedPicker<T> extends StatelessWidget {
  const _FlatSegmentedPicker({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<_FlatSegmentItem<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: <Widget>[
            for (final item in items)
              Expanded(
                child: _FlatSegmentButton<T>(
                  item: item,
                  selected: item.value == value,
                  onTap: () => onChanged(item.value),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FlatSegmentButton<T> extends StatelessWidget {
  const _FlatSegmentButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _FlatSegmentItem<T> item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        boxShadow: selected
            ? <BoxShadow>[
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppHugeIcon(
                    selected
                        ? HugeIcons.strokeRoundedCheckmarkCircle02
                        : item.icon,
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.label,
                      key: item.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: selected ? scheme.onPrimaryContainer : color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceDesignGuidance extends StatelessWidget {
  const _VoiceDesignGuidance({required this.onTemplateSelected});

  static const String _simpleTemplate =
      '五十多岁的中年男性，标准普通话，嗓音低沉有磁性，语气沉稳自信，语速适中，像纪录片旁白解说员。';
  static const String _professionalTemplate =
      '一位年迈的老先生，说带北方口音的普通话，语速缓慢而沉稳，嗓音略带沙哑和沧桑感，仿佛一位饱经风霜的老爷爷在讲故事，充满岁月的智慧。';

  final ValueChanged<String> onTemplateSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              AppHugeIcon(
                HugeIcons.strokeRoundedIdea01,
                color: scheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '写作维度',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const <Widget>[
              _PromptDimensionChip(label: '性别/年龄'),
              _PromptDimensionChip(label: '音色/质感'),
              _PromptDimensionChip(label: '情绪/语气'),
              _PromptDimensionChip(label: '语速/节奏'),
              _PromptDimensionChip(label: '角色/人设'),
              _PromptDimensionChip(label: '说话风格'),
              _PromptDimensionChip(label: '场景'),
              _PromptDimensionChip(label: '年代参照'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '建议 1-4 句写清核心特征；不要写混响、回声、EQ、压缩等后期效果词，也不要用“普通的”“正常的”这类模糊词。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: AppFlatActionButton(
                  onPressed: () => onTemplateSelected(_simpleTemplate),
                  icon: HugeIcons.strokeRoundedSparkles,
                  label: '简洁示例',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppFlatActionButton(
                  prominent: true,
                  onPressed: () => onTemplateSelected(_professionalTemplate),
                  icon: HugeIcons.strokeRoundedMagicWand02,
                  label: '专业示例',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromptDimensionChip extends StatelessWidget {
  const _PromptDimensionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RequirementBox extends StatelessWidget {
  const _RequirementBox({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    this.active = false,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: active
              ? scheme.primary.withValues(alpha: 0.3)
              : scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppHugeIcon(
            icon,
            color: active ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
