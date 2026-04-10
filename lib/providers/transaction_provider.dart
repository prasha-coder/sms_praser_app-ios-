import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../services/persistence_service.dart';

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<TransactionModel>>((ref) {
  return TransactionNotifier();
});

class TransactionNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionNotifier() : super([]) {
    loadTransactions();
  }

  void loadTransactions() {
    state = PersistenceService.getTransactions();
  }

  void addTransaction(TransactionModel transaction) {
    // Check if it already exists in the state to avoid UI flicker
    final exists = state.any((e) => 
      e.amount == transaction.amount && 
      e.date == transaction.date && 
      e.bank == transaction.bank
    );
    
    if (!exists) {
      state = [transaction, ...state]..sort((a, b) => b.date.compareTo(a.date));
    }
  }
}
