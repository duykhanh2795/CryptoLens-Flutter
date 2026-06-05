import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/core/theme/app_theme.dart';
import 'package:cryptolens_flutter/core/widgets/app_state_views.dart';
import 'package:cryptolens_flutter/features/ai/domain/ai_chat_message.dart';

class StarterPrompt {
  const StarterPrompt({required this.label, required this.text});

  final String label;
  final String text;
}

const starterPrompts = [
  StarterPrompt(
    label: 'Fast',
    text: 'Tin tức pháp lý crypto mới nhất đang ảnh hưởng gì tới thị trường?',
  ),
  StarterPrompt(
    label: 'Fast',
    text:
        'Vì sao Hyperliquid đang được nhắc nhiều trong cộng đồng crypto gần đây?',
  ),
  StarterPrompt(
    label: 'Deep Research',
    text: 'Những altcoin như SUI, NEAR hoặc LINK đang có setup nào đáng chú ý?',
  ),
  StarterPrompt(
    label: 'Backtest',
    text:
        'So sánh portfolio top 5 crypto equal-weight và market-cap-weight trong 2 năm.',
  ),
];

class AiChatTopBar extends StatelessWidget {
  const AiChatTopBar({required this.onMenu, required this.onClose, super.key});

  final VoidCallback onMenu;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded, size: 31),
            color: AppColors.textPrimary,
          ),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 34),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

class PromptStartContent extends StatelessWidget {
  const PromptStartContent({required this.onPrompt, super.key});

  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Text(
            'Select Prompt to Start',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.08,
            ),
          ),
        ),
        for (final prompt in starterPrompts) ...[
          PromptCard(prompt: prompt, onTap: () => onPrompt(prompt.text)),
          const SizedBox(height: 18),
        ],
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Discover more prompts in prompt library.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class PromptCard extends StatelessWidget {
  const PromptCard({required this.prompt, required this.onTap, super.key});

  final StarterPrompt prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF202024),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PromptBadge(label: prompt.label),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                prompt.text,
                style: const TextStyle(
                  color: Color(0xFFD7D4DD),
                  fontSize: 16,
                  height: 1.32,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PromptBadge extends StatelessWidget {
  const PromptBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2930),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Fast' ? Icons.bolt_rounded : Icons.auto_awesome_rounded,
            color: AppColors.textSecondary,
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessagesList extends StatelessWidget {
  const ChatMessagesList({
    required this.messages,
    required this.isSending,
    required this.scrollController,
    super.key,
  });

  final List<AiChatMessage> messages;
  final bool isSending;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      children: [
        for (final message in messages) ...[
          ChatMessageBubble(message: message),
          const SizedBox(height: 14),
        ],
        if (isSending)
          const Align(alignment: Alignment.centerLeft, child: ThinkingBubble()),
      ],
    );
  }
}

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({required this.message, super.key});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.86,
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.accent.withValues(alpha: 0.18)
                : const Color(0xFF202024),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class ThinkingBubble extends StatelessWidget {
  const ThinkingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppInlineLoader(
            dimension: 16,
            strokeWidth: 2,
            color: AppColors.accent,
          ),
          SizedBox(width: 8),
          Text(
            'Thinking',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    required this.value,
    required this.isSending,
    required this.onChanged,
    required this.onSend,
    super.key,
  });

  final String value;
  final bool isSending;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = widget.value.trim().isNotEmpty && !widget.isSending;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF202024),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 3,
              enabled: !widget.isSending,
              onChanged: widget.onChanged,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: AppColors.accent,
              decoration: const InputDecoration.collapsed(
                hintText: 'Enter to wrap, tap send button to submit',
                hintStyle: TextStyle(color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const ComposerChip(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Auto',
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: AppColors.green,
                        size: 17,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Private',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: canSend ? widget.onSend : null,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: canSend
                          ? AppColors.accent
                          : AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: canSend
                          ? const Color(0xFF1A1400)
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ComposerChip extends StatelessWidget {
  const ComposerChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2930),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AiInlineError extends StatelessWidget {
  const AiInlineError({
    required this.message,
    required this.onDismiss,
    super.key,
  });

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 26),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF32161B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFFF6B7D), fontSize: 12),
            ),
          ),
          InkWell(
            onTap: onDismiss,
            customBorder: const CircleBorder(),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.close_rounded,
                color: Color(0xFFFF6B7D),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AiSidePanel extends StatelessWidget {
  const AiSidePanel({
    required this.onClose,
    required this.onNewChat,
    super.key,
  });

  final VoidCallback onClose;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: InkWell(
            onTap: onClose,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.48)),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.68,
            constraints: const BoxConstraints(maxWidth: 330),
            color: const Color(0xFF202024),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF7C6FE8), Color(0xFF9EA4AD)],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'CryptoLens AI',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Color(0xFF333039), height: 1),
                  DrawerAction(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'New chat',
                    onTap: onNewChat,
                  ),
                  DrawerAction(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Prompt Library',
                    onTap: onClose,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    color: const Color(0xFF2A2830),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 21,
                          backgroundColor: Color(0xFFD73E0F),
                          child: Text('C'),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'CryptoLens',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DrawerAction extends StatelessWidget {
  const DrawerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 27),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
