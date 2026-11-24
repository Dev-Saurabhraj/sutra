import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/gst/gstin.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/art/industry_scenes.dart';
import '../../../design/art/shop_scene.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/thread_stripe.dart';
import '../../auth/presentation/session_controller.dart';
import '../../market/data/market_repository.dart';
import '../../market/domain/market_models.dart';
import '../../market/presentation/market_text.dart';
import 'onboarding_steps.dart';
import 'onboarding_text.dart';

enum OnboardingRole { maker, buyer }

/// Who is signing up. Null until they choose.
final onboardingRoleProvider = StateProvider<OnboardingRole?>((_) => null);

/// The first question for a new number: make/sell, or buy for a shop. Two living pictures, one tap.
class RoleChoiceView extends ConsumerWidget {
  const RoleChoiceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text(s.tr(MarketText.roleTitle), style: SutraType.display(26)),
        const SizedBox(height: 20),
        _RoleCard(
          art: const IndustryArt('handloom'),
          title: s.tr(MarketText.roleMaker),
          sub: s.tr(MarketText.roleMakerSub),
          color: SutraColors.sindoor,
          onTap: () => ref.read(onboardingRoleProvider.notifier).state = OnboardingRole.maker,
        ),
        const SizedBox(height: 14),
        _RoleCard(
          art: const ShopArt(),
          title: s.tr(MarketText.roleBuyer),
          sub: s.tr(MarketText.roleBuyerSub),
          color: SutraColors.neel,
          onTap: () => ref.read(onboardingRoleProvider.notifier).state = OnboardingRole.buyer,
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: () => ref.read(langProvider.notifier).set(s.isHindi ? AppLang.en : AppLang.hi),
            icon: const Icon(Icons.translate_rounded),
            label: Text(s.isHindi ? AppLang.en.label : AppLang.hi.label),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.art, required this.title, required this.sub, required this.color, required this.onTap});
  final Widget art;
  final String title;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SutraColors.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: const BorderRadius.all(SutraRadius.lg), side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.4)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 132,
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFF7EA), Color(0xFFF6E7D3)])),
              padding: const EdgeInsets.all(10),
              child: art,
            ),
            const ThreadStripe(height: 3),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: SutraType.display(19, color: color)),
                        const SizedBox(height: 2),
                        Text(sub, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: color),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A buyer needs four facts: who, which shop, where (decides the GST type), and a GSTIN if they have one.
class BuyerSignupView extends ConsumerStatefulWidget {
  const BuyerSignupView({super.key});

  @override
  ConsumerState<BuyerSignupView> createState() => _BuyerSignupViewState();
}

class _BuyerSignupViewState extends ConsumerState<BuyerSignupView> {
  final _name = TextEditingController();
  final _business = TextEditingController();
  final _city = TextEditingController();
  final _gstin = TextEditingController();
  String? _state;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _business, _city, _gstin]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Same checks as the maker's GST step: length, format, check digit, and the state code.
  String? _gstinProblem(AppStrings s) {
    final g = _gstin.text.trim();
    if (g.isEmpty) return null;
    return switch (checkGstin(g, state: _state)) {
      null => null,
      GstinProblem.length => s.tr(OnbText.gstinLength),
      GstinProblem.format || GstinProblem.state => s.tr(OnbText.gstinFormat),
      GstinProblem.checkDigit => s.tr(OnbText.gstinCheck),
      GstinProblem.wrongState => s.tr(OnbText.gstinState),
    };
  }

  bool get _ready => _name.text.trim().length >= 2 && _business.text.trim().length >= 2 && _city.text.trim().length >= 2 && _state != null;

  Future<void> _submit() async {
    final s = ref.read(stringsProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(marketRepositoryProvider).signUp(
            BuyerSignup(name: _name.text.trim(), business: _business.text.trim(), city: _city.text.trim(), state: _state!, gstin: _gstin.text),
            language: ref.read(langProvider).code,
          );
      await ref.read(sessionControllerProvider.notifier).reload();
    } catch (e) {
      final err = ApiException.from(e);
      if (mounted) setState(() => _error = s.isHindi ? (err.messageHi ?? err.message) : err.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final gstProblem = _gstinProblem(s);
    return Column(
      children: [
        Expanded(
          child: StepFrame(
            art: const ShopArt(),
            title: s.tr(MarketText.buyerTitle),
            body: s.tr(MarketText.buyerBody),
            children: [
              TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: s.tr(MarketText.yourName)), onChanged: (_) => setState(() {})),
              const SizedBox(height: 12),
              TextField(controller: _business, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: s.tr(MarketText.business)), onChanged: (_) => setState(() {})),
              const SizedBox(height: 12),
              TextField(controller: _city, textCapitalization: TextCapitalization.words, decoration: InputDecoration(labelText: s.tr(MarketText.city)), onChanged: (_) => setState(() {})),
              const SizedBox(height: 12),
              StatePickerField(label: s.tr(MarketText.state), value: _state, onChanged: (v) => setState(() => _state = v)),
              const SizedBox(height: 12),
              TextField(
                controller: _gstin,
                textCapitalization: TextCapitalization.characters,
                maxLength: 15,
                decoration: InputDecoration(labelText: s.tr(MarketText.gstin), errorText: gstProblem, counterText: ''),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              Text(s.tr(MarketText.gstinWhy), style: Theme.of(context).textTheme.bodySmall),
              if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: SutraColors.kumkum))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              TextButton(onPressed: _busy ? null : () => ref.read(onboardingRoleProvider.notifier).state = null, child: Text(s.tr(MarketText.back))),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: SutraColors.neel, minimumSize: const Size.fromHeight(52)),
                  onPressed: _busy || !_ready || gstProblem != null ? null : _submit,
                  child: _busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : Text(s.tr(MarketText.openBazaar)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
