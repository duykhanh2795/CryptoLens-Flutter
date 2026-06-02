import 'package:flutter/material.dart';

import 'package:cryptolens_flutter/features/profile/presentation/widgets/profile_colors.dart';
import 'package:cryptolens_flutter/features/profile/presentation/widgets/profile_dialogs.dart';

class ProfileTopBar extends StatelessWidget {
  const ProfileTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: ProfileColors.textPrimary,
              size: 28,
            ),
          ),
          const Expanded(
            child: Text(
              'Account Info',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ProfileColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(
            width: 48,
            child: Icon(
              Icons.manage_accounts_outlined,
              color: ProfileColors.textPrimary,
              size: 27,
            ),
          ),
        ],
      ),
    );
  }
}

class AccountInfoCard extends StatelessWidget {
  const AccountInfoCard({
    required this.displayName,
    required this.email,
    super.key,
  });

  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ProfileColors.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: const BoxDecoration(
                color: ProfileColors.surfaceVariant,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: const Text(
                'Standard',
                style: TextStyle(
                  color: ProfileColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 22, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    ProfileAvatar(name: displayName),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        displayName.isEmpty ? 'CryptoLens User' : displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ProfileColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                AccountInfoLine(
                  label: 'CryptoLens UID',
                  value: profileUid(email),
                  icon: Icons.content_copy_outlined,
                ),
                const SizedBox(height: 18),
                AccountInfoLine(
                  label: 'Registration info',
                  value: email.isEmpty ? 'Not available' : email,
                  icon: Icons.visibility_outlined,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: ProfileColors.divider),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upgrade to Pro 1',
                            style: TextStyle(
                              color: ProfileColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sync exchanges and wallet activity to level up',
                            style: TextStyle(
                              color: ProfileColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: 0.08,
                              minHeight: 7,
                              color: ProfileColors.yellow,
                              backgroundColor: ProfileColors.surfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => showComingSoon(context, 'Benefits'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Benefits',
                            style: TextStyle(
                              color: ProfileColors.yellow,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: ProfileColors.yellow,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    final cleanName = name.trim();
    final initial = cleanName.isEmpty
        ? 'C'
        : cleanName.substring(0, 1).toUpperCase();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: ProfileColors.yellow,
          child: Text(
            initial,
            style: const TextStyle(
              color: Color(0xFF111214),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ProfileColors.surfaceVariant,
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: ProfileColors.textPrimary,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class AccountInfoLine extends StatelessWidget {
  const AccountInfoLine({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 142,
          child: Text(
            label,
            style: const TextStyle(
              color: ProfileColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: ProfileColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: ProfileColors.textTertiary, size: 19),
      ],
    );
  }
}

class ProfileRow extends StatelessWidget {
  const ProfileRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 18),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Icon(icon, color: ProfileColors.textPrimary, size: 25),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: ProfileColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 24),
              SizedBox(
                width: 116,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    trailingText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: ProfileColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
            ] else
              const SizedBox(width: 158),
            const SizedBox(
              width: 24,
              child: Icon(
                Icons.chevron_right_rounded,
                color: ProfileColors.textTertiary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompactProfileAction extends StatelessWidget {
  const CompactProfileAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = ProfileColors.textPrimary,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: ProfileColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
