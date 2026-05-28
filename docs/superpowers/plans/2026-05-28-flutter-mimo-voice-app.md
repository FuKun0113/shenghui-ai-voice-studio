# Flutter MiMo Voice App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an Android-first Flutter app for MiMo text-to-speech, voice cloning, voice design, AI voice library management, generated audio history, and MiMo service settings.

**Architecture:** Scaffold a Flutter app with a small domain layer, a mockable service boundary, local app state, and four primary screens. The first pass runs end-to-end with mock audio/service behavior, then adds the MiMo request builder so builtin, cloned, and designed voices route through the correct generation path.

**Tech Stack:** Flutter 3.44.0, Dart 3.12.0, Material 3, `flutter_test`, `shared_preferences`, `flutter_secure_storage`, `file_picker`, `record`, `just_audio`, `path_provider`, `uuid`, `http`.

---

## File Structure

Create this structure after `flutter create`:

```text
lib/
  main.dart
  src/
    app/
      voice_clone_app.dart
      app_shell.dart
      app_theme.dart
    domain/
      audio_format.dart
      generation_request.dart
      generated_audio.dart
      service_config.dart
      voice.dart
    services/
      audio_input_service.dart
      audio_playback_service.dart
      audio_validator.dart
      local_voice_store.dart
      mimo_client.dart
      mock_mimo_service.dart
    state/
      app_state.dart
    ui/
      generate/
        generate_screen.dart
      history/
        history_screen.dart
      settings/
        settings_screen.dart
      voices/
        voice_creation_sheet.dart
        voice_library_screen.dart
      widgets/
        audio_player_bar.dart
        empty_state.dart
        voice_card.dart
test/
  domain/
    generation_request_test.dart
    voice_test.dart
  services/
    audio_validator_test.dart
    mimo_client_test.dart
  state/
    app_state_test.dart
  ui/
    app_navigation_test.dart
    generate_screen_test.dart
    history_screen_test.dart
    settings_screen_test.dart
    voice_library_screen_test.dart
```

Responsibilities:

- `domain/`: immutable app concepts with no Flutter UI dependencies.
- `services/`: audio, persistence, mock MiMo behavior, and MiMo request construction.
- `state/`: central `ChangeNotifier` state used by screens.
- `ui/`: screens and reusable widgets.
- `app/`: root app, navigation shell, and theme.

## Task 1: Scaffold Flutter Project

**Files:**
- Create: Flutter scaffold files from `flutter create`
- Modify: `pubspec.yaml`
- Verify: `test/widget_test.dart`

- [ ] **Step 1: Create the Flutter project**

Run:

```bash
flutter create . --platforms android,ios,macos,web --org com.yunque --project-name voice_clone_app
```

Expected:

```text
All done!
```

- [ ] **Step 2: Replace `pubspec.yaml` dependencies**

Modify `pubspec.yaml` so the dependencies section includes:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  file_picker: ^10.3.7
  flutter_secure_storage: ^10.0.0
  http: ^1.6.0
  just_audio: ^0.10.5
  path: ^1.9.1
  path_provider: ^2.1.5
  record: ^6.1.2
  shared_preferences: ^2.5.4
  uuid: ^4.5.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
```

- [ ] **Step 3: Fetch dependencies**

Run:

```bash
flutter pub get
```

Expected:

```text
Got dependencies!
```

- [ ] **Step 4: Run generated tests**

Run:

```bash
flutter test
```

Expected:

```text
All tests passed!
```

- [ ] **Step 5: Commit scaffold**

Run:

```bash
git add .
git commit -m "chore: scaffold Flutter app"
```

Expected:

```text
[master ...] chore: scaffold Flutter app
```

## Task 2: Add Domain Models And Routing Rules

**Files:**
- Create: `lib/src/domain/voice.dart`
- Create: `lib/src/domain/generated_audio.dart`
- Create: `lib/src/domain/generation_request.dart`
- Create: `lib/src/domain/audio_format.dart`
- Test: `test/domain/voice_test.dart`
- Test: `test/domain/generation_request_test.dart`

- [ ] **Step 1: Write voice model tests**

Create `test/domain/voice_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/voice.dart';

void main() {
  test('designed voices require reference audio after save', () {
    final voice = Voice.designed(
      id: 'designed-1',
      name: '温柔旁白',
      stylePrompt: '年轻女性，温柔，清晰',
      referenceAudioPath: '/tmp/designed.wav',
      previewAudioPath: '/tmp/designed.wav',
      createdAt: DateTime.utc(2026, 5, 28),
    );

    expect(voice.type, VoiceType.designed);
    expect(voice.requiresReferenceAudio, isTrue);
    expect(voice.referenceAudioPath, '/tmp/designed.wav');
  });

  test('builtin voices do not require local reference audio', () {
    final voice = Voice.builtin(
      id: 'mimo-mia',
      name: 'Mia',
      providerVoiceId: 'mimo_mia',
    );

    expect(voice.type, VoiceType.builtin);
    expect(voice.requiresReferenceAudio, isFalse);
    expect(voice.providerVoiceId, 'mimo_mia');
  });
}
```

- [ ] **Step 2: Write generation routing tests**

Create `test/domain/generation_request_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/generation_request.dart';
import 'package:voice_clone_app/src/domain/voice.dart';

