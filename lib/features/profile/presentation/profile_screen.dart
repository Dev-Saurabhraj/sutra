import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/bits.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/thread_stripe.dart';
import '../../auth/presentation/session_controller.dart';
import '../../gst/presentation/gst_text.dart';
import '../../catalog/presentation/catalog_text.dart';
import '../../orders/presentation/order_text.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final me = ref.watch(meProvider);
    final p = me?.producer;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: SutraSpace.page,
          children: [
            Text(s.profileTitle, style: SutraType.display(28)),
            const SizedBox(height: 16),
            if (p != null) ...[
              Row(
                children: [
                  InitialsBadge(name: p.name, color: hexColor(p.avatarColor), size: 60),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.businessName, style: SutraType.display(20)),
                        Text('${p.name} · ${p.city}', style: text.bodySmall),
                        Text(['${p.industry.emoji} ${s.pick(p.industry.nameHi, p.industry.name)}', ?p.clusterName].join(' · '), style: text.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const ThreadStripe(radius: 2),
              const SizedBox(height: 14),
              LedgerCard(
                child: Column(
                  children: [
                    LedgerLine(label: s.gstScheme, value: Text(s.schemeName(p.gstScheme), style: text.titleSmall)),
                    if (p.gstin != null) LedgerLine(label: 'GSTIN', value: Text(p.gstin!, style: SutraType.figure(14))),
                    LedgerLine(label: s.udyam, value: Text(p.udyamNumber ?? s.notAdded, style: SutraType.figure(14))),
                    LedgerLine(
                      label: s.pick(p.industry.machineHi, p.industry.machine),
                      value: Text(s.machinesOf(p.machines, p.industry.machineHi, p.industry.machine), style: text.titleSmall),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.push('/gst'),
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(s.tr(GstText.title)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/orders'),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: Text(s.tr(OrderText.title)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/catalog'),
                      icon: const Icon(Icons.auto_stories_outlined),
                      label: Text(s.tr(CatalogText.title)),
                    ),
                  ),
                ],
              ),
            ],
            SectionHeader(s.language),
            _LanguagePicker(strings: s),
            SectionHeader(s.privacy),
            Text(s.consentPoints.join('\n'), style: text.bodySmall),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
              icon: const Icon(Icons.logout_rounded),
              label: Text(s.logout),
              style: OutlinedButton.styleFrom(foregroundColor: SutraColors.kumkum),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<AppLang>(
      segments: [for (final l in AppLang.values) ButtonSegment(value: l, label: Text(l.label))],
      selected: {strings.lang},
      showSelectedIcon: false,
      onSelectionChanged: (v) async {
        final lang = v.first;
        await ref.read(langProvider.notifier).set(lang);
        try {
          await ref.read(authRepositoryProvider).setLanguage(lang.code);
        } catch (_) {
          // The choice is saved on the phone; the server copy can sync later.
        }
      },
    );
  }
}
