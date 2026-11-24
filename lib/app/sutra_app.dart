import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/theme.dart';
import 'providers.dart';
import 'router.dart';

class SutraApp extends ConsumerWidget {
  const SutraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    return MaterialApp.router(
      title: 'Sutra',
      debugShowCheckedModeBanner: false,
      theme: SutraTheme.light(),
      routerConfig: ref.watch(routerProvider),
      locale: Locale(lang.code, 'IN'),
      supportedLocales: const [Locale('hi', 'IN'), Locale('en', 'IN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Older users often raise system font size; cap it so ledger rows stay readable, not broken.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 1, maxScaleFactor: 1.3)),
          child: child!,
        );
      },
    );
  }
}
