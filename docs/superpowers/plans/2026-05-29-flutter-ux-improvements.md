# Flutter UX Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the 7 approved Flutter UX improvements for persistence, generation, recording, voice library, long text, history, and settings.

**Architecture:** Keep the current `AppState + services + ui` structure. Add small persistence and text services, extend domain models with local-only UX metadata, then update each screen to use those state APIs.

**Tech Stack:** Flutter, Dart, shared_preferences, flutter_secure_storage, file_picker, record, just_audio, share_plus, flutter_test.

---

## File Structure

- Modify `lib/src/domain/voice.dart`: add `favorite`, `lastUsedAt`, `copyWith`, JSON helpers for user voices.
- Modify `lib/src/domain/generated_audio.dart`: add `title`, `favorite`, `copyWith`, JSON helpers.
- Create `lib/src/domain/draft_state.dart`: holds draft text, style prompt, speed, emotion, selected voice id.
- Create `lib/src/domain/connection_test_result.dart`: typed result for MiMo API testing.
- Create `lib/src/services/local_json_store.dart`: shared string-list JSON storage abstraction with in-memory test store.
- Modify `lib/src/services/local_voice_store.dart`: load built-ins plus persisted user voices and voice overlays.
- Create `lib/src/services/local_history_store.dart`: persist generated audio metadata.
- Create `lib/src/services/local_draft_store.dart`: persist draft and generation parameters.
- Create `lib/src/services/text_segmenter.dart`: split long text into stable generation segments.
- Modify `lib/src/services/audio_validator.dart`: validate file exists, extension, and MiMo Base64 size limit.
- Modify `lib/src/services/audio_input_service.dart`: return recording metadata and support test injection.
- Modify `lib/src/services/mimo_client.dart`: add `testConnection()` to `MimoService`.
- Modify `lib/src/services/mock_mimo_service.dart`: implement connection test and keep deterministic test behavior.
- Modify `lib/src/state/app_state.dart`: load/save local state and expose UX actions.
- Modify `lib/main.dart`: load local app data before `runApp`.
- Modify `lib/src/app/app_shell.dart`: pass callbacks for settings navigation, reuse text, and voice selection.
- Modify `lib/src/ui/generate/generate_screen.dart`: generation phases, document stats, segmentation, retry, generated actions.
- Modify `lib/src/ui/voices/voice_creation_sheet.dart`: recording timer, validation, preview, re-record, required fields.
- Modify `lib/src/ui/voices/voice_library_screen.dart`: search, filters, favorite, recent use.
- Modify `lib/src/ui/history/history_screen.dart`: persisted asset library actions and filters.
- Modify `lib/src/ui/settings/settings_screen.dart`: API Key reveal and test connection.
- Add and update tests under `test/domain`, `test/services`, `test/state`, and `test/ui`.

## Task 1: Domain Models And Serialization

**Files:**
- Modify: `lib/src/domain/voice.dart`
- Modify: `lib/src/domain/generated_audio.dart`
- Create: `lib/src/domain/draft_state.dart`
- Create: `lib/src/domain/connection_test_result.dart`
- Test: `test/domain/voice_test.dart`
- Test: `test/domain/generated_audio_test.dart`
- Test: `test/domain/draft_state_test.dart`

- [ ] **Step 1: Write failing domain tests**

Add tests that lock the new public API:

```dart
test('voice copyWith preserves fields and updates favorite metadata', () {
  final created = DateTime(2026, 5, 29, 10);
  final voice = Voice.cloned(
    id: 'voice-1',
    name: '我的音色',
    referenceAudioPath: '/tmp/ref.wav',
    gender: '女声',
    tags: const <String>['用户创建', '女声'],
    createdAt: created,
  );

  final updated = voice.copyWith(
    favorite: true,
    lastUsedAt: DateTime(2026, 5, 29, 11),
  );

  expect(updated.id, 'voice-1');
  expect(updated.favorite, isTrue);
  expect(updated.lastUsedAt, DateTime(2026, 5, 29, 11));
  expect(updated.referenceAudioPath, '/tmp/ref.wav');
});

test('user voice json round trip keeps clone metadata', () {
  final created = DateTime(2026, 5, 29, 10);
  final voice = Voice.cloned(
    id: 'voice-1',
    name: '我的音色',
    referenceAudioPath: '/tmp/ref.wav',
    gender: '男声',
    tags: const <String>['用户创建', '男声'],
    createdAt: created,
  ).copyWith(favorite: true, lastUsedAt: DateTime(2026, 5, 29, 11));

  final restored = Voice.fromJson(voice.toJson());

  expect(restored.id, voice.id);
  expect(restored.type, VoiceType.cloned);
  expect(restored.favorite, isTrue);
  expect(restored.lastUsedAt, DateTime(2026, 5, 29, 11));
});
```

