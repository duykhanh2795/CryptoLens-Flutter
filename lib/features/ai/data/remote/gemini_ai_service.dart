import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:cryptolens_flutter/core/config/app_config.dart';
import 'package:cryptolens_flutter/core/errors/app_exception.dart';
import 'package:cryptolens_flutter/core/network/api_client.dart';
import 'package:cryptolens_flutter/features/ai/domain/ai_chat_message.dart';
import 'package:cryptolens_flutter/features/market/domain/coin.dart';

class GeminiAiService {
  GeminiAiService({http.Client? client}) : _client = ApiClient(client: client);

  static final _generateContentUri = Uri.https(
    'generativelanguage.googleapis.com',
    '/v1beta/models/gemini-2.5-flash:generateContent',
  );

  final ApiClient _client;

  Future<String> sendChatMessage({
    required String message,
    required List<Coin> marketContext,
    required List<AiChatMessage> recentMessages,
  }) async {
    if (AppConfig.geminiApiKey.trim().isEmpty) {
      throw const AiServiceException(
        'Add GEMINI_API_KEY with --dart-define to enable AI chat.',
      );
    }

    final response = await _client.postJson(
      _generateContentUri,
      label: 'Gemini chat',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': AppConfig.geminiApiKey,
      },
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text': _buildChatPrompt(
                  message,
                  marketContext,
                  recentMessages,
                ),
              },
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.45,
          'maxOutputTokens': 1200,
          'responseMimeType': 'text/plain',
        },
      }),
      timeout: const Duration(seconds: 35),
    );

    final text = _parseTextResponse(response.data);
    if (text.trim().isEmpty) {
      return 'Mình chưa có đủ dữ liệu để trả lời câu này.';
    }
    return text.trim();
  }

  void dispose() => _client.close();

  String _buildChatPrompt(
    String message,
    List<Coin> marketContext,
    List<AiChatMessage> recentMessages,
  ) {
    final marketLines = marketContext
        .take(12)
        .map((coin) {
          return '- ${coin.symbol}: price=\$${coin.currentPrice}, '
              '24h=${coin.priceChangePercent24h.toStringAsFixed(2)}%, '
              'volume=\$${coin.volume24h}, marketCap=\$${coin.marketCap}';
        })
        .join('\n');
    final history = recentMessages
        .take(8)
        .map((chat) {
          final role = chat.role == AiMessageRole.user ? 'User' : 'Assistant';
          return '$role: ${chat.text}';
        })
        .join('\n');

    return '''
You are CryptoLens AI, a crypto dashboard assistant.
Answer in Vietnamese unless the user explicitly asks for another language.
Be concise, practical, and transparent about uncertainty.
Do not pretend to place trades or access private wallets.
If the question asks for investment advice, frame the answer as informational only.

Current market context:
$marketLines

Recent conversation:
$history

User question:
$message
'''
        .trim();
  }

  String _parseTextResponse(Object? decoded) {
    if (decoded is! Map<String, Object?>) return '';
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return '';
    final first = candidates.first;
    if (first is! Map<String, Object?>) return '';
    final content = first['content'];
    if (content is! Map<String, Object?>) return '';
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return '';
    final firstPart = parts.first;
    if (firstPart is! Map<String, Object?>) return '';
    return firstPart['text']?.toString() ?? '';
  }
}

class AiServiceException extends AppException {
  const AiServiceException(super.message);
}
