import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cryptolens_flutter/core/utils/formatters.dart';
import 'package:cryptolens_flutter/features/wallet/domain/wallet.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/widgets/wallet_colors.dart';
import 'package:cryptolens_flutter/features/wallet/presentation/widgets/wallet_format_helpers.dart';

void showTransactionSheet(BuildContext context, WalletTransaction tx) {
  final explorer = transactionExplorerUrl(tx);
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: WalletColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(tx.type.label, style: WalletColors.sectionTitle),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                color: WalletColors.textSecondary,
              ),
            ],
          ),
          DetailRow('Amount', '${formatNativeAmount(tx.amount)} ${tx.symbol}'),
          DetailRow(
            'Value',
            tx.valueUsd == null ? 'Unavailable' : formatPrice(tx.valueUsd!),
          ),
          DetailRow(
            'Time',
            DateFormat('MMM dd, yyyy HH:mm').format(tx.timestamp),
          ),
          DetailRow('Tx hash', shortWalletAddress(tx.id)),
          DetailRow(
            'Counterparty',
            tx.counterparty == null
                ? 'Unavailable'
                : shortWalletAddress(tx.counterparty!),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: tx.id)),
                  child: const Text('Copy Hash'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: tx.counterparty == null
                      ? null
                      : () => Clipboard.setData(
                          ClipboardData(text: tx.counterparty!),
                        ),
                  child: const Text('Copy Address'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: explorer == null
                  ? null
                  : () => unawaited(launchUrl(Uri.parse(explorer))),
              style: FilledButton.styleFrom(
                backgroundColor: WalletColors.yellow,
                foregroundColor: const Color(0xFF1A1400),
              ),
              child: const Text('Open Explorer'),
            ),
          ),
        ],
      ),
    ),
  );
}

class DetailRow extends StatelessWidget {
  const DetailRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(label, style: WalletColors.sub),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: WalletColors.body.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