Add generated audio and draft tests:

```dart
test('generated audio json round trip keeps title and favorite', () {
  final audio = GeneratedAudio(
    id: 'audio-1',
    text: '欢迎使用',
    voiceId: 'mimo-default',
    voiceName: 'MiMo-默认',
    audioPath: '/tmp/audio.wav',
    durationMs: 3200,
    createdAt: DateTime(2026, 5, 29, 10),
    title: '欢迎词',
    favorite: true,
  );

  final restored = GeneratedAudio.fromJson(audio.toJson());

  expect(restored.title, '欢迎词');
  expect(restored.favorite, isTrue);
  expect(restored.createdAt, DateTime(2026, 5, 29, 10));
});

test('draft state stores current generation choices', () {
  const draft = DraftState(
    text: '稿件',
    stylePrompt: '温柔',
    speed: 1.2,
    emotion: '开心',
    selectedVoiceId: 'voice-1',
  );

  final restored = DraftState.fromJson(draft.toJson());

  expect(restored.text, '稿件');
  expect(restored.speed, 1.2);
  expect(restored.selectedVoiceId, 'voice-1');
});
```

- [ ] **Step 2: Run domain tests and verify they fail**

Run:

```bash
flutter test --no-pub test/domain/voice_test.dart test/domain/generated_audio_test.dart test/domain/draft_state_test.dart
```

Expected: fail because `copyWith`, JSON helpers, new fields, and `DraftState` do not exist yet.

- [ ] **Step 3: Implement domain APIs**

Add fields to `Voice`:

```dart
final bool favorite;
final DateTime? lastUsedAt;
```

Default them to `false` and `null` in the main constructor and factories. Add:

```dart
Voice copyWith({
  String? id,
  String? name,
  VoiceType? type,
  String? providerVoiceId,
  String? referenceAudioPath,
  String? previewAudioPath,
  String? stylePrompt,
  String? language,
  String? gender,
  List<String>? tags,
  DateTime? createdAt,
  DateTime? updatedAt,
  bool? favorite,
  DateTime? lastUsedAt,
}) {
  return Voice(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    providerVoiceId: providerVoiceId ?? this.providerVoiceId,
    referenceAudioPath: referenceAudioPath ?? this.referenceAudioPath,
    previewAudioPath: previewAudioPath ?? this.previewAudioPath,
    stylePrompt: stylePrompt ?? this.stylePrompt,
    language: language ?? this.language,
    gender: gender ?? this.gender,
    tags: tags ?? this.tags,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    favorite: favorite ?? this.favorite,
    lastUsedAt: lastUsedAt ?? this.lastUsedAt,
  );
}
```

Add `toJson()` and `fromJson()` using `VoiceType.name` and `DateTime.toIso8601String()`.

Add matching fields, `copyWith`, `toJson`, and `fromJson` to `GeneratedAudio`.

Create `DraftState`:

```dart
class DraftState {
  const DraftState({
    this.text = '',
    this.stylePrompt = '',
    this.speed = 1.0,
    this.emotion = '自然',
    this.selectedVoiceId,
  });

  final String text;
  final String stylePrompt;
  final double speed;
  final String emotion;
  final String? selectedVoiceId;

  Map<String, Object?> toJson() => <String, Object?>{
    'text': text,
    'stylePrompt': stylePrompt,
    'speed': speed,
    'emotion': emotion,
    'selectedVoiceId': selectedVoiceId,
  };

  factory DraftState.fromJson(Map<String, Object?> json) {
    return DraftState(
      text: json['text'] as String? ?? '',
      stylePrompt: json['stylePrompt'] as String? ?? '',
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      emotion: json['emotion'] as String? ?? '自然',
      selectedVoiceId: json['selectedVoiceId'] as String?,
    );
  }
}
```

Create `ConnectionTestResult`:

```dart
enum ConnectionTestStatus {
  success,
  missingApiKey,
  invalidUrl,
  networkError,
  httpError,
  invalidResponse,
}

class ConnectionTestResult {
  const ConnectionTestResult({
    required this.status,
    required this.message,
    this.statusCode,
  });

  final ConnectionTestStatus status;
  final String message;
  final int? statusCode;

  bool get isSuccess => status == ConnectionTestStatus.success;
}
```

- [ ] **Step 4: Run domain tests and verify they pass**

Run:

```bash
flutter test --no-pub test/domain/voice_test.dart test/domain/generated_audio_test.dart test/domain/draft_state_test.dart
```

