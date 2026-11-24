import 'app_strings.dart';

class EnglishStrings extends AppStrings {
  const EnglishStrings();

  @override
  AppLang get lang => AppLang.en;

  @override
  String get tagline => 'One thread for the whole business';
  @override
  String get listen => 'Listen';
  @override
  String get retry => 'Try again';
  @override
  String get cancel => 'Cancel';
  @override
  String get somethingWrong => 'Something went wrong';

  @override
  String get welcomeTitle => 'Your bahi-khata, now on your phone';
  @override
  String get welcomeBody => 'Speak or take a photo — stock, GST and khata update on their own.';
  @override
  String get phoneLabel => 'Mobile number';
  @override
  String get sendCode => 'Send code';
  @override
  String get codeLabel => '6-digit code';
  @override
  String codeSentTo(String phone) => 'Code sent to $phone';
  @override
  String get verify => 'Continue';
  @override
  String get changeNumber => 'Change number';
  @override
  String devOtpHint(String code) => 'Test code: $code';
  @override
  String get consentTitle => 'Your data, your choice';
  @override
  List<String> get consentPoints => const [
        'We keep your mobile number only to log you in.',
        'Stock, bills and khata are used only for your bookkeeping and selling.',
        'Buyers see only what you publish in your catalog.',
        'We never sell your data.',
        'You can download your data or close your account at any time.',
      ];
  @override
  String get consentAgree => 'I understand, continue';

  @override
  String get navHome => 'Today';
  @override
  String get navStock => 'Stock';
  @override
  String get navVoice => 'Speak';
  @override
  String get navKhata => 'Khata';
  @override
  String get navProfile => 'Me';

  @override
  String get needsAttention => 'Needs attention';
  @override
  String get todaysPage => "Today's page";
  @override
  String get kpiSales30 => 'Sales, last 30 days';
  @override
  String invoicesCount(int n) => n == 1 ? '1 invoice' : '$n invoices';
  @override
  String get kpiStockValue => 'Stock value';
  @override
  String get kpiStockValueSub => 'raw + finished';
  @override
  String get kpiToReceive => 'To receive';
  @override
  String get kpiToPay => 'To pay';
  @override
  String get kpiOpenOrders => 'Open orders';
  @override
  String newRequests(int n) => switch (n) {
        0 => 'no new requests',
        1 => '1 new request',
        _ => '$n new requests',
      };
  @override
  String get rawMaterial => 'Raw material';
  @override
  String get seeAll => 'See all';
  @override
  String get speakCta => 'Speak an entry';

  @override
  String get stockTitle => "What's running low?";
  @override
  String get rawTab => 'Raw material';
  @override
  String get finishedTab => 'Finished goods';
  @override
  String lastsDays(int days) => 'lasts $days days';
  @override
  String get notInUse => 'not in use';
  @override
  String reorderBy(String date) => 'reorder by $date';
  @override
  String get statusCritical => 'Out soon';
  @override
  String get statusLow => 'Low';
  @override
  String get statusOk => 'OK';
  @override
  String get reorder => 'Reorder';
  @override
  String get reorderTitle => 'Order from supplier';
  @override
  String supplierTakes(String supplier, int days) => '$supplier · delivers in $days days';
  @override
  String get quantity => 'Quantity';
  @override
  String get sendOnWhatsApp => 'Send on WhatsApp';
  @override
  String reorderSent(String eta) => 'Order sent. Expected by $eta.';
  @override
  String get ready => 'ready';
  @override
  String get wholesale => 'wholesale';

  @override
  String get voiceTitle => 'Speak an entry';
  @override
  String get tapToSpeak => 'Tap the charkha and speak';
  @override
  String get listening => 'Listening… speak now';
  @override
  String get micUnavailable => 'The mic is not available here. Type below instead.';
  @override
  String get typeHere => 'Or type here…';
  @override
  String get understand => 'Go';
  @override
  String get shallIWrite => 'Shall I write this?';
  @override
  String get wrong => 'Wrong';
  @override
  String get yesWrite => 'Yes, write it';
  @override
  String get written => 'Written';
  @override
  String get kindMade => 'MADE';
  @override
  String get kindSold => 'SOLD';
  @override
  String get kindBought => 'IN';
  @override
  String get kindMoney => 'MONEY';
  @override
  String get tryThese => 'Try saying';
  @override
  String get cannotSave => "This can't be saved";
  @override
  String get readBy => 'Sutra understood';

  @override
  String get khataTitle => 'Who owes what?';
  @override
  String get toReceive => 'To receive';
  @override
  String get toPay => 'To pay';
  @override
  String get openTab => 'Open';
  @override
  String get settledTab => 'Settled';
  @override
  String dueOn(String date) => 'due $date';
  @override
  String overdueDays(int n) => '$n days late';
  @override
  String msmeDaysLeft(int n) => n >= 0 ? 'MSME 45-day: $n days left' : 'MSME 45-day limit passed';
  @override
  String get remind => 'Remind';
  @override
  String get settle => 'Settle';
  @override
  String settleConfirm(String party, String amount) => 'Mark $amount from $party as settled?';
  @override
  String get nothingHere => 'Nothing here yet';
  @override
  String get stampDue => 'DUE';
  @override
  String get stampPaid => 'PAID';

  @override
  String get profileTitle => 'My business';
  @override
  String get language => 'Language';
  @override
  String get gstScheme => 'GST';
  @override
  String schemeName(String scheme) => switch (scheme) {
        'COMPOSITION' => 'Composition scheme',
        'UNREGISTERED' => 'Not registered',
        _ => 'Regular GST',
      };
  @override
  String get udyam => 'Udyam number';
  @override
  String get notAdded => 'Not added';
  @override
  String machinesOf(int n, String machineWordHi, String machineWordEn) => '$n ${machineWordEn}s';
  @override
  String get logout => 'Log out';
  @override
  String get privacy => 'Your data';
}
