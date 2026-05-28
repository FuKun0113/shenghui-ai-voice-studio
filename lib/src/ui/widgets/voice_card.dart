import 'package:flutter/material.dart';

import '../../domain/voice.dart';

class VoiceCard extends StatelessWidget {
  const VoiceCard({
    super.key,
    required this.voice,
    required this.selected,
    required this.onUse,
    required this.onPreview,
    this.onDelete,
  });

  final Voice voice;
  final bool selected;
  final VoidCallback onUse;
  final VoidCallback onPreview;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(selected ? Icons.check : Icons.graphic_eq),
        ),
        title: Text(voice.name),
        subtitle: Text(_labelForType(voice.type)),
        trailing: Wrap(
          spacing: 4,
          children: <Widget>[
            IconButton(
              tooltip: '试听',
              onPressed: onPreview,
              icon: const Icon(Icons.play_arrow),
            ),
            IconButton(
              tooltip: '使用',
              onPressed: onUse,
              icon: const Icon(Icons.check_circle_outline),
            ),
            if (onDelete != null)
              IconButton(
                tooltip: '删除',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
      ),
    );
  }

  String _labelForType(VoiceType type) {
    return switch (type) {
      VoiceType.builtin => '默认音色',
      VoiceType.cloned => '克隆音色',
      VoiceType.designed => '设计音色',
    };
  }
}
