import 'package:flutter/foundation.dart';

import 'package:cryptolens_flutter/features/ai/data/remote/gemini_ai_service.dart';
import 'package:cryptolens_flutter/features/ai/domain/ai_chat_message.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';

class AiAssistantViewModel extends ChangeNotifier {
  AiAssistantViewModel({
    required GeminiAiService service,
    required List<Coin> marketContext,
  }) : this._(service, marketContext);

  AiAssistantViewModel._(this._service, this._marketContext);

  final GeminiAiService _service;
  final List<Coin> _marketContext;

  final List<AiChatMessage> messages = [];
  String input = '';
  String? error;
  bool isSending = false;
  int _nextMessageId = 1;

  List<Coin> get marketContext => _marketContext;

  void updateInput(String value) {
    input = value;
    notifyListeners();
  }

  void dismissError() {
    error = null;
    notifyListeners();
  }

  void newChat() {
    messages.clear();
    input = '';
    error = null;
    isSending = false;
    notifyListeners();
  }

  Future<void> sendCurrentInput() => sendMessage(input);

  Future<void> sendPrompt(String prompt) => sendMessage(prompt);

  Future<void> sendMessage(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || isSending) return;

    final userMessage = AiChatMessage(
      id: _nextMessageId++,
      role: AiMessageRole.user,
      text: message,
      createdAt: DateTime.now(),
    );
    final recentMessages = messages.takeLast(8);
    messages.add(userMessage);
    input = '';
    error = null;
    isSending = true;
    notifyListeners();

    try {
      final response = await _service.sendChatMessage(
        message: message,
        marketContext: _marketContext,
        recentMessages: recentMessages,
      );
      messages.add(
        AiChatMessage(
          id: _nextMessageId++,
          role: AiMessageRole.assistant,
          text: response,
          createdAt: DateTime.now(),
        ),
      );
    } catch (exception) {
      error = exception.toString();
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

extension _AiChatMessageList on List<AiChatMessage> {
  List<AiChatMessage> takeLast(int count) {
    if (length <= count) return List<AiChatMessage>.of(this);
    return sublist(length - count);
  }
}
