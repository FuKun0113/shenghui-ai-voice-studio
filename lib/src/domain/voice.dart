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
    this.language,
    this.gender,
    this.tags = const <String>[],
    this.createdAt,
    this.updatedAt,
    this.favorite = false,
    this.lastUsedAt,
  });

  factory Voice.builtin({
    required String id,
    required String name,
    required String providerVoiceId,
    String? previewAudioPath,
    String? language,
    String? gender,
    List<String> tags = const <String>[],
  }) {
    return Voice(
      id: id,
      name: name,
      type: VoiceType.builtin,
      providerVoiceId: providerVoiceId,
      previewAudioPath: previewAudioPath,
      language: language,
      gender: gender,
      tags: tags,
    );
  }

  factory Voice.cloned({
    required String id,
    required String name,
    required String referenceAudioPath,
    required DateTime createdAt,
    String? previewAudioPath,
    String? gender,
    List<String> tags = const <String>[],
  }) {
    return Voice(
      id: id,
      name: name,
      type: VoiceType.cloned,
      referenceAudioPath: referenceAudioPath,
      previewAudioPath: previewAudioPath ?? referenceAudioPath,
      gender: gender,
      tags: tags,
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
    String? gender,
    List<String> tags = const <String>[],
  }) {
    return Voice(
      id: id,
      name: name,
      type: VoiceType.designed,
      stylePrompt: stylePrompt,
      referenceAudioPath: referenceAudioPath,
      previewAudioPath: previewAudioPath,
      gender: gender,
      tags: tags,
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
  final String? language;
  final String? gender;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool favorite;
  final DateTime? lastUsedAt;

  bool get isUserCreated =>
      type == VoiceType.cloned || type == VoiceType.designed;

  bool get requiresReferenceAudio =>
      type == VoiceType.cloned || type == VoiceType.designed;

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

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'type': type.name,
      'providerVoiceId': providerVoiceId,
      'referenceAudioPath': referenceAudioPath,
      'previewAudioPath': previewAudioPath,
      'stylePrompt': stylePrompt,
      'language': language,
      'gender': gender,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'favorite': favorite,
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  factory Voice.fromJson(Map<String, Object?> json) {
    return Voice(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: VoiceType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => VoiceType.builtin,
      ),
      providerVoiceId: json['providerVoiceId'] as String?,
      referenceAudioPath: json['referenceAudioPath'] as String?,
      previewAudioPath: json['previewAudioPath'] as String?,
      stylePrompt: json['stylePrompt'] as String?,
      language: json['language'] as String?,
      gender: json['gender'] as String?,
      tags: (json['tags'] as List? ?? const <Object?>[])
          .whereType<String>()
          .toList(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      favorite: json['favorite'] as bool? ?? false,
      lastUsedAt: _parseDate(json['lastUsedAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
