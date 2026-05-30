import 'package:flutter/material.dart';

import '../services/local_popup_notice_store.dart';
import '../state/app_state.dart';
import 'app_shell.dart';
import 'app_theme.dart';

class ShenghuiApp extends StatelessWidget {
  const ShenghuiApp({super.key, required this.appState, this.popupNoticeStore});

  final AppState appState;
  final LocalPopupNoticeStore? popupNoticeStore;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '声绘',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AppShell(appState: appState, popupNoticeStore: popupNoticeStore),
    );
  }
}
