// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// KORREKTUR: Tippfehler im Paketnamen behoben
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'data/services/supabase_service.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // .env Datei laden
    await dotenv.load();

    // Supabase initialisieren
    await SupabaseService.initialize();

    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    // Fehler beim Initialisieren
    debugPrint('Error during app initialization: $e');
    runApp(const ProviderScope(child: ErrorApp()));
  }
}

// KORREKTUR: Zu ConsumerWidget geändert, um auf Provider zuzugreifen
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Den Router vom Provider abrufen
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'GrowTracker',
      // KORREKTUR: Ursprüngliche, einfache Theme-Konfiguration wiederhergestellt
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// Fallback App für Initialisierungsfehler
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowTracker - Error',
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Initialisierungsfehler',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Die App konnte nicht korrekt gestartet werden. Bitte überprüfe deine Internetverbindung und starte die App erneut.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // App neu starten (in der Entwicklung)
                    debugPrint('App restart requested');
                  },
                  child: const Text('App neu starten'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}