void main() {
  test('builtin voice routes to builtin tts', () {
    final voice = Voice.builtin(
      id: 'mimo-mia',
      name: 'Mia',
      providerVoiceId: 'mimo_mia',
    );

    final request = GenerationRequest.fromVoice(
      text: '你好，欢迎使用 AI 语音工作台。',
      voice: voice,
      speed: 1.0,
      emotion: '自然',
      stylePrompt: '',
    );

    expect(request.route, GenerationRoute.builtinTts);
    expect(request.referenceAudioPath, isNull);
    expect(request.providerVoiceId, 'mimo_mia');
  });

  test('designed voice routes to voice clone with saved reference audio', () {
    final voice = Voice.designed(
      id: 'designed-1',
      name: '温柔旁白',
      stylePrompt: '年轻女性，温柔，清晰',
      referenceAudioPath: '/tmp/designed.wav',
      previewAudioPath: '/tmp/designed.wav',
      createdAt: DateTime.utc(2026, 5, 28),
    );

    final request = GenerationRequest.fromVoice(
      text: '这段文字应该使用固定参考音色生成。',
      voice: voice,
      speed: 1.0,
      emotion: '自然',
      stylePrompt: '更有亲和力',
    );

    expect(request.route, GenerationRoute.voiceClone);
    expect(request.referenceAudioPath, '/tmp/designed.wav');
    expect(request.providerVoiceId, isNull);
  });
}
```

- [ ] **Step 3: Run tests to verify failure**

Run:

```bash
flutter test test/domain
```

Expected:

```text
Error: Error when reading 'lib/src/domain/voice.dart'
```

- [ ] **Step 4: Implement audio format model**

Create `lib/src/domain/audio_format.dart`:

```dart
enum AudioFormat {
  mp3,
  wav,
  unsupported;

  static AudioFormat fromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp3')) return AudioFormat.mp3;
    if (lower.endsWith('.wav')) return AudioFormat.wav;
    return AudioFormat.unsupported;
  }
}
```

- [ ] **Step 5: Implement voice model**

Create `lib/src/domain/voice.dart`:

```dart
enum VoiceType { builtin, cloned, designed }

class Voice {
  const Voice({
    required this.id,
    required this.name,
    required this.type,
    this.providerVoiceId,
    this.referenceAudioPath,
    this.previewAudioPath,
    this.stylePrompt,
    this.createdAt,
    this.updatedAt,
  });

  factory Voice.builtin({
    required String id,
    required String name,
    required String providerVoiceId,
    String? previewAudioPath,
  }) {
    return Voice(
      id: id,
      name: name,
      type: VoiceType.builtin,
      providerVoiceId: providerVoiceId,
      previewAudioPath: previewAudioPath,
    );
  }

