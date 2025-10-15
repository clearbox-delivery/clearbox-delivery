import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:core_data/core_data.dart';
import 'package:supabase_client/supabase_client.dart';
import 'package:courier_app/widgets/app_bottom_nav.dart';
import 'package:intl/intl.dart';

/// Courier Wallet Page (Earnings and Payouts)
/// [REQ-COU-WALLET-001] Display courier earnings, payouts, and transactions
class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Payout>? _payouts;
  List<WalletTransaction>? _transactions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authService = ref.read(authServiceProvider);
    final courierId = authService.currentUserId;

    if (courierId == null) {
      setState(() => _loading = false);
      return;
    }

    final walletService = ref.read(walletServiceProvider);
    final payouts = await walletService.getPayouts(courierId);
    final transactions = await walletService.getTransactions(courierId);

    if (mounted) {
      setState(() {
        _payouts = payouts;
        _transactions = transactions;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bg,
      appBar: AppBar(
        title: const Text('錢包'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '結算'),
            Tab(text: '明細'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPayoutsTab(),
                _buildTransactionsTab(),
              ],
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3), // Assuming wallet is 4th tab
    );
  }

  Widget _buildPayoutsTab() {
    if (_payouts == null || _payouts!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: DesignTokens.textMuted),
            SizedBox(height: DesignTokens.sp4),
            Text(
              '暫無結算記錄',
              style: TextStyle(
                fontSize: DesignTokens.fsMd,
                color: DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(DesignTokens.sp4),
        itemCount: _payouts!.length,
        separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp3),
        itemBuilder: (context, index) {
          final payout = _payouts![index];
          return _buildPayoutCard(payout);
        },
      ),
    );
  }

  Widget _buildPayoutCard(Payout payout) {
    final status = PayoutStatus.fromString(payout.status);
    final statusColor = _getPayoutStatusColor(status);
    final dateFormat = DateFormat('MM/dd');

    return CBCard(
      key: Key('payout-${payout.id}'),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.sp4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${dateFormat.format(payout.periodStart)} - ${dateFormat.format(payout.periodEnd)}',
                  style: const TextStyle(
                    fontSize: DesignTokens.fsMd,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.sp2,
                    vertical: DesignTokens.sp1,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: Text(
                    status.displayName,
                    style: TextStyle(
                      fontSize: DesignTokens.fsXs,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.sp3),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NT\$ ${payout.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: DesignTokens.fsXl,
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.brand,
                  ),
                ),
                if (payout.orderCount != null)
                  Text(
                    '${payout.orderCount} 筆訂單',
                    style: const TextStyle(
                      fontSize: DesignTokens.fsSm,
                      color: DesignTokens.textSecondary,
                    ),
                  ),
              ],
            ),
            if (payout.paidAt != null) ...[
              const SizedBox(height: DesignTokens.sp2),
              Text(
                '已付款：${DateFormat('yyyy/MM/dd HH:mm').format(payout.paidAt!)}',
                style: const TextStyle(
                  fontSize: DesignTokens.fsXs,
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    if (_transactions == null || _transactions!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: DesignTokens.textMuted),
            SizedBox(height: DesignTokens.sp4),
            Text(
              '暫無交易記錄',
              style: TextStyle(
                fontSize: DesignTokens.fsMd,
                color: DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(DesignTokens.sp4),
        itemCount: _transactions!.length,
        separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.sp2),
        itemBuilder: (context, index) {
          final tx = _transactions![index];
          return _buildTransactionCard(tx);
        },
      ),
    );
  }

  Widget _buildTransactionCard(WalletTransaction tx) {
    final type = TransactionType.fromString(tx.type);
    final isPositive = type == TransactionType.earnings || type == TransactionType.bonus;
    final amountColor = isPositive ? DesignTokens.success : DesignTokens.danger;
    final dateFormat = DateFormat('MM/dd HH:mm');

    return CBCard(
      key: Key('tx-${tx.id}'),
      child: ListTile(
        leading: Icon(
          _getTransactionIcon(type),
          color: amountColor,
        ),
        title: Text(
          type.displayName,
          style: const TextStyle(
            fontSize: DesignTokens.fsMd,
            color: DesignTokens.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tx.description != null)
              Text(
                tx.description!,
                style: const TextStyle(
                  fontSize: DesignTokens.fsSm,
                  color: DesignTokens.textSecondary,
                ),
              ),
            const SizedBox(height: DesignTokens.sp1),
            Text(
              dateFormat.format(tx.createdAt),
              style: const TextStyle(
                fontSize: DesignTokens.fsXs,
                color: DesignTokens.textMuted,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${isPositive ? '+' : '-'}NT\$ ${tx.amount.abs().toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: DesignTokens.fsMd,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.sp3,
          vertical: DesignTokens.sp2,
        ),
      ),
    );
  }

  Color _getPayoutStatusColor(PayoutStatus status) {
    switch (status) {
      case PayoutStatus.paid:
        return DesignTokens.success;
      case PayoutStatus.failed:
        return DesignTokens.danger;
      case PayoutStatus.processing:
        return DesignTokens.brand;
      case PayoutStatus.pending:
        return DesignTokens.warning;
    }
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.earnings:
        return Icons.delivery_dining;
      case TransactionType.bonus:
        return Icons.card_giftcard;
      case TransactionType.penalty:
        return Icons.warning_outlined;
      case TransactionType.payout:
        return Icons.account_balance;
    }
  }
}

