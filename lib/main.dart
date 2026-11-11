import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Datas em português ("sáb, 15 de nov") usadas nas telas de rolê.
  await initializeDateFormatting('pt_BR');
  await initSupabase();
  runApp(
    const ProviderScope(
      child: ChammaApp(),
    ),
  );
}
