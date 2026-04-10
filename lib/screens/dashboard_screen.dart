import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/transaction_provider.dart';
import '../services/gmail_service.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildBalanceCard(transactions),
              Expanded(
                child: _buildTransactionList(transactions),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final gmail = GmailService();
          await gmail.syncTransactions();
          ref.read(transactionProvider.notifier).loadTransactions();
        },
        label: const Text("Sync Gmail"),
        icon: const Icon(Icons.sync),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My Transactions",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "iOS SMS Parser",
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
          IconButton(
            onPressed: () => _showSettings(context),
            icon: const Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(List<TransactionModel> txs) {
    double spent = 0;
    double gained = 0;
    for (var tx in txs) {
      if (tx.type == "DEBIT") spent += tx.amount;
      if (tx.type == "CREDIT") gained += tx.amount;
    }

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              const Text(
                "Net Balance Impact",
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                "₹ ${(gained - spent).toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem("Spent", spent, Colors.redAccent),
                  _buildStatItem("Gained", gained, Colors.greenAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double val, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          "₹ ${val.toInt()}",
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTransactionList(List<TransactionModel> txs) {
    if (txs.isEmpty) {
      return const Center(
        child: Text(
          "No transactions found.\nUse Gmail Sync or iOS Shortcuts.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: txs.length,
      itemBuilder: (context, index) {
        final tx = txs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (tx.type == "DEBIT" ? Colors.red : Colors.green).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  tx.type == "DEBIT" ? Icons.arrow_outward : Icons.arrow_downward,
                  color: tx.type == "DEBIT" ? Colors.redAccent : Colors.greenAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.bank,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${DateFormat('dd MMM, hh:mm a').format(tx.date)} • ${tx.accountNo}",
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                "${tx.type == "DEBIT" ? "-" : "+"}₹${tx.amount.toInt()}",
                style: TextStyle(
                  color: tx.type == "DEBIT" ? Colors.redAccent : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B4B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "iOS Setup Guide",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const ListTile(
                leading: Icon(Icons.bolt, color: Colors.amber),
                title: Text("Real-time Tracking", style: TextStyle(color: Colors.white)),
                subtitle: Text("Configure iOS Shortcuts to auto-read bank SMS.", style: TextStyle(color: Colors.white60)),
              ),
              const ListTile(
                leading: Icon(Icons.email, color: Colors.blue),
                title: Text("Gmail Historical Sync", style: TextStyle(color: Colors.white)),
                subtitle: Text("Connect your Google account to fetch past alerts.", style: TextStyle(color: Colors.white60)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Got it!", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
