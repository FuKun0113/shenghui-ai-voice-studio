import 'package:flutter/material.dart';

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
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _styleController.dispose();
    _pathController.dispose();
    super.dispose();
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
            TextField(
              key: const Key('referencePathField'),
              controller: _pathController,
              decoration: const InputDecoration(
                labelText: '参考音频路径',
                border: OutlineInputBorder(),
              ),
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
