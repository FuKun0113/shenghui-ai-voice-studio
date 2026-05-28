import 'package:flutter/material.dart';

import '../../domain/generated_audio.dart';
import '../../state/app_state.dart';
import '../widgets/audio_player_bar.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  GeneratedAudio? _lastAudio;
  String? _error;

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

  Future<void> _generate() async {
    setState(() => _error = null);
    try {
      final audio = await widget.appState.generateCurrentVoice();
      setState(() => _lastAudio = audio);
    } on StateError catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedVoice = widget.appState.selectedVoice;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Card(
          child: ListTile(
            leading: const Icon(Icons.record_voice_over),
            title: Text(selectedVoice?.name ?? '未选择音色'),
            subtitle: const Text('当前音色'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          minLines: 6,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: '输入文本',
            border: OutlineInputBorder(),
          ),
          onChanged: widget.appState.updateDraftText,
        ),
        const SizedBox(height: 16),
        Text('语速 ${widget.appState.speed.toStringAsFixed(1)}'),
        Slider(
          min: 0.6,
          max: 1.6,
          divisions: 10,
          value: widget.appState.speed,
          onChanged: widget.appState.updateSpeed,
        ),
        TextField(
          decoration: const InputDecoration(
            labelText: '风格提示',
            border: OutlineInputBorder(),
          ),
          onChanged: widget.appState.updateStylePrompt,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: widget.appState.isGenerating ? null : _generate,
          icon: const Icon(Icons.auto_awesome),
          label: Text(widget.appState.isGenerating ? '生成中...' : '生成语音'),
        ),
        if (_error != null) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_lastAudio != null) ...<Widget>[
          const SizedBox(height: 16),
          AudioPlayerBar(
            title: '播放生成结果',
            subtitle: _lastAudio!.voiceName,
          ),
        ],
      ],
    );
  }
}
