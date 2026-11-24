import 'strings_en.dart';
import 'strings_hi.dart';

enum AppLang {
  hi('hi', 'हिंदी'),
  en('en', 'English');

  const AppLang(this.code, this.label);
  final String code;
  final String label;

  static AppLang fromCode(String? code) => code == 'en' ? AppLang.en : AppLang.hi;
}

/// A phrase in every supported language. Feature screens keep their own catalogs of these
/// (e.g. `OnboardingText.welcome`) so strings live next to the feature that uses them.
/// Adding a language = add a field here with a fallback to English.
class T {
  const T(this.hi, this.en);
  final String hi;
  final String en;
}

/// Every user-facing string. One implementation per language (add Tamil = add a class).
abstract class AppStrings {
  const AppStrings();

  /// Resolve a feature-catalog phrase in the current language.
  String tr(T phrase) => switch (lang) {
        AppLang.hi => phrase.hi,
        AppLang.en => phrase.en,
      };

  static AppStrings of(AppLang lang) => switch (lang) {
        AppLang.hi => const HindiStrings(),
        AppLang.en => const EnglishStrings(),
      };

  AppLang get lang;
  bool get isHindi => lang == AppLang.hi;

  /// Pick the right half of bilingual data coming from the API.
  String pick(String hi, String en) => isHindi ? hi : en;

  // common
  String get appName => 'Sutra';
  String get tagline;
  String get listen;
  String get retry;
  String get cancel;
  String get somethingWrong;

  // login + consent
  String get welcomeTitle;
  String get welcomeBody;
  String get phoneLabel;
  String get sendCode;
  String get codeLabel;
  String codeSentTo(String phone);
  String get verify;
  String get changeNumber;
  String devOtpHint(String code);
  String get consentTitle;
  List<String> get consentPoints;
  String get consentAgree;

  // navigation
  String get navHome;
  String get navStock;
  String get navVoice;
  String get navKhata;
  String get navProfile;

  // home
  String get needsAttention;
  String get todaysPage;
  String get kpiSales30;
  String invoicesCount(int n);
  String get kpiStockValue;
  String get kpiStockValueSub;
  String get kpiToReceive;
  String get kpiToPay;
  String get kpiOpenOrders;
  String newRequests(int n);
  String get rawMaterial;
  String get seeAll;
  String get speakCta;

  // stock
  String get stockTitle;
  String get rawTab;
  String get finishedTab;
  String lastsDays(int days);
  String get notInUse;
  String reorderBy(String date);
  String get statusCritical;
  String get statusLow;
  String get statusOk;
  String get reorder;
  String get reorderTitle;
  String supplierTakes(String supplier, int days);
  String get quantity;
  String get sendOnWhatsApp;
  String reorderSent(String eta);
  String get ready;
  String get wholesale;

  // voice
  String get voiceTitle;
  String get tapToSpeak;
  String get listening;
  String get micUnavailable;
  String get typeHere;
  String get understand;
  String get shallIWrite;
  String get wrong;
  String get yesWrite;
  String get written;
  String get kindMade;
  String get kindSold;
  String get kindBought;
  String get kindMoney;
  String get tryThese;
  String get cannotSave;
  String get readBy;

  // khata
  String get khataTitle;
  String get toReceive;
  String get toPay;
  String get openTab;
  String get settledTab;
  String dueOn(String date);
  String overdueDays(int n);
  String msmeDaysLeft(int n);
  String get remind;
  String get settle;
  String settleConfirm(String party, String amount);
  String get nothingHere;
  String get stampDue;
  String get stampPaid;

  // profile
  String get profileTitle;
  String get language;
  String get gstScheme;
  String schemeName(String scheme);
  String get udyam;
  String get notAdded;
  String machinesOf(int n, String machineWordHi, String machineWordEn);
  String get logout;
  String get privacy;
}