  factory Voice.cloned({
    required String id,
    required String name,
    required String referenceAudioPath,
    required DateTime createdAt,
    String? previewAudioPath,
  }) {
    return Voice(
      id: id,
      name: name,
      type: VoiceType.cloned,
      referenceAudioPath: referenceAudioPath,
      previewAudioPath: previewAudioPath ?? referenceAudioPath,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  factory Voice.designed({
    required String id,
    required String name,
    required String stylePrompt,
    required String referenceAudioPath,
    required String previewAudioPath,
    required DateTime createdAt,
  }) {
    return Voice(
      id: id,
      name: name,
      type: VoiceType.designed,
      stylePrompt: stylePrompt,
      referenceAudioPath: referenceAudioPath,
      previewAudioPath: previewAudioPath,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  final String id;
  final String name;
  final VoiceType type;
  final String? providerVoiceId;
  final String? referenceAudioPath;
  final String? previewAudioPath;
  final String? stylePrompt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isUserCreated => type == VoiceType.cloned || type == VoiceType.designed;
  bool get requiresReferenceAudio => type == VoiceType.cloned || type == VoiceType.designed;
}
```

- [ ] **Step 6: Implement generation request model**

Create `lib/src/domain/generation_request.dart`:

```dart
import 'voice.dart';

enum GenerationRoute { builtinTts, voiceClone }

class GenerationRequest {
  const GenerationRequest({
    required this.text,
    required this.voiceId,
    required this.voiceName,
    required this.route,
    required this.speed,
    required this.emotion,
    required this.stylePrompt,
    this.providerVoiceId,
    this.referenceAudioPath,
  });

  factory GenerationRequest.fromVoice({
    required String text,
    required Voice voice,
    required double speed,
    required String emotion,
    required String stylePrompt,
  }) {
    return GenerationRequest(
      text: text,
      voiceId: voice.id,
      voiceName: voice.name,
      route: voice.requiresReferenceAudio
          ? GenerationRoute.voiceClone
          : GenerationRoute.builtinTts,
      speed: speed,
      emotion: emotion,
      stylePrompt: stylePrompt,
      providerVoiceId: voice.providerVoiceId,
      referenceAudioPath: voice.referenceAudioPath,
    );
  }

  final String text;
  final String voiceId;
  final String voiceName;
  final GenerationRoute route;
  final double speed;
  final String emotion;
  final String stylePrompt;
  final String? providerVoiceId;
  final String? referenceAudioPath;
}
```

- [ ] **Step 7: Implement generated audio model**

Create `lib/src/domain/generated_audio.dart`:

```dart
class GeneratedAudio {
  const GeneratedAudio({
    required this.id,
    required this.text,
    required this.voiceId,
    required this.voiceName,
    required this.audioPath,
    required this.durationMs,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String voiceId;
  final String voiceName;
  final String audioPath;
  final int durationMs;
  final DateTime createdAt;
}
```

- [ ] **Step 8: Run tests to verify pass**

Run:

```bash
flutter test test/domain
```

Expected:

```text
All tests passed!
```

- [ ] **Step 9: Commit domain models**

Run:

```bash
git add lib/src/domain test/domain
git commit -m "feat: add voice domain models"
```

Expected:

```text
[master ...] feat: add voice domain models
```

## Task 3: Add App State And Mock MiMo Service

**Files:**
- Create: `lib/src/services/mock_mimo_service.dart`
- Create: `lib/src/services/local_voice_store.dart`
- Create: `lib/src/state/app_state.dart`
- Test: `test/state/app_state_test.dart`

- [ ] **Step 1: Write app state tests**

Create `test/state/app_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/voice.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';

void main() {
  test('starts with builtin voices and selects the first one', () {
    final state = AppState(mimoService: MockMimoService());

    expect(state.voices.where((voice) => voice.type == VoiceType.builtin), isNotEmpty);
    expect(state.selectedVoice, isNotNull);
  });

  test('saving a designed voice stores reference audio and routes through clone', () async {
    final state = AppState(mimoService: MockMimoService());

    final voice = await state.designVoice(
      name: '温柔旁白',
      stylePrompt: '年轻女性，温柔，清晰',
    );

    expect(voice.type, VoiceType.designed);
    expect(voice.referenceAudioPath, contains('designed-voice'));
    expect(state.voices.any((item) => item.id == voice.id), isTrue);
  });

  test('generated audio is appended to history', () async {
    final state = AppState(mimoService: MockMimoService());
    state.updateDraftText('你好，欢迎使用 AI 语音工作台。');

    final generated = await state.generateCurrentVoice();

    expect(generated.text, '你好，欢迎使用 AI 语音工作台。');
    expect(state.history.single.id, generated.id);
  });
}
```

- [ ] **Step 2: Run app state tests to verify failure**

Run:

```bash
flutter test test/state/app_state_test.dart
```

Expected:

```text
Error: Error when reading 'lib/src/state/app_state.dart'
```

- [ ] **Step 3: Implement mock MiMo service**

Create `lib/src/services/mock_mimo_service.dart`:

```dart
import '../domain/generated_audio.dart';
import '../domain/generation_request.dart';

class MockMimoService {
  Future<String> designVoiceReferenceAudio({
    required String stylePrompt,
    required String sampleText,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return '/mock/audio/designed-voice-$stamp.wav';
  }

  Future<GeneratedAudio> generateSpeech({
    required GenerationRequest request,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final stamp = DateTime.now().microsecondsSinceEpoch;
    return GeneratedAudio(
      id: 'audio-$stamp',
      text: request.text,
      voiceId: request.voiceId,
      voiceName: request.voiceName,
      audioPath: '/mock/audio/generated-$stamp.wav',
      durationMs: 3200,
      createdAt: DateTime.now(),
    );
  }
}
```

- [ ] **Step 4: Implement local voice seed data**

Create `lib/src/services/local_voice_store.dart`:

```dart
import '../domain/voice.dart';

class LocalVoiceStore {
  List<Voice> builtinVoices() {
    return <Voice>[
      Voice.builtin(
        id: 'mimo-mia',
        name: 'Mia',
        providerVoiceId: 'mimo_mia',
      ),
      Voice.builtin(
        id: 'mimo-chloe',
        name: 'Chloe',
        providerVoiceId: 'mimo_chloe',
      ),
      Voice.builtin(
        id: 'mimo-milo',
        name: 'Milo',
        providerVoiceId: 'mimo_milo',
      ),
      Voice.builtin(
        id: 'mimo-dean',
        name: 'Dean',
        providerVoiceId: 'mimo_dean',
      ),
    ];
  }
}
```

- [ ] **Step 5: Implement app state**

Create `lib/src/state/app_state.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/generated_audio.dart';
import '../domain/generation_request.dart';
import '../domain/voice.dart';
import '../services/local_voice_store.dart';
import '../services/mock_mimo_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required this.mimoService,
    LocalVoiceStore? voiceStore,
  }) : _voiceStore = voiceStore ?? LocalVoiceStore() {
    _voices = _voiceStore.builtinVoices();
    _selectedVoiceId = _voices.first.id;
  }

  final MockMimoService mimoService;
  final LocalVoiceStore _voiceStore;
  final Uuid _uuid = const Uuid();

  late List<Voice> _voices;
  final List<GeneratedAudio> _history = <GeneratedAudio>[];
  String? _selectedVoiceId;
  String _draftText = '';
  double _speed = 1.0;
  String _emotion = '自然';
  String _stylePrompt = '';
  bool _isGenerating = false;

  List<Voice> get voices => List<Voice>.unmodifiable(_voices);
  List<GeneratedAudio> get history => List<GeneratedAudio>.unmodifiable(_history);
  String get draftText => _draftText;
  double get speed => _speed;
  String get emotion => _emotion;
  String get stylePrompt => _stylePrompt;
  bool get isGenerating => _isGenerating;

  Voice? get selectedVoice {
    for (final voice in _voices) {
      if (voice.id == _selectedVoiceId) return voice;
    }
    return _voices.isEmpty ? null : _voices.first;
  }

  void selectVoice(String voiceId) {
    _selectedVoiceId = voiceId;
    notifyListeners();
  }

  void updateDraftText(String value) {
    _draftText = value;
    notifyListeners();
  }

  void updateSpeed(double value) {
    _speed = value;
    notifyListeners();
  }

  void updateEmotion(String value) {
    _emotion = value;
    notifyListeners();
  }

  void updateStylePrompt(String value) {
    _stylePrompt = value;
    notifyListeners();
  }

  Future<Voice> designVoice({
    required String name,
    required String stylePrompt,
  }) async {
    const sampleText = '你好，这是一段用于固定 AI 设计音色的标准试听文本。';
    final referenceAudioPath = await mimoService.designVoiceReferenceAudio(
      stylePrompt: stylePrompt,
      sampleText: sampleText,
    );
    final now = DateTime.now();
    final voice = Voice.designed(
      id: _uuid.v4(),
      name: name,
      stylePrompt: stylePrompt,
      referenceAudioPath: referenceAudioPath,
      previewAudioPath: referenceAudioPath,
      createdAt: now,
    );
    _voices = <Voice>[..._voices, voice];
    _selectedVoiceId = voice.id;
    notifyListeners();
    return voice;
  }

  Future<Voice> saveClonedVoice({
    required String name,
    required String referenceAudioPath,
  }) async {
    final now = DateTime.now();
    final voice = Voice.cloned(
      id: _uuid.v4(),
      name: name,
      referenceAudioPath: referenceAudioPath,
      createdAt: now,
    );
    _voices = <Voice>[..._voices, voice];
    _selectedVoiceId = voice.id;
    notifyListeners();
    return voice;
  }

  void deleteVoice(String voiceId) {
    _voices = _voices.where((voice) => voice.id != voiceId || !voice.isUserCreated).toList();
    if (_selectedVoiceId == voiceId) {
      _selectedVoiceId = _voices.first.id;
    }
    notifyListeners();
  }

  Future<GeneratedAudio> generateCurrentVoice() async {
    final voice = selectedVoice;
    if (voice == null) {
      throw StateError('请选择音色');
    }
    if (_draftText.trim().isEmpty) {
      throw StateError('请输入要生成的文本');
    }
    _isGenerating = true;
    notifyListeners();
    try {
      final request = GenerationRequest.fromVoice(
        text: _draftText.trim(),
        voice: voice,
        speed: _speed,
        emotion: _emotion,
        stylePrompt: _stylePrompt,
      );
      final generated = await mimoService.generateSpeech(request: request);
      _history.insert(0, generated);
      return generated;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  void deleteHistoryItem(String id) {
    _history.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}
```

- [ ] **Step 6: Run app state tests**

Run:

```bash
flutter test test/state/app_state_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 7: Commit app state**

Run:

```bash
git add lib/src/services lib/src/state test/state
git commit -m "feat: add app state and mock MiMo service"
```

Expected:

```text
[master ...] feat: add app state and mock MiMo service
```

## Task 4: Build App Shell, Theme, And Navigation

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/src/app/voice_clone_app.dart`
- Create: `lib/src/app/app_shell.dart`
- Create: `lib/src/app/app_theme.dart`
- Create: placeholder screen files under `lib/src/ui/`
- Test: `test/ui/app_navigation_test.dart`

- [ ] **Step 1: Write navigation widget test**

Create `test/ui/app_navigation_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/app/voice_clone_app.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';

void main() {
  testWidgets('bottom navigation switches between main tabs', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(VoiceCloneApp(appState: state));

    expect(find.text('生成'), findsWidgets);
    expect(find.text('输入文本'), findsOneWidget);

    await tester.tap(find.text('音色库').last);
    await tester.pumpAndSettle();
    expect(find.text('默认音色'), findsOneWidget);

    await tester.tap(find.text('历史').last);
    await tester.pumpAndSettle();
    expect(find.text('暂无生成记录'), findsOneWidget);

    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    expect(find.text('MiMo 服务'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run navigation test to verify failure**

Run:

```bash
flutter test test/ui/app_navigation_test.dart
```

Expected:

```text
Error: Error when reading 'lib/src/app/voice_clone_app.dart'
```

- [ ] **Step 3: Implement app entry**

Replace `lib/main.dart`:

```dart
import 'package:flutter/material.dart';

import 'src/app/voice_clone_app.dart';
import 'src/services/mock_mimo_service.dart';
import 'src/state/app_state.dart';

void main() {
  runApp(
    VoiceCloneApp(
      appState: AppState(mimoService: MockMimoService()),
    ),
  );
}
```

- [ ] **Step 4: Implement theme**

Create `lib/src/app/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF256D85),
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
```

- [ ] **Step 5: Implement root app**

Create `lib/src/app/voice_clone_app.dart`:

```dart
import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'app_shell.dart';
import 'app_theme.dart';

class VoiceCloneApp extends StatelessWidget {
  const VoiceCloneApp({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 语音工作台',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: AppShell(appState: appState),
    );
  }
}
```

- [ ] **Step 6: Implement placeholder screens**

Create `lib/src/ui/generate/generate_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class GenerateScreen extends StatelessWidget {
  const GenerateScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('输入文本'));
  }
}
```

Create `lib/src/ui/voices/voice_library_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class VoiceLibraryScreen extends StatelessWidget {
  const VoiceLibraryScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('默认音色'));
  }
}
```

Create `lib/src/ui/history/history_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('暂无生成记录'));
  }
}
```

Create `lib/src/ui/settings/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.appState});

  final AppState appState;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('MiMo 服务'));
  }
}
```

- [ ] **Step 7: Implement navigation shell**

Create `lib/src/app/app_shell.dart`:

```dart
import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../ui/generate/generate_screen.dart';
import '../ui/history/history_screen.dart';
import '../ui/settings/settings_screen.dart';
import '../ui/voices/voice_library_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.appState});

  final AppState appState;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      GenerateScreen(appState: widget.appState),
      VoiceLibraryScreen(appState: widget.appState),
      HistoryScreen(appState: widget.appState),
      SettingsScreen(appState: widget.appState),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('AI 语音工作台')),
      body: SafeArea(child: screens[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.graphic_eq), label: '生成'),
          NavigationDestination(icon: Icon(Icons.record_voice_over), label: '音色库'),
          NavigationDestination(icon: Icon(Icons.history), label: '历史'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 8: Run navigation test**

Run:

```bash
flutter test test/ui/app_navigation_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 9: Commit app shell**

Run:

```bash
git add lib/main.dart lib/src/app lib/src/ui test/ui/app_navigation_test.dart
git commit -m "feat: add app shell navigation"
```

Expected:

```text
[master ...] feat: add app shell navigation
```

## Task 5: Implement Generate Screen

**Files:**
- Modify: `lib/src/ui/generate/generate_screen.dart`
- Create: `lib/src/ui/widgets/audio_player_bar.dart`
- Test: `test/ui/generate_screen_test.dart`

- [ ] **Step 1: Write generate screen test**

Create `test/ui/generate_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/generate/generate_screen.dart';

void main() {
  testWidgets('generates speech and shows player', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(MaterialApp(home: GenerateScreen(appState: state)));

    await tester.enterText(find.byType(TextField).first, '欢迎使用 AI 语音工作台。');
    await tester.tap(find.text('生成语音'));
    await tester.pump();
    expect(find.text('生成中...'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('播放生成结果'), findsOneWidget);
    expect(state.history, hasLength(1));
  });
}
```

- [ ] **Step 2: Run generate screen test to verify failure**

Run:

```bash
flutter test test/ui/generate_screen_test.dart
```

Expected:

```text
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "生成语音">
```

- [ ] **Step 3: Implement audio player bar**

Create `lib/src/ui/widgets/audio_player_bar.dart`:

```dart
import 'package:flutter/material.dart';

class AudioPlayerBar extends StatelessWidget {
  const AudioPlayerBar({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: '播放',
              onPressed: () {},
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
```

- [ ] **Step 4: Implement generate screen**

Replace `lib/src/ui/generate/generate_screen.dart`:

```dart
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
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
```

- [ ] **Step 5: Run generate screen test**

Run:

```bash
flutter test test/ui/generate_screen_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 6: Commit generate screen**

Run:

```bash
git add lib/src/ui/generate lib/src/ui/widgets/audio_player_bar.dart test/ui/generate_screen_test.dart
git commit -m "feat: add speech generation screen"
```

Expected:

```text
[master ...] feat: add speech generation screen
```

## Task 6: Implement Voice Library And Creation Sheet

**Files:**
- Modify: `lib/src/ui/voices/voice_library_screen.dart`
- Create: `lib/src/ui/voices/voice_creation_sheet.dart`
- Create: `lib/src/ui/widgets/voice_card.dart`
- Test: `test/ui/voice_library_screen_test.dart`

- [ ] **Step 1: Write voice library test**

Create `test/ui/voice_library_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/voices/voice_library_screen.dart';

void main() {
  testWidgets('design voice saves an AI voice', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(MaterialApp(home: VoiceLibraryScreen(appState: state)));

    await tester.tap(find.text('创建音色'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('设计音色'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('voiceNameField')), '温柔旁白');
    await tester.enterText(find.byKey(const Key('stylePromptField')), '年轻女性，温柔，清晰');
    await tester.tap(find.text('生成并保存'));
    await tester.pumpAndSettle();

    expect(find.text('温柔旁白'), findsOneWidget);
    expect(state.voices.any((voice) => voice.name == '温柔旁白'), isTrue);
  });
}
```

- [ ] **Step 2: Run voice library test to verify failure**

Run:

```bash
flutter test test/ui/voice_library_screen_test.dart
```

Expected:

```text
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "创建音色">
```

- [ ] **Step 3: Implement voice card**

Create `lib/src/ui/widgets/voice_card.dart`:

```dart
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
```

- [ ] **Step 4: Implement voice creation sheet**

Create `lib/src/ui/voices/voice_creation_sheet.dart`:

```dart
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
            onSelectionChanged: (values) => setState(() => _designMode = values.first),
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
```

- [ ] **Step 5: Implement voice library screen**

Replace `lib/src/ui/voices/voice_library_screen.dart`:

```dart
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('试听 ${voice.name}')),
            );
          },
          onDelete: voice.isUserCreated ? () => appState.deleteVoice(voice.id) : null,
        );
      },
    );
  }
}
```

- [ ] **Step 6: Run voice library test**

Run:

```bash
flutter test test/ui/voice_library_screen_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 7: Commit voice library**

Run:

```bash
git add lib/src/ui/voices lib/src/ui/widgets/voice_card.dart test/ui/voice_library_screen_test.dart
git commit -m "feat: add voice library and creation flow"
```

Expected:

```text
[master ...] feat: add voice library and creation flow
```

## Task 7: Implement History Screen

**Files:**
- Modify: `lib/src/ui/history/history_screen.dart`
- Create: `lib/src/ui/widgets/empty_state.dart`
- Test: `test/ui/history_screen_test.dart`

- [ ] **Step 1: Write history screen test**

Create `test/ui/history_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/history/history_screen.dart';

void main() {
  testWidgets('shows generated audio history and supports delete', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    state.updateDraftText('历史记录测试文本');
    await state.generateCurrentVoice();

    await tester.pumpWidget(MaterialApp(home: HistoryScreen(appState: state)));
    expect(find.text('历史记录测试文本'), findsOneWidget);

    await tester.tap(find.byTooltip('删除'));
    await tester.pumpAndSettle();
    expect(find.text('暂无生成记录'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run history test to verify failure**

Run:

```bash
flutter test test/ui/history_screen_test.dart
```

Expected:

```text
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "历史记录测试文本">
```

- [ ] **Step 3: Implement empty state widget**

Create `lib/src/ui/widgets/empty_state.dart`:

```dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Implement history screen**

Replace `lib/src/ui/history/history_screen.dart`:

```dart
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
            title: Text(item.text, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${item.voiceName} · ${(item.durationMs / 1000).toStringAsFixed(1)} 秒'),
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
```

- [ ] **Step 5: Run history test**

Run:

```bash
flutter test test/ui/history_screen_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 6: Commit history screen**

Run:

```bash
git add lib/src/ui/history lib/src/ui/widgets/empty_state.dart test/ui/history_screen_test.dart
git commit -m "feat: add generated audio history"
```

Expected:

```text
[master ...] feat: add generated audio history
```

## Task 8: Implement Settings And Service Configuration

**Files:**
- Create: `lib/src/domain/service_config.dart`
- Modify: `lib/src/ui/settings/settings_screen.dart`
- Test: `test/ui/settings_screen_test.dart`

- [ ] **Step 1: Write settings screen test**

Create `test/ui/settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/services/mock_mimo_service.dart';
import 'package:voice_clone_app/src/state/app_state.dart';
import 'package:voice_clone_app/src/ui/settings/settings_screen.dart';

void main() {
  testWidgets('settings shows backend and direct api options', (tester) async {
    final state = AppState(mimoService: MockMimoService());
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(appState: state)));

    expect(find.text('MiMo 服务'), findsOneWidget);
    expect(find.text('后端代理'), findsOneWidget);
    expect(find.text('原型直连 API Key'), findsOneWidget);
    expect(find.text('授权和隐私'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run settings test to verify failure**

Run:

```bash
flutter test test/ui/settings_screen_test.dart
```

Expected:

```text
Expected: exactly one matching candidate
Actual: _TextWidgetFinder:<Found 0 widgets with text "后端代理">
```

- [ ] **Step 3: Implement service config model**

Create `lib/src/domain/service_config.dart`:

```dart
enum ServiceMode { backendProxy, directApiKey }

class ServiceConfig {
  const ServiceConfig({
    required this.mode,
    this.backendUrl,
    this.hasApiKey = false,
  });

  const ServiceConfig.backend()
      : mode = ServiceMode.backendProxy,
        backendUrl = '',
        hasApiKey = false;

  final ServiceMode mode;
  final String? backendUrl;
  final bool hasApiKey;
}
```

- [ ] **Step 4: Implement settings screen**

Replace `lib/src/ui/settings/settings_screen.dart`:

```dart
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
        Card(
          child: ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('授权和隐私'),
            subtitle: const Text('只能克隆本人或已获授权的声音。'),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Run settings test**

Run:

```bash
flutter test test/ui/settings_screen_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 6: Commit settings**

Run:

```bash
git add lib/src/domain/service_config.dart lib/src/ui/settings test/ui/settings_screen_test.dart
git commit -m "feat: add MiMo service settings"
```

Expected:

```text
[master ...] feat: add MiMo service settings
```

## Task 9: Add Audio Validation And MiMo Request Builder

**Files:**
- Create: `lib/src/services/audio_validator.dart`
- Create: `lib/src/services/mimo_client.dart`
- Test: `test/services/audio_validator_test.dart`
- Test: `test/services/mimo_client_test.dart`

- [ ] **Step 1: Write audio validation tests**

Create `test/services/audio_validator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/audio_format.dart';
import 'package:voice_clone_app/src/services/audio_validator.dart';

void main() {
  test('accepts mp3 and wav reference audio', () {
    expect(AudioValidator.detectFormat('/tmp/sample.mp3'), AudioFormat.mp3);
    expect(AudioValidator.detectFormat('/tmp/sample.wav'), AudioFormat.wav);
  });

  test('rejects unsupported reference audio formats', () {
    expect(
      () => AudioValidator.requireSupported('/tmp/sample.m4a'),
      throwsA(isA<UnsupportedAudioFormatException>()),
    );
  });
}
```

- [ ] **Step 2: Write MiMo request builder tests**

Create `test/services/mimo_client_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_clone_app/src/domain/generation_request.dart';
import 'package:voice_clone_app/src/domain/voice.dart';
import 'package:voice_clone_app/src/services/mimo_client.dart';

void main() {
  test('builtin request uses provider voice id', () {
    final voice = Voice.builtin(
      id: 'mimo-mia',
      name: 'Mia',
      providerVoiceId: 'mimo_mia',
    );
    final request = GenerationRequest.fromVoice(
      text: '你好',
      voice: voice,
      speed: 1.0,
      emotion: '自然',
      stylePrompt: '',
    );

    final body = MimoRequestBuilder.buildSpeechBody(request);

    expect(body['model'], 'mimo-v2.5-tts');
    expect(body['voice'], 'mimo_mia');
  });

  test('designed request uses voice clone model and reference audio path', () {
    final voice = Voice.designed(
      id: 'designed-1',
      name: '温柔旁白',
      stylePrompt: '年轻女性，温柔，清晰',
      referenceAudioPath: '/tmp/designed.wav',
      previewAudioPath: '/tmp/designed.wav',
      createdAt: DateTime.utc(2026, 5, 28),
    );
    final request = GenerationRequest.fromVoice(
      text: '你好',
      voice: voice,
      speed: 1.0,
      emotion: '自然',
      stylePrompt: '',
    );

    final body = MimoRequestBuilder.buildSpeechBody(request);

    expect(body['model'], 'mimo-v2.5-tts-voiceclone');
    expect(body['referenceAudioPath'], '/tmp/designed.wav');
  });
}
```

- [ ] **Step 3: Run service tests to verify failure**

Run:

```bash
flutter test test/services
```

Expected:

```text
Error: Error when reading 'lib/src/services/audio_validator.dart'
```

- [ ] **Step 4: Implement audio validator**

Create `lib/src/services/audio_validator.dart`:

```dart
import '../domain/audio_format.dart';

class UnsupportedAudioFormatException implements Exception {
  const UnsupportedAudioFormatException(this.path);

  final String path;

  @override
  String toString() => 'Unsupported audio format: $path';
}

class AudioValidator {
  static AudioFormat detectFormat(String path) {
    return AudioFormat.fromPath(path);
  }

  static void requireSupported(String path) {
    final format = detectFormat(path);
    if (format == AudioFormat.unsupported) {
      throw UnsupportedAudioFormatException(path);
    }
  }
}
```

- [ ] **Step 5: Implement MiMo request builder**

Create `lib/src/services/mimo_client.dart`:

```dart
import '../domain/generation_request.dart';

class MimoRequestBuilder {
  static Map<String, Object?> buildSpeechBody(GenerationRequest request) {
    return switch (request.route) {
      GenerationRoute.builtinTts => <String, Object?>{
          'model': 'mimo-v2.5-tts',
          'text': request.text,
          'voice': request.providerVoiceId,
          'speed': request.speed,
          'emotion': request.emotion,
          'stylePrompt': request.stylePrompt,
        },
      GenerationRoute.voiceClone => <String, Object?>{
          'model': 'mimo-v2.5-tts-voiceclone',
          'text': request.text,
          'referenceAudioPath': request.referenceAudioPath,
          'speed': request.speed,
          'emotion': request.emotion,
          'stylePrompt': request.stylePrompt,
        },
    };
  }
}
```

- [ ] **Step 6: Run service tests**

Run:

```bash
flutter test test/services
```

Expected:

```text
All tests passed!
```

- [ ] **Step 7: Commit service boundary**

Run:

```bash
git add lib/src/services/audio_validator.dart lib/src/services/mimo_client.dart test/services
git commit -m "feat: add audio validation and MiMo routing"
```

Expected:

```text
[master ...] feat: add audio validation and MiMo routing
```

## Task 10: Add Audio Input And Playback Services

**Files:**
- Create: `lib/src/services/audio_input_service.dart`
- Create: `lib/src/services/audio_playback_service.dart`
- Modify: `lib/src/ui/voices/voice_creation_sheet.dart`
- Modify: `lib/src/ui/widgets/audio_player_bar.dart`
- Test: `test/services/audio_validator_test.dart`

- [ ] **Step 1: Extend audio validator tests for selected upload paths**

Append this test to `test/services/audio_validator_test.dart`:

```dart
test('returns the original path for supported reference audio', () {
  expect(AudioValidator.requireSupported('/tmp/reference.wav'), '/tmp/reference.wav');
  expect(AudioValidator.requireSupported('/tmp/reference.mp3'), '/tmp/reference.mp3');
});
```

- [ ] **Step 2: Run validator test to verify failure**

Run:

```bash
flutter test test/services/audio_validator_test.dart
```

Expected:

```text
This expression has a type of 'void' so its value can't be used.
```

- [ ] **Step 3: Update audio validator to return validated path**

Replace `lib/src/services/audio_validator.dart`:

```dart
import '../domain/audio_format.dart';

class UnsupportedAudioFormatException implements Exception {
  const UnsupportedAudioFormatException(this.path);

  final String path;

  @override
  String toString() => 'Unsupported audio format: $path';
}

class AudioValidator {
  static AudioFormat detectFormat(String path) {
    return AudioFormat.fromPath(path);
  }

  static String requireSupported(String path) {
    final format = detectFormat(path);
    if (format == AudioFormat.unsupported) {
      throw UnsupportedAudioFormatException(path);
    }
    return path;
  }
}
```

- [ ] **Step 4: Implement audio input service**

Create `lib/src/services/audio_input_service.dart`:

```dart
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'audio_validator.dart';

class AudioInputService {
  AudioInputService({AudioRecorder? recorder}) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  Future<String?> pickReferenceAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['mp3', 'wav'],
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null) return null;
    return AudioValidator.requireSupported(path);
  }

  Future<String> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw StateError('请允许麦克风权限后再录音');
    }
    final directory = await getTemporaryDirectory();
    final filePath = p.join(
      directory.path,
      'voice-reference-${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav),
      path: filePath,
    );
    return filePath;
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    return AudioValidator.requireSupported(path);
  }

  Future<void> dispose() {
    return _recorder.dispose();
  }
}
```

- [ ] **Step 5: Implement audio playback service**

Create `lib/src/services/audio_playback_service.dart`:

```dart
import 'package:just_audio/just_audio.dart';

class AudioPlaybackService {
  AudioPlaybackService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  Future<void> playFile(String path) async {
    await _player.setFilePath(path);
    await _player.play();
  }

  Future<void> stop() {
    return _player.stop();
  }

  Future<void> dispose() {
    return _player.dispose();
  }
}
```

- [ ] **Step 6: Add upload and record controls to voice creation sheet**

Modify `lib/src/ui/voices/voice_creation_sheet.dart`:

```dart
import '../../services/audio_input_service.dart';
```

Add state fields inside `_VoiceCreationSheetState`:

```dart
final AudioInputService _audioInputService = AudioInputService();
bool _recording = false;
```

Add methods inside `_VoiceCreationSheetState`:

```dart
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
```

Update `dispose()`:

```dart
@override
void dispose() {
  _nameController.dispose();
  _styleController.dispose();
  _pathController.dispose();
  _audioInputService.dispose();
  super.dispose();
}
```

Replace the clone-mode `TextField` branch with:

```dart
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
)
```

- [ ] **Step 7: Connect audio player bar to playback service**

Modify `lib/src/ui/widgets/audio_player_bar.dart` constructor:

```dart
const AudioPlayerBar({
  super.key,
  required this.title,
  required this.subtitle,
  this.audioPath,
});

final String? audioPath;
```

Import the playback service:

```dart
import '../../services/audio_playback_service.dart';
```

Replace the play button `onPressed` with:

```dart
onPressed: audioPath == null
    ? null
    : () {
        AudioPlaybackService().playFile(audioPath!);
      },
```

In `GenerateScreen`, pass the generated path:

```dart
AudioPlayerBar(
  title: '播放生成结果',
  subtitle: _lastAudio!.voiceName,
  audioPath: _lastAudio!.audioPath,
)
```

- [ ] **Step 8: Run service tests**

Run:

```bash
flutter test test/services/audio_validator_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 9: Run analyzer**

Run:

```bash
flutter analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 10: Commit audio services**

Run:

```bash
git add pubspec.yaml lib/src/services/audio_input_service.dart lib/src/services/audio_playback_service.dart lib/src/services/audio_validator.dart lib/src/ui/voices/voice_creation_sheet.dart lib/src/ui/widgets/audio_player_bar.dart lib/src/ui/generate/generate_screen.dart test/services/audio_validator_test.dart
git commit -m "feat: add audio input and playback services"
```

Expected:

```text
[master ...] feat: add audio input and playback services
```

## Task 11: Final Verification

**Files:**
- Modify only files needed to fix analysis or test failures found by verification.

- [ ] **Step 1: Run formatter**

Run:

```bash
dart format lib test
```

Expected:

```text
Formatted ...
```

or:

```text
Formatted 0 files
```

- [ ] **Step 2: Run analyzer**

Run:

```bash
flutter analyze
```

Expected:

```text
No issues found!
```

- [ ] **Step 3: Run full test suite**

Run:

```bash
flutter test
```

Expected:

```text
All tests passed!
```

- [ ] **Step 4: Confirm Android emulator is available**

Run:

```bash
flutter emulators
```

Expected includes:

```text
Pixel_10_Pro
```

- [ ] **Step 5: Commit verification fixes**

If formatter or analyzer changed files, run:

```bash
git add lib test
git commit -m "chore: polish Flutter voice app"
```

Expected when files changed:

```text
[master ...] chore: polish Flutter voice app
```

Expected when no files changed:

```text
nothing to commit, working tree clean
```

## Coverage Review

Spec coverage:

- Text-to-speech generation: Task 5 and Task 9.
- Default voices: Task 3 and Task 6.
- Voice cloning from recording/upload path: Task 3, Task 6, Task 9, and Task 10 establish state, UI entry, validation, file upload, live recording, and saved reference audio.
- Voice design: Task 3 and Task 6.
- Designed voice saved as reference audio and reused through clone route: Task 2, Task 3, and Task 9.
- Voice library management: Task 6.
- Generated history: Task 7.
- Settings: Task 8.
- Error handling: Task 5, Task 9, and Task 10 establish user-visible validation, generation errors, unsupported format errors, and microphone permission errors.
- Privacy and consent: Task 8 includes copy and Task 10 keeps recording behind explicit user action.
- Testing: Each implementation task starts with tests and ends with verification.

No placeholder terms are intentionally left in this plan. The first implementation produces a working Flutter shell with mock MiMo generation, real audio input/playback services, and a tested MiMo routing boundary.
