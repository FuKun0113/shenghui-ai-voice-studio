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

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'text': text,
      'stylePrompt': stylePrompt,
      'speed': speed,
      'emotion': emotion,
      'selectedVoiceId': selectedVoiceId,
    };
  }

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