Expected: all domain tests pass.

## Task 2: Local Persistence Services

**Files:**
- Create: `lib/src/services/local_json_store.dart`
- Modify: `lib/src/services/local_voice_store.dart`
- Create: `lib/src/services/local_history_store.dart`
- Create: `lib/src/services/local_draft_store.dart`
- Test: `test/services/local_voice_store_test.dart`
- Test: `test/services/local_history_store_test.dart`
- Test: `test/services/local_draft_store_test.dart`

- [ ] **Step 1: Write failing store tests**

Add an in-memory storage test path:

```dart
test('local voice store loads builtins and persisted user voices', () async {
  final jsonStore = MemoryJsonStore();
  final store = LocalVoiceStore(jsonStore: jsonStore);
  final created = DateTime(2026, 5, 29, 10);

  await store.saveUserVoices(<Voice>[
    Voice.cloned(
      id: 'custom-1',
      name: '我的音色',
      referenceAudioPath: '/tmp/ref.wav',
      createdAt: created,
    ),
  ]);

  final voices = await store.loadVoices();

  expect(voices.where((voice) => voice.type == VoiceType.builtin), hasLength(9));
  expect(voices.any((voice) => voice.id == 'custom-1'), isTrue);
});

test('local voice store persists favorite overlays for builtin voices', () async {
  final jsonStore = MemoryJsonStore();
  final store = LocalVoiceStore(jsonStore: jsonStore);

  await store.saveVoiceOverlay('mimo-default', favorite: true, lastUsedAt: DateTime(2026, 5, 29, 12));

  final voices = await store.loadVoices();
  final voice = voices.singleWhere((item) => item.id == 'mimo-default');

  expect(voice.favorite, isTrue);
  expect(voice.lastUsedAt, DateTime(2026, 5, 29, 12));
});
```

Add history and draft tests:

```dart
test('local history store persists generated audio list', () async {
  final store = LocalHistoryStore(jsonStore: MemoryJsonStore());
  final item = GeneratedAudio(
    id: 'audio-1',
    text: '文本',
    voiceId: 'voice-1',
    voiceName: '音色',
    audioPath: '/tmp/audio.wav',
    durationMs: 1200,
    createdAt: DateTime(2026, 5, 29, 10),
  );

  await store.saveHistory(<GeneratedAudio>[item]);

  final restored = await store.loadHistory();
  expect(restored.single.id, 'audio-1');
  expect(restored.single.text, '文本');
});

test('local draft store persists draft state', () async {
  final store = LocalDraftStore(jsonStore: MemoryJsonStore());
  const draft = DraftState(
    text: '脚本',
    stylePrompt: '亲切',
    speed: 1.1,
    emotion: '开心',
    selectedVoiceId: 'voice-1',
  );

  await store.save(draft);

  final restored = await store.load();
  expect(restored.text, '脚本');
  expect(restored.selectedVoiceId, 'voice-1');
});
```

- [ ] **Step 2: Run store tests and verify they fail**

Run:

```bash
flutter test --no-pub test/services/local_voice_store_test.dart test/services/local_history_store_test.dart test/services/local_draft_store_test.dart
```

Expected: fail because the store classes and async APIs are missing.

- [ ] **Step 3: Implement storage abstraction**

Create `LocalJsonStore` and `MemoryJsonStore`:

```dart
abstract class LocalJsonStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

class MemoryJsonStore implements LocalJsonStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
```

Add a `SharedPreferencesJsonStore` using `SharedPreferencesAsync`.

- [ ] **Step 4: Implement voice, history, and draft stores**

Use `jsonEncode` and `jsonDecode`. `LocalVoiceStore.loadVoices()` returns:

```dart
final builtins = builtinVoices();
final users = await loadUserVoices();
final overlays = await loadVoiceOverlays();
return <Voice>[
  for (final voice in builtins) _applyOverlay(voice, overlays[voice.id]),
  for (final voice in users) _applyOverlay(voice, overlays[voice.id]),
];
```

`LocalHistoryStore` persists `List<GeneratedAudio>` under key `mimo_generated_history`.

`LocalDraftStore` persists `DraftState` under key `mimo_generation_draft`.

- [ ] **Step 5: Run store tests and verify they pass**

Run:

```bash
flutter test --no-pub test/services/local_voice_store_test.dart test/services/local_history_store_test.dart test/services/local_draft_store_test.dart
```

Expected: all store tests pass.

## Task 3: AppState Persistence And Core Actions

**Files:**
- Modify: `lib/src/state/app_state.dart`
- Modify: `lib/main.dart`
- Test: `test/state/app_state_test.dart`

- [ ] **Step 1: Write failing AppState tests**

