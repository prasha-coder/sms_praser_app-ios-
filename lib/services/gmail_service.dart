import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'parser_service.dart';
import 'persistence_service.dart';
import '../models/transaction_model.dart';
import 'dart:convert';

class GmailService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      GmailApi.gmailReadonlyScope,
    ],
  );

  GoogleSignInAccount? _currentUser;

  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser != null;
    } catch (error) {
      print(error);
      return false;
    }
  }

  Future<void> syncTransactions() async {
    if (_currentUser == null) {
      final success = await signIn();
      if (!success) return;
    }

    final httpClient = (await _googleSignIn.authenticatedClient())!;
    final gmailApi = GmailApi(httpClient);

    // Filter to find bank transaction emails
    // You can customize this query: e.g., "from:alerts@bank.com OR from:info@hdfcbank.net"
    const String query = "credited OR debited OR spent OR paid";
    
    final ListMessagesResponse results = await gmailApi.users.messages.list(
      'me',
      q: query,
      maxResults: 20,
    );

    final messages = results.messages ?? [];
    for (var msg in messages) {
      final message = await gmailApi.users.messages.get('me', msg.id!);
      final snippet = message.snippet ?? "";
      
      // Parse the snippet first as it's often enough for basic transaction details
      final transaction = ParserService.parseTransaction(snippet);
      if (transaction != null) {
        await PersistenceService.saveTransaction(transaction);
      } else {
        // If snippet wasn't enough, we could parse the full body here
        // (Base64 decoding of parts[0].body.data)
      }
    }
  }

  Future<void> signOut() => _googleSignIn.disconnect();
}
