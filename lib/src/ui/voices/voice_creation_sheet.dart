import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../services/audio_input_service.dart';
import '../../services/audio_playback_service.dart';
import '../../services/audio_validator.dart';
import '../../state/app_state.dart';
import '../widgets/app_panel.dart';

class VoiceCreationSheet extends StatefulWidget {
  const VoiceCreationSheet({super.key, required this.appState});

  final AppState appState;

  @override
  State<VoiceCreationSheet> createState() => _VoiceCreationSheetState();
}

class _VoiceCreationSheetState extends State<VoiceCreationSheet> {
  static const String _readAloudPrompt =
      '请跟读：今天的天气很好，我正在用自然稳定的声音录制一段样本，帮助系统学习我的音色。';

  bool _designMode = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _styleController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  final AudioInputService _audioInputService = AudioInputService();
  String _gender = '不限定';
  bool _recording = false;
  bool _showReadPrompt = false;
  bool _referencePlaying = false;
  bool _saving = false;
  String? _formError;
  String? _validationMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _styleController.dispose();
    _pathController.dispose();
    unawaited(_audioInputService.dispose());
    super.dispose();
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
        _showReadPrompt = true;
      });
    }
  }

  Future<void> _toggleReferencePlayback() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    if (_referencePlaying) {
      await AudioPlaybackService.instance.pause();
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
      await widget.appState.designVoice(
        name: name,
        stylePrompt: _styleController.text.trim(),
        gender: _gender,
      );
    } else {
      await widget.appState.saveClonedVoice(
        name: name,
        referenceAudioPath: _pathController.text.trim(),
        gender: _gender,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _setReferencePath(String path) async {
    final validation = await AudioValidator.validateReferenceFile(path);
    setState(() {
      _pathController.text = path;
      _validationMessage = validation.message;
      _formError = validation.isValid ? null : validation.message;
      _referencePlaying = false;
    });
  }

  void _applyDesignTemplate(String value) {
    _styleController.text = value;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 12,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.16),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SectionHeader(
                  title: '创建音色',
                  subtitle: '设计音色会先生成试听参考音频，再用克隆能力复用。',
                ),
                const SizedBox(height: 14),
                SegmentedButton<bool>(
                  segments: const <ButtonSegment<bool>>[
                    ButtonSegment<bool>(
                      value: true,
                      icon: AppHugeIcon(HugeIcons.strokeRoundedMagicWand02),
                      label: Text('设计音色'),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      icon: AppHugeIcon(HugeIcons.strokeRoundedMic01),
                      label: Text('克隆音色'),
                    ),
                  ],
                  selected: <bool>{_designMode},
                  onSelectionChanged: (values) =>
                      setState(() => _designMode = values.first),
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
                SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: '不限定',
                      icon: AppHugeIcon(HugeIcons.strokeRoundedSettings05),
                      label: Text('不限定'),
                    ),
                    ButtonSegment<String>(
                      value: '男声',
                      icon: AppHugeIcon(HugeIcons.strokeRoundedMale02),
                      label: Text('男声', key: Key('maleVoiceSegment')),
                    ),
                    ButtonSegment<String>(
                      value: '女声',
                      icon: AppHugeIcon(HugeIcons.strokeRoundedFemale02),
                      label: Text('女声', key: Key('femaleVoiceSegment')),
                    ),
                  ],
                  selected: <String>{_gender},
                  onSelectionChanged: (values) =>
                      setState(() => _gender = values.first),
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
                          ],
                        )
                      : Column(
                          key: const ValueKey<String>('cloneModeFields'),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const _RequirementBox(
                              icon: HugeIcons.strokeRoundedFileAudio,
                              title: '上传音频要求',
                              text:
                                  '建议 10-30 秒清晰单人声；安静环境录制；支持 mp3/wav；文件小于 5 MB；避免背景音乐、多人声和明显噪音。',
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              child: _showReadPrompt
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: _RequirementBox(
                                        icon: HugeIcons.strokeRoundedVoice,
                                        title: _recording
                                            ? '正在录音，请跟读'
                                            : '录音跟读文本',
                                        text: _readAloudPrompt,
                                        active: _recording,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
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
                                  ? HugeIcons.strokeRoundedPause
                                  : HugeIcons.strokeRoundedPlay,
                              label: _pathController.text.trim().isEmpty
                                  ? '参考音频'
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
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                if (_formError != null) ...<Widget>[
                  Text(
                    _formError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const AppHugeIcon(
                    HugeIcons.strokeRoundedCheckmarkCircle02,
                  ),
                  label: Text(_saving ? '保存中...' : '生成并保存'),
                ),
              ],
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