Add tests:

```dart
test('loads persisted voices history and draft data', () async {
  final jsonStore = MemoryJsonStore();
  final voiceStore = LocalVoiceStore(jsonStore: jsonStore);
  final historyStore = LocalHistoryStore(jsonStore: jsonStore);
  final draftStore = LocalDraftStore(jsonStore: jsonStore);

  await voiceStore.saveUserVoices(<Voice>[
    Voice.cloned(
      id: 'voice-custom',
      name: '我的音色',
      referenceAudioPath: '/tmp/ref.wav',
      createdAt: DateTime(2026, 5, 29, 10),
    ),
  ]);
  await historyStore.saveHistory(<GeneratedAudio>[
    GeneratedAudio(
      id: 'audio-1',
      text: '历史文本',
      voiceId: 'voice-custom',
      voiceName: '我的音色',
      audioPath: '/tmp/audio.wav',
      durationMs: 1000,
      createdAt: DateTime(2026, 5, 29, 11),
    ),
  ]);
  await draftStore.save(const DraftState(
    text: '草稿',
    stylePrompt: '温柔',
    speed: 1.2,
    emotion: '开心',
    selectedVoiceId: 'voice-custom',
  ));

  final state = AppState(
    mimoService: MockMimoService(),
    voiceStore: voiceStore,
    historyStore: historyStore,
    draftStore: draftStore,
  );
  await state.loadLocalData();

  expect(state.selectedVoice?.id, 'voice-custom');
  expect(state.draftText, '草稿');
  expect(state.history.single.id, 'audio-1');
});

test('generation persists history and marks selected voice as recently used', () async {
  final jsonStore = MemoryJsonStore();
  final voiceStore = LocalVoiceStore(jsonStore: jsonStore);
  final historyStore = LocalHistoryStore(jsonStore: jsonStore);
  final state = AppState(
    mimoService: MockMimoService(),
    voiceStore: voiceStore,
    historyStore: historyStore,
    draftStore: LocalDraftStore(jsonStore: jsonStore),
  );

  state.updateDraftText('要生成的文本');
  final audio = await state.generateCurrentVoice();

  final persisted = await historyStore.loadHistory();
  final reloadedVoices = await voiceStore.loadVoices();

  expect(persisted.single.id, audio.id);
  expect(reloadedVoices.first.lastUsedAt, isNotNull);
});
```

- [ ] **Step 2: Run AppState tests and verify they fail**

Run:

```bash
flutter test --no-pub test/state/app_state_test.dart
```

Expected: fail because `historyStore`, `draftStore`, `loadLocalData`, and recent-use persistence do not exist.

- [ ] **Step 3: Implement AppState persistence APIs**

Add optional stores to the constructor:

```dart
LocalHistoryStore? historyStore,
LocalDraftStore? draftStore,
```

Add:

```dart
Future<void> loadLocalData() async {
  _voices = await _voiceStore.loadVoices();
  _history
    ..clear()
    ..addAll(await _historyStore.loadHistory());
  final draft = await _draftStore.load();
  _draftText = draft.text;
  _stylePrompt = draft.stylePrompt;
  _speed = draft.speed;
  _emotion = draft.emotion;
  _selectedVoiceId = _resolveSelectedVoiceId(draft.selectedVoiceId);
  notifyListeners();
}
```

Persist draft from `updateDraftText`, `updateStylePrompt`, `updateSpeed`, `updateEmotion`, and `selectVoice`.

Add actions:

```dart
void toggleVoiceFavorite(String voiceId);
void toggleHistoryFavorite(String audioId);
void renameHistoryItem(String audioId, String title);
void useHistoryText(String audioId);
void clearHistory();
```

After `generateCurrentVoice()` inserts history, call `saveHistory(_history)` and update selected voice `lastUsedAt`.

- [ ] **Step 4: Update main app bootstrap**

In `main.dart`, create shared `SharedPreferencesJsonStore`, pass stores into `AppState`, and call:

```dart
final jsonStore = SharedPreferencesJsonStore();
final configStore = LocalServiceConfigStore();
final serviceConfig = await configStore.load();
final appState = AppState(
  mimoService: MimoApiService(),
  serviceConfig: serviceConfig,
  serviceConfigStore: configStore,
  voiceStore: LocalVoiceStore(jsonStore: jsonStore),
  historyStore: LocalHistoryStore(jsonStore: jsonStore),
  draftStore: LocalDraftStore(jsonStore: jsonStore),
);
await appState.loadLocalData();
runApp(VoiceCloneApp(appState: appState));
```

- [ ] **Step 5: Run AppState tests and verify they pass**

Run:

