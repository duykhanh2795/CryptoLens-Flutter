enum AiMessageRole { user, assistant }

class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final int id;
  final AiMessageRole role;
  final String text;
  final DateTime createdAt;

  bool get isUser => role == AiMessageRole.user;
}
