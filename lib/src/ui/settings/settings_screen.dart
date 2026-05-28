import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('MiMo 服务', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: const <Widget>[
              RadioListTile<String>(
                value: 'backend',
                groupValue: 'backend',
                onChanged: null,
                title: Text('后端代理'),
                subtitle: Text('正式版本推荐，API Key 保存在服务端。'),
              ),
              RadioListTile<String>(
                value: 'direct',
                groupValue: 'backend',
                onChanged: null,
                title: Text('原型直连 API Key'),
                subtitle: Text('仅用于本机 Demo，后续可切换到后端代理。'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const TextField(
          decoration: InputDecoration(
            labelText: '后端地址',
            hintText: 'https://api.example.com',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Card(
          child: ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('授权和隐私'),
            subtitle: Text('只能克隆本人或已获授权的声音。'),
          ),
        ),
      ],
    );
  }
}