```bash
flutter test --no-pub test/state/app_state_test.dart
```

Expected: all AppState tests pass.

## Task 4: Text Segmentation And Generate Flow

**Files:**
- Create: `lib/src/services/text_segmenter.dart`
- Modify: `lib/src/state/app_state.dart`
- Modify: `lib/src/app/app_shell.dart`
- Modify: `lib/src/ui/generate/generate_screen.dart`
- Test: `test/services/text_segmenter_test.dart`
- Test: `test/ui/generate_screen_test.dart`

- [ ] **Step 1: Write failing tests**

Add `TextSegmenter` tests:

```dart
test('keeps short text as a single segment', () {
  final segments = TextSegmenter(maxChars: 20).segment('第一段文本');
  expect(segments, <String>['第一段文本']);
});

test('splits long text by paragraphs before character length', () {
  final text = '第一段内容\n\n第二段内容很长，需要生成';
  final segments = TextSegmenter(maxChars: 8).segment(text);
  expect(segments, <String>['第一段内容', '第二段内容很长', '需要生成']);
});
```

Update generate UI tests:

```dart
testWidgets('missing api key offers settings guidance', (tester) async {
  var openedSettings = false;
  final state = AppState(mimoService: MockMimoService());
  state.updateDraftText('测试文本');

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: GenerateScreen(
        appState: state,
        onOpenSettings: () => openedSettings = true,
      ),
    ),
  ));

  await tester.tap(find.text('生成语音'));
  await tester.pump();

  expect(find.textContaining('请先填写 MiMo API Key'), findsOneWidget);
  expect(openedSettings, isFalse);
  await tester.tap(find.text('去设置'));
  expect(openedSettings, isTrue);
});

testWidgets('long text shows segment controls', (tester) async {
  final state = AppState(mimoService: MockMimoService());
  state.updateServiceConfig(const ServiceConfig.directApi(apiKey: 'test-key'));
  state.updateDraftText('第一段内容\n\n第二段内容'.padRight(260, '长'));

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: GenerateScreen(appState: state)),
  ));
  await tester.pumpAndSettle();

  expect(find.textContaining('已分为'), findsOneWidget);
  expect(find.text('生成全部'), findsOneWidget);
});
```

- [ ] **Step 2: Run tests and verify they fail**

Run:

```bash
flutter test --no-pub test/services/text_segmenter_test.dart test/ui/generate_screen_test.dart
```

Expected: fail because segmentation, settings guidance, and long-text UI are missing.

- [ ] **Step 3: Implement TextSegmenter**

Create:

```dart
class TextSegmenter {
  const TextSegmenter({this.maxChars = 500});

  final int maxChars;

  List<String> segment(String input) {
    final normalized = input.trim();
    if (normalized.isEmpty) return const <String>[];
    final paragraphs = normalized
        .split(RegExp(r'\n\s*\n|\r\n\s*\r\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty);
    final result = <String>[];
    for (final paragraph in paragraphs) {
      if (paragraph.length <= maxChars) {
        result.add(paragraph);
      } else {
        for (var start = 0; start < paragraph.length; start += maxChars) {
          result.add(paragraph.substring(start, (start + maxChars).clamp(0, paragraph.length)));
        }
      }
    }
    return result;
  }
}
```

- [ ] **Step 4: Implement generate page UX**

Add optional callback:

```dart
final VoidCallback? onOpenSettings;
```

When API Key is missing, show an `AppPanel` or `SnackBar` with message `请先填写 MiMo API Key` and action `去设置`.

Add local state:

```dart
GenerationPhase _phase = GenerationPhase.idle;
List<String> _segments = const <String>[];
int _activeSegment = 0;
```

Render document stats:

```dart
final charCount = _textController.text.characters.length;
final estimatedSeconds = (charCount / 4).ceil();
```

Show `已分为 N 段` and buttons `生成当前段` and `生成全部` when `TextSegmenter().segment(text).length > 1`.

Add `AppState.generateText(String text)` so segmented generation can generate each segment without mutating the full draft.

- [ ] **Step 5: Run generate tests and verify they pass**

Run:

```bash
flutter test --no-pub test/services/text_segmenter_test.dart test/ui/generate_screen_test.dart
```

Expected: all generate-flow tests pass.

## Task 5: Recording Clone Experience

**Files:**
- Modify: `lib/src/services/audio_validator.dart`
- Modify: `lib/src/services/audio_input_service.dart`
- Modify: `lib/src/ui/voices/voice_creation_sheet.dart`
- Test: `test/services/audio_validator_test.dart`
- Test: `test/ui/voice_creation_sheet_test.dart`
- Update: `test/ui/voice_library_screen_test.dart`

