import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../domain/generated_audio.dart';
import '../../services/audio_export_service.dart';
import '../../services/audio_playback_service.dart';
import '../../state/app_state.dart';
import '../widgets/app_panel.dart';
import '../widgets/generated_audio_player.dart';
import '../widgets/mimo_tagged_text.dart';

class GeneratedAudioDetailScreen extends StatefulWidget {
  const GeneratedAudioDetailScreen({
    super.key,
    required this.audio,
    required this.appState,
    required this.playbackService,
    required this.exportService,
    this.onAudioChanged,
  });

  final GeneratedAudio audio;
  final AppState appState;
  final AudioPlaybackController playbackService;
  final AudioExportController exportService;
  final ValueChanged<GeneratedAudio>? onAudioChanged;

  @override
  State<GeneratedAudioDetailScreen> createState() =>
      _GeneratedAudioDetailScreenState();
}

class _GeneratedAudioDetailScreenState
    extends State<GeneratedAudioDetailScreen> {
  late GeneratedAudio _audio = widget.audio;
  bool _working = false;

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

  Future<void> _download() async {
    try {
      final path = await widget.exportService.exportAudio(_audio);
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

  Future<void> _share() async {
    try {
      await widget.exportService.shareAudio(_audio);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('分享失败：$error')));
    }
  }

  Future<void> _regenerate() async {
    setState(() => _working = true);
    try {
      final audio = await widget.appState.regenerateAudio(_audio);
      if (!mounted) return;
      setState(() {
        _audio = audio;
        _working = false;
      });
      widget.onAudioChanged?.call(audio);
      await widget.playbackService.playFile(audio.audioPath);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _working = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('重生成失败：$error')));
    }
  }

  Future<void> _rename() async {
    final title = await showDialog<String>(
      context: context,
      builder: (context) =>
          _RenameAudioDialog(initialTitle: _audio.title ?? ''),
    );
    if (title == null || !mounted) return;
    final renamed = _audio.copyWith(title: title.trim());
    widget.appState.renameHistoryItem(_audio.id, title);
    setState(() => _audio = renamed);
    widget.onAudioChanged?.call(renamed);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除语音'),
        content: const Text('删除后将从历史记录中移除，确定继续吗？'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (widget.playbackService.playbackState.value.path == _audio.audioPath) {
      unawaited(widget.playbackService.stop());
    }
    widget.appState.deleteHistoryItem(_audio.id);
    Navigator.of(context).pop();
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
    final voice = widget.appState.voices
        .where((voice) => voice.id == _audio.voiceId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('语音详情'),
        actions: <Widget>[
          IconButton(
            tooltip: '命名语音',
            onPressed: _rename,
            icon: const AppHugeIcon(HugeIcons.strokeRoundedEdit02),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              LargeGeneratedAudioPlayer(
                audio: _audio,
                isPlaying: _isPlaying,
                playbackProgress: _playbackProgress,
                onTogglePlay: _working ? () {} : _togglePlay,
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  AudioActionButton(
                    icon: HugeIcons.strokeRoundedDownload01,
                    label: '下载',
                    onPressed: _download,
                  ),
                  const SizedBox(width: 8),
                  AudioActionButton(
                    icon: HugeIcons.strokeRoundedShare01,
                    label: '分享',
                    onPressed: _share,
                  ),
                  const SizedBox(width: 8),
                  AudioActionButton(
                    icon: _working
                        ? HugeIcons.strokeRoundedLoading03
                        : HugeIcons.strokeRoundedRefresh,
                    label: _working ? '正在重生成' : '重生成',
                    onPressed: _working ? null : _regenerate,
                    spinning: _working,
                  ),
                  const SizedBox(width: 8),
                  AudioActionButton(
                    icon: HugeIcons.strokeRoundedDelete01,
                    label: '删除',
                    danger: true,
                    onPressed: _delete,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SectionHeader(title: '音色'),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        IconBadge(
                          icon: voice?.isUserCreated == true
                              ? HugeIcons.strokeRoundedMic01
                              : HugeIcons.strokeRoundedVoice,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _audio.voiceName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                voice == null
                                    ? '原音色信息不可用'
                                    : voice.tags.take(4).join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CopyableTaggedTextBlock(
                title: '表演指令',
                text: _audio.stylePrompt,
                emptyText: '未填写表演指令',
                maxHeight: 180,
                collapsible: true,
              ),
              const SizedBox(height: 14),
              CopyableTaggedTextBlock(
                title: '生成文本',
                text: _audio.text,
                maxHeight: 320,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RenameAudioDialog extends StatefulWidget {
  const _RenameAudioDialog({required this.initialTitle});

  final String initialTitle;

  @override
  State<_RenameAudioDialog> createState() => _RenameAudioDialogState();
}

class _RenameAudioDialogState extends State<_RenameAudioDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialTitle,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('命名语音'),
      content: TextField(
        key: const Key('audioTitleField'),
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '语音名称',
          hintText: '留空则使用生成文本作为名称',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
