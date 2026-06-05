import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/features/ai/data/remote/gemini_ai_service.dart';
import 'package:cryptolens_flutter/features/ai/presentation/viewmodels/ai_assistant_view_model.dart';
import 'package:cryptolens_flutter/features/ai/presentation/widgets/ai_assistant_widgets.dart';
import 'package:cryptolens_flutter/features/market/presentation/market_controller.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({required this.controller, super.key});

  final MarketController controller;

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  late final AiAssistantViewModel _viewModel;
  final _scrollController = ScrollController();
  bool _drawerOpen = false;

  @override
  void initState() {
    super.initState();
    _viewModel = AiAssistantViewModel(
      service: GeminiAiService(),
      marketContext: widget.controller.coins,
    )..addListener(_scrollToBottomSoon);
  }

  @override
  void dispose() {
    _viewModel
      ..removeListener(_scrollToBottomSoon)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF17161B),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return Stack(
              children: [
                Column(
                  children: [
                    AiChatTopBar(
                      onMenu: () => setState(() => _drawerOpen = true),
                      onClose: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: _viewModel.messages.isEmpty
                          ? PromptStartContent(
                              onPrompt: (prompt) =>
                                  _viewModel.sendPrompt(prompt),
                            )
                          : ChatMessagesList(
                              messages: _viewModel.messages,
                              isSending: _viewModel.isSending,
                              scrollController: _scrollController,
                            ),
                    ),
                    if (_viewModel.error != null)
                      AiInlineError(
                        message: _viewModel.error!,
                        onDismiss: _viewModel.dismissError,
                      ),
                    ChatComposer(
                      value: _viewModel.input,
                      isSending: _viewModel.isSending,
                      onChanged: _viewModel.updateInput,
                      onSend: _viewModel.sendCurrentInput,
                    ),
                  ],
                ),
                if (_drawerOpen)
                  AiSidePanel(
                    onClose: () => setState(() => _drawerOpen = false),
                    onNewChat: () {
                      _viewModel.newChat();
                      setState(() => _drawerOpen = false);
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class FloatingAiButton extends StatelessWidget {
  const FloatingAiButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 92,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE8ECEF),
                  Color(0xFF7C6FE8),
                  Color(0xFF9EA4AD),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.38),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.66),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
