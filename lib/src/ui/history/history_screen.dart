import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.appState});

  final AppState appState;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
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

  @override
  Widget build(BuildContext context) {
    final history = widget.appState.history;
    if (history.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: '暂无生成记录',
        subtitle: '生成语音后会自动保存在这里。',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Card(
          child: ListTile(
            leading: IconButton(
              tooltip: '播放',
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
            ),
            title: Text(
              item.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${item.voiceName} · ${(item.durationMs / 1000).toStringAsFixed(1)} 秒',
            ),
            trailing: Wrap(
              spacing: 4,
              children: <Widget>[
                IconButton(
                  tooltip: '分享',
                  onPressed: () {},
                  icon: const Icon(Icons.ios_share),
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: () => widget.appState.deleteHistoryItem(item.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
