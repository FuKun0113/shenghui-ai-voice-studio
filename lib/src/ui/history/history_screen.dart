import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../domain/generated_audio.dart';
import '../../services/audio_export_service.dart';
import '../../services/audio_playback_service.dart';
import '../../state/app_state.dart';
import '../widgets/app_panel.dart';
import '../widgets/empty_state.dart';
import '../widgets/generated_audio_player.dart';
import 'generated_audio_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  HistoryScreen({
    super.key,
    required this.appState,
    this.onReuseText,
    AudioPlaybackController? playbackService,
    AudioExportController? exportService,
  }) : playbackService = playbackService ?? AudioPlaybackService.instance,
       exportService = exportService ?? AudioExportService.instance;

  final AppState appState;
  final ValueChanged<String>? onReuseText;
  final AudioPlaybackController playbackService;
  final AudioExportController exportService;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Set<String> _regeneratingIds = <String>{};

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_sync);
    widget.playbackService.playbackState.addListener(_syncPlayback);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_sync);
    widget.playbackService.playbackState.removeListener(_syncPlayback);
    super.dispose();
  }

  void _sync() => setState(() {});

  void _syncPlayback() {
    if (mounted) setState(() {});
  }

  Future<void> _togglePlay(GeneratedAudio item) async {
    if (_isPlaying(item)) {
      await widget.playbackService.pause();
      return;
    }
    try {
      await widget.playbackService.playFile(item.audioPath);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('播放失败：$error')));
    }
  }

  Future<void> _export(GeneratedAudio item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await widget.exportService.exportAudio(item);
      if (path == null) return;
      messenger.showSnackBar(const SnackBar(content: Text('语音已保存')));
    } on Object catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }

  Future<void> _share(GeneratedAudio item) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.exportService.shareAudio(item);
    } on Object catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('分享失败：$error')));
    }
  }

  Future<void> _regenerate(GeneratedAudio item) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _regeneratingIds.add(item.id));
    try {
      final audio = await widget.appState.regenerateAudio(item);
      if (!mounted) return;
      setState(() => _regeneratingIds.remove(item.id));
      await widget.playbackService.playFile(audio.audioPath);
    } on Object catch (error) {
      if (mounted) setState(() => _regeneratingIds.remove(item.id));
      messenger.showSnackBar(SnackBar(content: Text('重生成失败：$error')));
    }
  }

  void _delete(GeneratedAudio item) {
    if (_isPlaying(item)) {
      unawaited(widget.playbackService.stop());
    }
    widget.appState.deleteHistoryItem(item.id);
  }

  void _openDetail(GeneratedAudio item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GeneratedAudioDetailScreen(
          audio: item,
          appState: widget.appState,
          playbackService: widget.playbackService,
          exportService: widget.exportService,
          onAudioChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  bool _isPlaying(GeneratedAudio item) {
    return widget.playbackService.playbackState.value.isPlayingPath(
      item.audioPath,
    );
  }

  double _progressFor(GeneratedAudio item) {
    final state = widget.playbackService.playbackState.value;
    if (state.path != item.audioPath) return 0;
    final totalMs = state.duration?.inMilliseconds ?? item.durationMs;
    if (totalMs <= 0) return state.progress;
    return (state.position.inMilliseconds / totalMs).clamp(0, 1).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.appState.history;
    if (history.isEmpty) {
      return const EmptyState(
        icon: HugeIcons.strokeRoundedClock01,
        title: '暂无生成记录',
        subtitle: '生成语音后会自动保存在这里。',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: history.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppPanel(
              child: Row(
                children: <Widget>[
                  const IconBadge(icon: HugeIcons.strokeRoundedClock01),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SectionHeader(
                      title: '生成历史',
                      subtitle: '${history.length} 条语音记录',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final item = history[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GeneratedAudioCapsule(
            audio: item,
            isPlaying: _isPlaying(item),
            playbackProgress: _progressFor(item),
            onTogglePlay: () => _togglePlay(item),
            onOpen: () => _openDetail(item),
            onDownload: () => _export(item),
            onShare: () => _share(item),
            onDelete: () => _delete(item),
            onRegenerate: () => _regenerate(item),
            isRegenerating: _regeneratingIds.contains(item.id),
          ),
        );
      },
    );
  }
}
