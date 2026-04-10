class TransactionModel {
  final double amount;
  final String type;
  final String bank;
  final DateTime date;
  final String? accountNo;
  final String? referenceNo;

  TransactionModel({
    required this.amount,
    required this.type,
    required this.bank,
    required this.date,
    this.accountNo,
    this.referenceNo,
  });
}
