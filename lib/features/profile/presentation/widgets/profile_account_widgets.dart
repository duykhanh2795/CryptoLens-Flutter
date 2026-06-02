part of '../screens/profile_screen.dart';

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar();

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
              color: _ProfileColors.textPrimary,
              size: 28,
            ),
          ),
          const Expanded(
            child: Text(
              'Account Info',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ProfileColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(
            width: 48,
            child: Icon(
              Icons.manage_accounts_outlined,
              color: _ProfileColors.textPrimary,
              size: 27,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.displayName, required this.email});

  final String displayName;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _ProfileColors.surface,
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
                color: _ProfileColors.surfaceVariant,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                ),
              ),
              child: const Text(
                'Standard',
                style: TextStyle(
                  color: _ProfileColors.textPrimary,
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
                    _ProfileAvatar(name: displayName),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        displayName.isEmpty ? 'CryptoLens User' : displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ProfileColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                _AccountInfoLine(
                  label: 'CryptoLens UID',
                  value: _profileUid(email),
                  icon: Icons.content_copy_outlined,
                ),
                const SizedBox(height: 18),
                _AccountInfoLine(
                  label: 'Registration info',
                  value: email.isEmpty ? 'Not available' : email,
                  icon: Icons.visibility_outlined,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: _ProfileColors.divider),
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
                              color: _ProfileColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sync exchanges and wallet activity to level up',
                            style: TextStyle(
                              color: _ProfileColors.textSecondary,
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
                              color: _ProfileColors.yellow,
                              backgroundColor: _ProfileColors.surfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showComingSoon(context, 'Benefits'),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Benefits',
                            style: TextStyle(
                              color: _ProfileColors.yellow,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: _ProfileColors.yellow,
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name});

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
          backgroundColor: _ProfileColors.yellow,
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
              color: _ProfileColors.surfaceVariant,
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: _ProfileColors.textPrimary,
              size: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountInfoLine extends StatelessWidget {
  const _AccountInfoLine({
    required this.label,
    required this.value,
    required this.icon,
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
              color: _ProfileColors.textSecondary,
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
              color: _ProfileColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: _ProfileColors.textTertiary, size: 19),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
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
              child: Icon(icon, color: _ProfileColors.textPrimary, size: 25),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _ProfileColors.textPrimary,
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
                      color: _ProfileColors.textSecondary,
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
                color: _ProfileColors.textTertiary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactProfileAction extends StatelessWidget {
  const _CompactProfileAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = _ProfileColors.textPrimary,
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
          color: _ProfileColors.surface,
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
