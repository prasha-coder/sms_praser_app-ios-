import 'dart:async';
import 'package:app_links/app_links.dart';
import 'parser_service.dart';
import 'persistence_service.dart';
import '../models/transaction_model.dart';

class DeepLinkService {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final Function(TransactionModel)? onNewTransaction;

  DeepLinkService({this.onNewTransaction});

  void init() {
    _appLinks = AppLinks();

    // Check for initial link (app started from link)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleLink(uri);
    });

    // Listen for incoming links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleLink(uri);
    });
  }

  void _handleLink(Uri uri) {
    if (uri.scheme == 'smsparser' && uri.host == 'parse') {
      final String? body = uri.queryParameters['body'];
      if (body != null && body.isNotEmpty) {
        final transaction = ParserService.parseTransaction(body);
        if (transaction != null) {
          PersistenceService.saveTransaction(transaction);
          onNewTransaction?.call(transaction);
        }
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
