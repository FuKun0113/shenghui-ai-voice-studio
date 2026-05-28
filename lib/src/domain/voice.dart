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

  bool get isUserCreated =>
      type == VoiceType.cloned || type == VoiceType.designed;

  bool get requiresReferenceAudio =>
      type == VoiceType.cloned || type == VoiceType.designed;
}
