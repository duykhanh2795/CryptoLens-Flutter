part of '../screens/profile_screen.dart';

void _showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature is being ported from Kotlin.')),
  );
}

void _showChangePassword(BuildContext context) {
  final newPassword = TextEditingController();
  final confirmPassword = TextEditingController();
  var visible = false;
  var saving = false;
  String? error;
  showDialog<void>(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: _ProfileColors.surface,
        title: const Text(
          'Change Password',
          style: TextStyle(color: _ProfileColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPassword,
              obscureText: !visible,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPassword,
              obscureText: !visible,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: visible,
              onChanged: (value) =>
                  setDialogState(() => visible = value ?? false),
              title: const Text(
                'Show password',
                style: TextStyle(color: _ProfileColors.textSecondary),
              ),
            ),
            if (error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  error!,
                  style: const TextStyle(color: AppColors.red),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _ProfileColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: saving
                ? null
                : () async {
                    setDialogState(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      await CryptoAuthService().updatePassword(
                        newPassword: newPassword.text,
                        confirmPassword: confirmPassword.text,
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated')),
                      );
                    } on CryptoAuthException catch (authError) {
                      setDialogState(() {
                        error = authError.message;
                        saving = false;
                      });
                    } catch (exception) {
                      setDialogState(() {
                        error = exception.toString();
                        saving = false;
                      });
                    }
                  },
            style: FilledButton.styleFrom(
              backgroundColor: _ProfileColors.yellow,
            ),
            child: saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Color(0xFF1A1400)),
                  ),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    newPassword.dispose();
    confirmPassword.dispose();
  });
}

void _showClearPortfolio(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _ProfileColors.surface,
      icon: const Icon(Icons.delete_forever_outlined, color: AppColors.red),
      title: const Text(
        'Clear Portfolio?',
        style: TextStyle(color: _ProfileColors.textPrimary),
      ),
      content: const Text(
        'This removes all local portfolio transactions. Exchange connections stay linked and can be synced again.',
        style: TextStyle(color: _ProfileColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: _ProfileColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () async {
            await PortfolioStore().clear();
            if (!context.mounted) return;
            Navigator.of(context).pop();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Portfolio cleared')));
          },
          child: const Text('Clear', style: TextStyle(color: AppColors.red)),
        ),
      ],
    ),
  );
}

void _showLogout(BuildContext context, VoidCallback onLogout) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: _ProfileColors.surface,
      icon: const Icon(Icons.logout_rounded, color: AppColors.red),
      title: const Text(
        'Log Out?',
        style: TextStyle(color: _ProfileColors.textPrimary),
      ),
      content: const Text(
        'Your portfolio data will remain saved locally on this device.',
        style: TextStyle(color: _ProfileColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: _ProfileColors.textSecondary),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onLogout();
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.red),
          child: const Text('Log Out'),
        ),
      ],
    ),
  );
}

String _profileUid(String email) {
  final hash = email.codeUnits.fold<int>(
    0,
    (value, unit) => (value * 31 + unit) & 0x7fffffff,
  );
  return hash.toString().padLeft(9, '0').substring(0, 9);
}

void _showSelection(
  BuildContext context,
  String title,
  String selected,
  List<String> options,
  ValueChanged<String> onSelected,
) {
  showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: _ProfileColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  color: _ProfileColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const Divider(color: _ProfileColors.divider, height: 1),
          for (final option in options)
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                onSelected(option);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: option == selected
                              ? _ProfileColors.yellow
                              : _ProfileColors.textPrimary,
                          fontWeight: option == selected
                              ? FontWeight.w900
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (option == selected)
                      const Icon(
                        Icons.check_rounded,
                        color: _ProfileColors.yellow,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _ProfileColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
