import '../models/transaction_model.dart';

class ParserService {
  static TransactionModel? parseTransaction(String message, {DateTime? date, String? sender}) {
    try {
      final upperSender = sender?.toUpperCase() ?? "UNKNOWN";
      
      // Filter out phone numbers (usually start with + or digits)
      if (upperSender.startsWith('+') || RegExp(r'^\d+$').hasMatch(upperSender)) return null;

      final bankIdentifiers = [
        "BOI", "HDFC", "ICICI", "SBI", "YONO", "AXIS", "KOTAK", "PNB", 
        "IDFC", "INDUS", "YES", "CAN", "UNION", "UBI", "BOB", "IOB", 
        "PAYTM", "AIRP", "CEN", "MAHAB", "FED", "KVB", "RBL", "DBS", 
        "SCB", "CITI", "HSBC", "INDIAN", "UCO", "BOM", "IDBI", "DHAN"
      ];

      bool isFromBank = bankIdentifiers.any((id) => upperSender.contains(id));
      
      // If we don't have a bank sender, we might be parsing a raw copy-paste or email
      // So we allow parsing if the message body has strong indicators.
      final lowerMsg = message.toLowerCase();
      bool isTransaction = lowerMsg.contains("credited") || lowerMsg.contains("debited") || lowerMsg.contains("spent") || lowerMsg.contains("paid");
      
      if (!isFromBank && !isTransaction) return null;

      bool containsCredit = lowerMsg.contains("credited") || lowerMsg.contains("received") || lowerMsg.contains("deposit");
      bool containsDebit = lowerMsg.contains("debited") || lowerMsg.contains("spent") || lowerMsg.contains("paid") || lowerMsg.contains("withdrawn");

      String type;
      if (containsCredit && containsDebit) {
        if (lowerMsg.indexOf("debited") < lowerMsg.indexOf("credited")) {
          type = "DEBIT";
        } else {
          type = "CREDIT";
        }
      } else {
        type = containsCredit ? "CREDIT" : "DEBIT";
      }

      final amountRegex = RegExp(r'(?:Rs\.?|INR|₹)\s?(\d+(?:,\d+)*(?:\.\d+)?)', caseSensitive: false);
      final match = amountRegex.firstMatch(message);

      if (match == null) return null;

      String rawAmount = match.group(1)!.replaceAll(',', '');
      double amount = double.parse(rawAmount);

      final accountRegex = RegExp(r'(?:a/c|ac|acct|account)[\s.]*(?:no\.?)?[\s:-]*([xX\*]*\d+)', caseSensitive: false);
      final refRegex = RegExp(r'(?:ref|utr|upi\s*ref|txn|transaction)[\s]*(?:no\.?|id)?[\s:-]*([A-Za-z0-9]{5,})', caseSensitive: false);

      final acctMatch = accountRegex.firstMatch(message);
      final refMatch = refRegex.firstMatch(message);

      String? accountNo = acctMatch?.group(1);
      String? referenceNo = refMatch?.group(1);

      // Mask the account number: Take last 3 digits and prefix with XXX
      String cleanAcct = accountNo?.replaceAll(RegExp(r'[^0-9]'), '') ?? "0";
      String maskedAccount = cleanAcct.length >= 3 
          ? "XXX${cleanAcct.substring(cleanAcct.length - 3)}" 
          : "XXX$cleanAcct";

      return TransactionModel(
        amount: amount,
        type: type,
        bank: upperSender,
        date: date ?? DateTime.now(),
        accountNo: maskedAccount == "XXX0" ? "Unknown" : maskedAccount,
        referenceNo: referenceNo,
      );
    } catch (e) {
      return null;
    }
  }
}
