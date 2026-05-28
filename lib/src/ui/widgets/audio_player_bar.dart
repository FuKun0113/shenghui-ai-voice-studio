import 'package:flutter/material.dart';

import '../../services/audio_playback_service.dart';

class AudioPlayerBar extends StatelessWidget {
  const AudioPlayerBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.audioPath,
  });

  final String title;
  final String subtitle;
  final String? audioPath;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: '播放',
              onPressed: audioPath == null
                  ? null
                  : () async {
                      await AudioPlaybackService().playFile(audioPath!);
                    },
              icon: const Icon(Icons.play_arrow),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            IconButton(
              tooltip: '分享',
              onPressed: () {},
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
      ),
    );
  }
}
