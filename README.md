# Sutra — Flutter app

The producer app (Hindi-first, voice-first). Talks to the API in [`../backend`](../backend).

## Run

```bash
flutter pub get
# start the backend first (see ../backend/README.md)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000        # Android emulator
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
```

On a physical phone, use your computer's LAN IP, e.g. `http://192.168.1.20:4000`.
Demo login: `98000 00001` with dev code `123456`.

Checks: `flutter analyze` · `flutter test`.

## Structure

```
lib/
  main.dart                 boot: date formats, shared prefs, ProviderScope
  app/                      SutraApp, router (session-driven redirects), providers (composition root)
  core/                     config, ApiClient (token refresh, idempotency keys), ApiException,
                            TokenStore (secure storage), l10n (AppStrings: Hindi + English), formatters,
                            device services behind interfaces (VoiceInput, Speaker, LinkLauncher)
  design/                   "Bahi" design system — tokens, type, theme, and signature widgets:
                            ThreadStripe · LedgerCard/LedgerLine · Stamp · SpoolGauge · CharkhaMic ·
                            WovenNavBar · Parchi · AmountText · WovenSwatch · AsyncView
  features/<feature>/
    domain/                 models + repository interface (no Flutter, no HTTP)
    data/                   HTTP implementation + Riverpod providers
    presentation/           screens and controllers
```

Features in Phase 1: `auth` (OTP login, DPDP consent) · `home` (Aaj) · `stock` (spools, reorder) · `voice`
(speak → preview → confirm) · `khata` (ledger, MSME clock, reminders) · `profile` · `alerts` · `shell` (woven nav).

## Rules that matter here

- UI depends on `domain/` interfaces; only `data/` knows about Dio and JSON.
- Every string lives in `AppStrings`; screens never hard-code text. API data comes bilingual: use `strings.pick(hi, en)`.
- Nothing typed by AI is saved without the user's "हाँ, लिख दो".
- See [`../docs/DESIGN.md`](../docs/DESIGN.md) before adding UI, and [`../docs/RULES.md`](../docs/RULES.md) for everything else.

## Known gaps (tracked in the root README)

- Fonts load from Google Fonts at runtime; bundle them as assets for offline use (Phase 1 polish).
- Speech recognition needs Google speech services on Android; the typed box is the fallback.
- No offline queue yet (Phase 6).
