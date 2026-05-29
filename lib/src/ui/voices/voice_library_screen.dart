import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../domain/voice.dart';
import '../../services/audio_playback_service.dart';
import '../../state/app_state.dart';
import '../widgets/app_panel.dart';
import '../widgets/empty_state.dart';
import '../widgets/voice_card.dart';
import 'voice_creation_sheet.dart';

class VoiceLibraryScreen extends StatefulWidget {
  const VoiceLibraryScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<VoiceLibraryScreen> createState() => _VoiceLibraryScreenState();
}

class _VoiceLibraryScreenState extends State<VoiceLibraryScreen> {
  static const List<String> _filters = <String>['全部', '官方', '自定义', '男声', '女声'];

  final TextEditingController _searchController = TextEditingController();
  String _filter = '全部';
  String? _playingVoiceId;
  String? _playingVoicePath;

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_sync);
    AudioPlaybackService.instance.playbackState.addListener(_syncPlayback);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_sync);
    AudioPlaybackService.instance.playbackState.removeListener(_syncPlayback);
    _searchController.dispose();
    super.dispose();
  }

  void _sync() => setState(() {});

  void _syncPlayback() {
    final state = AudioPlaybackService.instance.playbackState.value;
    final pendingPreview = _playingVoicePath?.startsWith('pending:') ?? false;
    final shouldClear =
        _playingVoiceId != null &&
        !pendingPreview &&
        (_playingVoicePath == null ||
            !state.isPlaying ||
            state.path != _playingVoicePath);
    if (shouldClear && mounted) {
      setState(() {
        _playingVoiceId = null;
        _playingVoicePath = null;
      });
    }
  }

  void _openCreationSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceCreationSheet(appState: widget.appState),
    );
  }

  Future<void> _togglePreview(Voice voice) async {
    if (_playingVoiceId == voice.id) {
      await AudioPlaybackService.instance.pause();
      if (mounted) {
        setState(() {
          _playingVoiceId = null;
          _playingVoicePath = null;
        });
      }
      return;
    }

    setState(() {
      _playingVoiceId = voice.id;
      _playingVoicePath = voice.previewAudioPath ?? 'pending:${voice.id}';
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (voice.previewAudioPath != null) {
        await AudioPlaybackService.instance.playFile(voice.previewAudioPath!);
        return;
      }
      final audio = await widget.appState.previewVoice(voice);
      if (mounted) {
        setState(() => _playingVoicePath = audio.audioPath);
      }
      await AudioPlaybackService.instance.playFile(audio.audioPath);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _playingVoiceId = null;
          _playingVoicePath = null;
        });
      }
      messenger.showSnackBar(SnackBar(content: Text('试听失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final builtinVoices = widget.appState.voices
        .where((voice) => voice.type == VoiceType.builtin)
        .toList();
    final aiVoices = widget.appState.voices
        .where((voice) => voice.type != VoiceType.builtin)
        .toList();
    final visibleVoices = _filteredVoices(widget.appState.voices);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: AppPanel(
              child: Row(
                children: <Widget>[
                  const IconBadge(icon: HugeIcons.strokeRoundedLibrary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '音色库',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${builtinVoices.length} 个官方音色 · ${aiVoices.length} 个自定义音色',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              key: const Key('voiceSearchField'),
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: '搜索音色',
                prefixIcon: AppPrefixIcon(HugeIcons.strokeRoundedSearch01),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                for (final filter in _filters) ...<Widget>[
                  FilterChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              '${visibleVoices.length} 个匹配音色',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: _VoiceList(
              appState: widget.appState,
              voices: visibleVoices,
              playingVoiceId: _playingVoiceId,
              emptyTitle: _filter == '自定义' ? '暂无自定义音色' : '暂无匹配音色',
              emptySubtitle: _filter == '自定义'
                  ? '设计或克隆一个音色后会显示在这里。'
                  : '换个关键词或分类试试。',
              onTogglePreview: _togglePreview,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreationSheet,
        icon: const AppHugeIcon(HugeIcons.strokeRoundedAdd01),
        label: const Text('创建音色'),
      ),
    );
  }

  List<Voice> _filteredVoices(List<Voice> voices) {
    final query = _searchController.text.trim().toLowerCase();
    return voices.where((voice) {
      final haystack = <String>[
        voice.name,
        ?voice.language,
        ?voice.gender,
        ...voice.tags,
      ].join(' ').toLowerCase();
      if (query.isNotEmpty && !haystack.contains(query)) return false;
      return switch (_filter) {
        '官方' => voice.type == VoiceType.builtin,
        '自定义' => voice.type != VoiceType.builtin,
        '男声' =>
          voice.gender == '男性' ||
              voice.gender == '男声' ||
              voice.gender == 'Male' ||
              voice.tags.contains('男声') ||
              voice.tags.contains('Male'),
        '女声' =>
          voice.gender == '女性' ||
              voice.gender == '女声' ||
              voice.gender == 'Female' ||
              voice.tags.contains('女声') ||
              voice.tags.contains('Female'),
        _ => true,
      };
    }).toList()..sort((a, b) {
      final selectedId = widget.appState.selectedVoice?.id;
      final aSelected = a.id == selectedId;
      final bSelected = b.id == selectedId;
      if (aSelected != bSelected) return aSelected ? -1 : 1;
      if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
      final aTime = a.lastUsedAt;
      final bTime = b.lastUsedAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
  }
}

class _VoiceList extends StatelessWidget {
  const _VoiceList({
    required this.appState,
    required this.voices,
    required this.playingVoiceId,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onTogglePreview,
  });

  final AppState appState;
  final List<Voice> voices;
  final String? playingVoiceId;
  final String emptyTitle;
  final String emptySubtitle;
  final ValueChanged<Voice> onTogglePreview;

  @override
  Widget build(BuildContext context) {
    if (voices.isEmpty) {
      return EmptyState(
        icon: HugeIcons.strokeRoundedVoiceId,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      itemCount: voices.length,
      itemBuilder: (context, index) {
        final voice = voices[index];
        return VoiceCard(
          voice: voice,
          selected: appState.selectedVoice?.id == voice.id,
          isPreviewing: playingVoiceId == voice.id,
          onUse: () => appState.selectVoice(voice.id),
          onPreview: () => onTogglePreview(voice),
          onFavorite: () => appState.toggleVoiceFavorite(voice.id),
          onDelete: voice.isUserCreated
              ? () => appState.deleteVoice(voice.id)
              : null,
        );
      },
    );
  }
}
