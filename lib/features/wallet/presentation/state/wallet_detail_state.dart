enum WalletDetailTab {
  assets('ASSETS'),
  history('HISTORY');

  const WalletDetailTab(this.label);
  final String label;
}

enum WalletHistoryFilter {
  all('All'),
  received('Received'),
  sent('Sent'),
  executed('Contract'),
  token('Token');

  const WalletHistoryFilter(this.label);
  final String label;
}
