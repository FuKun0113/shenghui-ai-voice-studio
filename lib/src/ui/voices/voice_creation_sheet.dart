import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/audio_input_service.dart';
import '../../state/app_state.dart';

class VoiceCreationSheet extends StatefulWidget {
  const VoiceCreationSheet({super.key, required this.appState});

  final AppState appState;

  @override
  State<VoiceCreationSheet> createState() => _VoiceCreationSheetState();
}

class _VoiceCreationSheetState extends State<VoiceCreationSheet> {
  bool _designMode = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _styleController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();
  final AudioInputService _audioInputService = AudioInputService();
  bool _recording = false;
  bool _saving = false;

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
      setState(() => _pathController.text = path);
    }
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _audioInputService.stopRecording();
      setState(() {
        _recording = false;
        if (path != null) _pathController.text = path;
      });
    } else {
      await _audioInputService.startRecording();
      setState(() => _recording = true);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    if (_designMode) {
      await widget.appState.designVoice(
        name: _nameController.text.trim(),
        stylePrompt: _styleController.text.trim(),
      );
    } else {
      await widget.appState.saveClonedVoice(
        name: _nameController.text.trim(),
        referenceAudioPath: _pathController.text.trim(),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SegmentedButton<bool>(
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: true, label: Text('设计音色')),
              ButtonSegment<bool>(value: false, label: Text('克隆音色')),
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
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (_designMode)
            TextField(
              key: const Key('stylePromptField'),
              controller: _styleController,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '音色描述',
                border: OutlineInputBorder(),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text('上传 mp3/wav，或直接录制一段清晰的人声。'),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickReferenceAudio,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('上传音频'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleRecording,
                        icon: Icon(_recording ? Icons.stop : Icons.mic),
                        label: Text(_recording ? '停止录音' : '开始录音'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('referencePathField'),
                  controller: _pathController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: '参考音频',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(_saving ? '保存中...' : '生成并保存'),
          ),
        ],
      ),
    );
  }
}
