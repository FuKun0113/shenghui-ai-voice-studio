class GeneratedAudio {
  const GeneratedAudio({
    required this.id,
    required this.text,
    required this.voiceId,
    required this.voiceName,
    required this.audioPath,
    required this.durationMs,
    required this.createdAt,
    this.title,
    this.stylePrompt,
    this.favorite = false,
  });

  final String id;
  final String text;
  final String voiceId;
  final String voiceName;
  final String audioPath;
  final int durationMs;
  final DateTime createdAt;
  final String? title;
  final String? stylePrompt;
  final bool favorite;

  String get displayTitle {
    final value = title?.trim();
    if (value != null && value.isNotEmpty) return value;
    return text;
  }

  GeneratedAudio copyWith({
    String? id,
    String? text,
    String? voiceId,
    String? voiceName,
    String? audioPath,
    int? durationMs,
    DateTime? createdAt,
    String? title,
    String? stylePrompt,
    bool? favorite,
  }) {
    return GeneratedAudio(
      id: id ?? this.id,
      text: text ?? this.text,
      voiceId: voiceId ?? this.voiceId,
      voiceName: voiceName ?? this.voiceName,
      audioPath: audioPath ?? this.audioPath,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      stylePrompt: stylePrompt ?? this.stylePrompt,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'text': text,
      'voiceId': voiceId,
      'voiceName': voiceName,
      'audioPath': audioPath,
      'durationMs': durationMs,
      'createdAt': createdAt.toIso8601String(),
      'title': title,
      'stylePrompt': stylePrompt,
      'favorite': favorite,
    };
  }

  factory GeneratedAudio.fromJson(Map<String, Object?> json) {
    return GeneratedAudio(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      voiceId: json['voiceId'] as String? ?? '',
      voiceName: json['voiceName'] as String? ?? '',
      audioPath: json['audioPath'] as String? ?? '',
      durationMs: (json['durationMs'] as num?)?.round() ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      title: json['title'] as String?,
      stylePrompt: json['stylePrompt'] as String?,
      favorite: json['favorite'] as bool? ?? false,
    );
  }
}
