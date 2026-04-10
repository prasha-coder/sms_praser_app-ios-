import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';

class PersistenceService {
  static const String boxName = 'transactions';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(boxName);
  }

  static Future<void> saveTransaction(TransactionModel transaction) async {
    final box = Hive.box(boxName);
    
    // Deduplication check
    final exists = box.values.any((e) {
      final map = e as Map;
      return map['amount'] == transaction.amount &&
             map['date'] == transaction.date.toIso8601String() &&
             map['bank'] == transaction.bank;
    });

    if (!exists) {
      await box.add({
        'amount': transaction.amount,
        'type': transaction.type,
        'bank': transaction.bank,
        'date': transaction.date.toIso8601String(),
        'accountNo': transaction.accountNo,
        'referenceNo': transaction.referenceNo,
      });
    }
  }

  static List<TransactionModel> getTransactions() {
    final box = Hive.box(boxName);
    return box.values.map((e) {
      final map = e as Map;
      return TransactionModel(
        amount: map['amount'] as double,
        type: map['type'] as String,
        bank: map['bank'] as String,
        date: DateTime.parse(map['date'] as String),
        accountNo: map['accountNo'] as String?,
        referenceNo: map['referenceNo'] as String?,
      );
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }
}
