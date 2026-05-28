import 'package:flutter/material.dart';

import '../../domain/voice.dart';
import '../../state/app_state.dart';
import '../widgets/voice_card.dart';
import 'voice_creation_sheet.dart';

class VoiceLibraryScreen extends StatefulWidget {
  const VoiceLibraryScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<VoiceLibraryScreen> createState() => _VoiceLibraryScreenState();
}

class _VoiceLibraryScreenState extends State<VoiceLibraryScreen> {
  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_sync);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_sync);
    super.dispose();
  }

  void _sync() => setState(() {});

  void _openCreationSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => VoiceCreationSheet(appState: widget.appState),
    );
  }

  @override
  Widget build(BuildContext context) {
    final builtinVoices = widget.appState.voices
        .where((voice) => voice.type == VoiceType.builtin)
        .toList();
    final aiVoices = widget.appState.voices
        .where((voice) => voice.type != VoiceType.builtin)
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: <Widget>[
            const TabBar(
              tabs: <Widget>[
                Tab(text: '默认音色'),
                Tab(text: 'AI 音色'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  _VoiceList(appState: widget.appState, voices: builtinVoices),
                  _VoiceList(appState: widget.appState, voices: aiVoices),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreationSheet,
          icon: const Icon(Icons.add),
          label: const Text('创建音色'),
        ),
      ),
    );
  }
}

class _VoiceList extends StatelessWidget {
  const _VoiceList({required this.appState, required this.voices});

  final AppState appState;
  final List<Voice> voices;

  @override
  Widget build(BuildContext context) {
    if (voices.isEmpty) {
      return const Center(child: Text('暂无 AI 音色'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: voices.length,
      itemBuilder: (context, index) {
        final voice = voices[index];
        return VoiceCard(
          voice: voice,
          selected: appState.selectedVoice?.id == voice.id,
          onUse: () => appState.selectVoice(voice.id),
          onPreview: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('试听 ${voice.name}')));
          },
          onDelete: voice.isUserCreated
              ? () => appState.deleteVoice(voice.id)
              : null,
        );
      },
    );
  }
}