- [ ] **Step 1: Write failing recording and validation tests**

Add validator tests:

```dart
test('validates existing reference audio file and size', () async {
  final directory = await Directory.systemTemp.createTemp('mimo-audio-test');
  final file = File('${directory.path}/reference.wav');
  await file.writeAsBytes(List<int>.filled(32, 1));

  final result = await AudioValidator.validateReferenceFile(file.path);

  expect(result.isValid, isTrue);
  expect(result.message, contains('可用'));
});

test('rejects missing reference audio file', () async {
  final result = await AudioValidator.validateReferenceFile('/missing/reference.wav');
  expect(result.isValid, isFalse);
  expect(result.message, contains('文件不存在'));
});
```

Add widget test for the sheet:

```dart
testWidgets('clone sheet requires name and reference audio before saving', (tester) async {
  final state = AppState(mimoService: MockMimoService());
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => FilledButton(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (_) => VoiceCreationSheet(appState: state),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ));

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('克隆音色'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('生成并保存'));
  await tester.pump();

  expect(find.textContaining('请输入音色名称'), findsOneWidget);
});
```

- [ ] **Step 2: Run recording tests and verify they fail**

Run:

```bash
flutter test --no-pub test/services/audio_validator_test.dart test/ui/voice_creation_sheet_test.dart test/ui/voice_library_screen_test.dart
```

Expected: fail because `validateReferenceFile`, required-field UI, and dedicated sheet tests are missing.

- [ ] **Step 3: Implement audio validation result**

Add:

```dart
class AudioValidationResult {
  const AudioValidationResult.valid(this.path) : isValid = true, message = '音频可用';
  const AudioValidationResult.invalid(this.message) : isValid = false, path = null;

  final bool isValid;
  final String message;
  final String? path;
}
```

Add `AudioValidator.validateReferenceFile(String path)`:

- Return invalid `文件不存在` if `File(path).exists()` is false.
- Return invalid `仅支持 mp3 或 wav` for unsupported formats.
- Return invalid `参考音频超过 MiMo 10 MB Base64 限制` if estimated Base64 length is over `10 * 1024 * 1024`.
- Return valid for supported files under the limit.

- [ ] **Step 4: Update VoiceCreationSheet**

Add state fields:

```dart
Duration _recordingDuration = Duration.zero;
Timer? _recordingTimer;
String? _validationMessage;
bool _referenceValid = false;
```

Show:

- `录音中 00:12` while recording.
- `试听参考音频` and `重新录制` after a path is available.
- Validation message below the reference path field.
- Required field messages for missing name and missing reference audio.

Use `AudioPlaybackService.instance.playFile(_pathController.text)` for preview.

- [ ] **Step 5: Run recording tests and verify they pass**

Run:

```bash
flutter test --no-pub test/services/audio_validator_test.dart test/ui/voice_creation_sheet_test.dart test/ui/voice_library_screen_test.dart
```

Expected: all recording and existing voice-library tests pass.

## Task 6: Voice Library Search, Filters, Favorites

**Files:**
- Modify: `lib/src/state/app_state.dart`
- Modify: `lib/src/app/app_shell.dart`
- Modify: `lib/src/ui/voices/voice_library_screen.dart`
- Modify: `lib/src/ui/widgets/voice_card.dart`
- Test: `test/ui/voice_library_screen_test.dart`
- Test: `test/state/app_state_test.dart`

- [ ] **Step 1: Write failing tests**

Add tests:

```dart
testWidgets('voice library filters by search and gender chips', (tester) async {
  final state = AppState(mimoService: MockMimoService());
  await tester.pumpWidget(MaterialApp(home: VoiceLibraryScreen(appState: state)));

  await tester.enterText(find.byKey(const Key('voiceSearchField')), '冰糖');
  await tester.pumpAndSettle();

  expect(find.text('冰糖'), findsOneWidget);
  expect(find.text('茉莉'), findsNothing);

  await tester.enterText(find.byKey(const Key('voiceSearchField')), '');
  await tester.tap(find.text('男声'));
  await tester.pumpAndSettle();

  expect(find.text('苏打'), findsOneWidget);
});

testWidgets('voice library can favorite a voice', (tester) async {
  final state = AppState(mimoService: MockMimoService());
  await tester.pumpWidget(MaterialApp(home: VoiceLibraryScreen(appState: state)));

  await tester.tap(find.byTooltip('收藏').first);
  await tester.pumpAndSettle();

  expect(state.voices.any((voice) => voice.favorite), isTrue);
});
```

- [ ] **Step 2: Run voice library tests and verify they fail**

Run:

