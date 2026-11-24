import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/network/api_exception.dart';
import '../../../design/tokens.dart';
import '../../../design/typography.dart';
import '../../../design/widgets/ledger_card.dart';
import '../../../design/widgets/thread_stripe.dart';
import '../domain/auth_repository.dart';
import 'session_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  OtpRequest? _sent;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      final err = ApiException.from(e);
      final s = ref.read(stringsProvider);
      setState(() => _error = s.isHindi ? (err.messageHi ?? err.message) : err.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestCode() => _run(() async {
        final r = await ref.read(authRepositoryProvider).requestOtp(_phone.text);
        setState(() => _sent = r);
      });

  Future<void> _verify() => _run(() => ref.read(sessionControllerProvider.notifier).signIn(_sent!.phone, _code.text.trim()));

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: SutraSpace.maxWidth),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Align(alignment: Alignment.centerRight, child: _LangSwitch(strings: s)),
                const SizedBox(height: 28),
                Text(s.appName, style: SutraType.display(54, color: SutraColors.sindoor)),
                Text(s.tagline, style: SutraType.display(18, color: SutraColors.inkSoft, weight: FontWeight.w600)),
                const SizedBox(height: 14),
                const ThreadStripe(height: 5, radius: 3),
                const SizedBox(height: 28),
                Text(s.welcomeTitle, style: text.titleLarge),
                const SizedBox(height: 6),
                Text(s.welcomeBody, style: text.bodyMedium?.copyWith(color: SutraColors.inkSoft)),
                const SizedBox(height: 28),
                LedgerCard(
                  padding: const EdgeInsets.fromLTRB(36, 18, 18, 18),
                  child: _sent == null ? _phoneStep(s) : _codeStep(s),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: text.bodyMedium?.copyWith(color: SutraColors.kumkum)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneStep(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]')), LengthLimitingTextInputFormatter(16)],
          style: SutraType.figure(22),
          decoration: InputDecoration(labelText: s.phoneLabel, prefixText: '+91  '),
          onSubmitted: (_) => _requestCode(),
        ),
        const SizedBox(height: 18),
        FilledButton(onPressed: _busy ? null : _requestCode, child: _busy ? const _Dots() : Text(s.sendCode)),
      ],
    );
  }

  Widget _codeStep(AppStrings s) {
    final sent = _sent!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(s.codeSentTo(sent.phone), style: Theme.of(context).textTheme.bodyMedium),
        if (sent.devOtpEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(s.devOtpHint('123456'), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SutraColors.neel)),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
          style: SutraType.figure(26).copyWith(letterSpacing: 10),
          decoration: InputDecoration(labelText: s.codeLabel),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 18),
        FilledButton(onPressed: _busy ? null : _verify, child: _busy ? const _Dots() : Text(s.verify)),
        TextButton(onPressed: _busy ? null : () => setState(() => _sent = null), child: Text(s.changeNumber)),
      ],
    );
  }
}

class _LangSwitch extends ConsumerWidget {
  const _LangSwitch({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = strings.isHindi ? AppLang.en : AppLang.hi;
    return TextButton.icon(
      onPressed: () => ref.read(langProvider.notifier).set(next),
      icon: const Icon(Icons.translate_rounded, size: 18),
      label: Text(next.label),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots();

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white));
}
