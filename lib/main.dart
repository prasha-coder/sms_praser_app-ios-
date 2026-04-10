import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/persistence_service.dart';
import 'services/deep_link_service.dart';
import 'services/clipboard_service.dart';
import 'providers/transaction_provider.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await PersistenceService.init();
  
  runApp(
    const ProviderScope(
      child: SmsParserApp(),
    ),
  );
}

class SmsParserApp extends ConsumerStatefulWidget {
  const SmsParserApp({super.key});

  @override
  ConsumerState<SmsParserApp> createState() => _SmsParserAppState();
}

class _SmsParserAppState extends ConsumerState<SmsParserApp> {
  late DeepLinkService _deepLinkService;

  @override
  void initState() {
    super.initState();
    
    // Initialize Deep Linking (Shortcuts integration)
    _deepLinkService = DeepLinkService(
      onNewTransaction: (tx) {
        ref.read(transactionProvider.notifier).addTransaction(tx);
      },
    );
    _deepLinkService.init();

    // Smart Clipboard Check on App Start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkClipboard();
    });
  }

  Future<void> _checkClipboard() async {
    final tx = await ClipboardService.checkAndParseClipboard();
    if (tx != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Detected transaction from clipboard: Rs. ${tx.amount}"),
            action: SnackBarAction(
              label: "SAVE",
              onPressed: () {
                PersistenceService.saveTransaction(tx);
                ref.read(transactionProvider.notifier).addTransaction(tx);
              },
            ),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Parser iOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Inter',
      ),
      home: const DashboardScreen(),
    );
  }
}