```bash
flutter test --no-pub test/ui/voice_library_screen_test.dart test/state/app_state_test.dart
```

Expected: fail because search field, filter chips, and favorite actions are missing.

- [ ] **Step 3: Implement AppState voice actions**

Implement:

```dart
void toggleVoiceFavorite(String voiceId) {
  _voices = _voices.map((voice) {
    if (voice.id != voiceId) return voice;
    final updated = voice.copyWith(favorite: !voice.favorite);
    unawaited(_voiceStore.saveVoiceOverlay(
      updated.id,
      favorite: updated.favorite,
      lastUsedAt: updated.lastUsedAt,
    ));
    return updated;
  }).toList();
  notifyListeners();
}
```

Update `selectVoice()` to set `lastUsedAt: DateTime.now()` and persist the overlay.

- [ ] **Step 4: Redesign VoiceLibraryScreen list controls**

Replace tabs with:

- Search `TextField` with key `voiceSearchField`.
- Filter chips: `全部`, `官方`, `AI 音色`, `男声`, `女声`, `中文`, `英文`, `收藏`.
- Section header showing visible count.
- `VoiceCard` favorite button with tooltip `收藏` or `取消收藏`.

Filtering rules:

- Search matches lowercase name and tags.
- `官方` means `VoiceType.builtin`.
- `AI 音色` means cloned or designed.
- `收藏` means `voice.favorite`.

- [ ] **Step 5: Run voice library tests and verify they pass**

Run:

```bash
flutter test --no-pub test/ui/voice_library_screen_test.dart test/state/app_state_test.dart
```

Expected: voice library and state tests pass.

## Task 7: History Asset Library

**Files:**
- Modify: `lib/src/state/app_state.dart`
- Modify: `lib/src/app/app_shell.dart`
- Modify: `lib/src/ui/history/history_screen.dart`
- Test: `test/ui/history_screen_test.dart`
- Test: `test/state/app_state_test.dart`

- [ ] **Step 1: Write failing history tests**

Add tests:

```dart
testWidgets('history supports rename favorite and copy text', (tester) async {
  final state = AppState(mimoService: MockMimoService());
  state.updateDraftText('历史操作测试文本');
  await state.generateCurrentVoice();

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: HistoryScreen(appState: state)),
  ));

  await tester.tap(find.byTooltip('收藏'));
  await tester.pump();
  expect(state.history.single.favorite, isTrue);

  await tester.tap(find.byTooltip('更多'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('重命名'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('historyRenameField')), '新标题');
  await tester.tap(find.text('保存'));
  await tester.pumpAndSettle();

  expect(find.text('新标题'), findsOneWidget);
});

testWidgets('history can reuse text in generate page through callback', (tester) async {
  final state = AppState(mimoService: MockMimoService());
  state.updateDraftText('复用文本');
  await state.generateCurrentVoice();
  String? reused;

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: HistoryScreen(
        appState: state,
        onReuseText: (text) => reused = text,
      ),
    ),
  ));

  await tester.tap(find.byTooltip('更多'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('用这段文本重新生成'));

  expect(reused, '复用文本');
});
```

- [ ] **Step 2: Run history tests and verify they fail**

Run:

```bash
flutter test --no-pub test/ui/history_screen_test.dart test/state/app_state_test.dart
```

Expected: fail because favorite, rename, more menu, and reuse callback are missing.

- [ ] **Step 3: Implement state actions**

Implement:

```dart
void toggleHistoryFavorite(String id) {
  _updateHistoryItem(id, (audio) => audio.copyWith(favorite: !audio.favorite));
  unawaited(_historyStore.saveHistory(_history));
  notifyListeners();
}

void renameHistoryItem(String id, String title) {
  _updateHistoryItem(id, (audio) => audio.copyWith(title: title.trim()));
  unawaited(_historyStore.saveHistory(_history));
  notifyListeners();
}
```

Use a private helper instead of adding an extension globally:

```dart
void _updateHistoryItem(String id, GeneratedAudio Function(GeneratedAudio) update) {
  _history = _history.map((item) => item.id == id ? update(item) : item).toList();
}
```

If `_history` is currently final, change it to mutable `List<GeneratedAudio> _history = <GeneratedAudio>[];`.

- [ ] **Step 4: Implement HistoryScreen UI**

Add:

- Search field and filter chips: `全部`, `收藏`, `今天`.
- Favorite icon button with tooltip `收藏`/`取消收藏`.
- Popup menu with `重命名`, `复制文本`, `用这段文本重新生成`, `删除`.
- Rename dialog with `TextField` key `historyRenameField`.
- Delete confirmation dialog.
- Empty filtered state text `没有匹配的历史记录`.

