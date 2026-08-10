import 'package:flutter/material.dart';
import 'package:pass_doc_manager/app/app.dart';
import 'package:pass_doc_manager/app/di/injection.dart';
import 'package:pass_doc_manager/app/platform/desktop_window_manager.dart';
import 'package:pass_doc_manager/core/utils/local_asset_path_resolver.dart';
import 'package:pass_doc_manager/data/shared/storage/hive_migrations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDesktopWindow();
  runApp(const _CredenceLaunchApp());

  try {
    registerHiveMigrations();
    await LocalAssetPathResolver.initialize();
    await configureDependencies();
    runApp(const CredenceApp());
  } catch (error, stackTrace) {
    debugPrint('[Bootstrap] App initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    runApp(_CredenceLaunchErrorApp(error: error));
  }
}

class _CredenceLaunchApp extends StatelessWidget {
  const _CredenceLaunchApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFFFBFAF6),
        body: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Color(0xFF221D16),
            ),
          ),
        ),
      ),
    );
  }
}

class _CredenceLaunchErrorApp extends StatelessWidget {
  const _CredenceLaunchErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFFBFAF6),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Launch failed',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF221D16),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A startup dependency failed before the vault could open.',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.35,
                    color: Color(0xFF7E776F),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '$error',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFFE5484D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
