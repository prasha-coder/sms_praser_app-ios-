import 'package:flutter/services.dart';
import 'parser_service.dart';
import '../models/transaction_model.dart';

class ClipboardService {
  static Future<TransactionModel?> checkAndParseClipboard() async {
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    final String? text = data?.text;

    if (text != null && text.isNotEmpty) {
      return ParserService.parseTransaction(text);
    }
    return null;
  }
}