Use `Clipboard.setData(ClipboardData(text: item.text))` for copy.

- [ ] **Step 5: Run history tests and verify they pass**

Run:

```bash
flutter test --no-pub test/ui/history_screen_test.dart test/state/app_state_test.dart
```

Expected: all history and state tests pass.

## Task 8: Settings Connection Test

**Files:**
- Modify: `lib/src/services/mimo_client.dart`
- Modify: `lib/src/services/mock_mimo_service.dart`
- Modify: `lib/src/ui/settings/settings_screen.dart`
- Test: `test/services/mimo_client_test.dart`
- Test: `test/ui/settings_screen_test.dart`

- [ ] **Step 1: Write failing tests**

Add service tests:

```dart
test('connection test reports missing api key', () async {
  final service = MimoApiService(client: FakeHttpClient());
  final result = await service.testConnection(config: const ServiceConfig.directApi());

  expect(result.status, ConnectionTestStatus.missingApiKey);
});
```

Add UI tests:

```dart
testWidgets('settings can reveal api key and test connection', (tester) async {
  final state = AppState(
    mimoService: MockMimoService(),
    serviceConfig: const ServiceConfig.directApi(apiKey: 'saved-key'),
  );

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: SettingsScreen(appState: state)),
  ));

  expect(find.text('saved-key'), findsNothing);
  await tester.tap(find.byTooltip('显示 API Key'));
  await tester.pump();
  expect(find.text('saved-key'), findsOneWidget);

  await tester.tap(find.text('测试连接'));
  await tester.pumpAndSettle();
  expect(find.textContaining('连接成功'), findsOneWidget);
});
```

- [ ] **Step 2: Run settings tests and verify they fail**

Run:

```bash
flutter test --no-pub test/services/mimo_client_test.dart test/ui/settings_screen_test.dart
```

Expected: fail because connection test and reveal UI are missing.

- [ ] **Step 3: Implement MimoService connection test**

Add method to abstract class:

```dart
Future<ConnectionTestResult> testConnection({required ServiceConfig config});
```

In `MimoApiService`, return:

- `missingApiKey` if direct mode and key empty.
- `invalidUrl` if `Uri.tryParse(config.resolvedApiUrl)` is null or has no scheme.
- `success` after `_postForAudio()` succeeds with a short built-in voice request.
- `httpError` for non-2xx `StateError` containing status code.
- `invalidResponse` for JSON/response parsing errors.
- `networkError` for `SocketException` and other HTTP client transport errors.

In `MockMimoService`, return success unless config has no key and the test needs missing-key behavior.

- [ ] **Step 4: Implement SettingsScreen UI**

Add local state:

```dart
bool _showApiKey = false;
bool _testing = false;
ConnectionTestResult? _testResult;
```

API Key `TextField` uses suffix icon:

```dart
IconButton(
  tooltip: _showApiKey ? '隐藏 API Key' : '显示 API Key',
  onPressed: () => setState(() => _showApiKey = !_showApiKey),
  icon: Icon(_showApiKey ? Symbols.visibility_off_rounded : Symbols.visibility_rounded),
)
```

Add `OutlinedButton.icon` with text `测试连接`. Render result panel using `ConnectionTestResult.message`.

- [ ] **Step 5: Run settings tests and verify they pass**

Run:

```bash
flutter test --no-pub test/services/mimo_client_test.dart test/ui/settings_screen_test.dart
```

Expected: settings and service tests pass.

## Task 9: Full Verification And Android Check

**Files:**
- No new files.

- [ ] **Step 1: Run analyzer**

Run:

```bash
flutter analyze --no-pub
```

Expected: exit code 0.

- [ ] **Step 2: Run all tests**

Run:

```bash
flutter test --no-pub
```

Expected: exit code 0.

- [ ] **Step 3: Build debug APK**

Run:

```bash
flutter build apk --debug --no-pub
```

Expected: exit code 0 and APK at `build/app/outputs/flutter-apk/app-debug.apk`.

- [ ] **Step 4: Launch on emulator if available**

Run:

```bash
flutter devices
```

If an Android emulator is listed, run:

```bash
flutter install --debug
flutter run --debug --no-pub
```

Expected: app launches and the four tabs render without startup exceptions.

## Plan Self-Review Checklist

- Spec coverage: all 7 approved feature areas map to Tasks 1-8.
- Data safety: persistence stores are introduced before UI actions depend on them.
- TDD order: every behavior task starts with failing tests and a red command.
- Verification: analyzer, all tests, APK build, and emulator launch are included.
- Scope: no login, cloud sync, payments, audio editing, or technology migration.
