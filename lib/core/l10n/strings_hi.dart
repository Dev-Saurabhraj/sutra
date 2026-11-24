import 'app_strings.dart';

class HindiStrings extends AppStrings {
  const HindiStrings();

  @override
  AppLang get lang => AppLang.hi;

  @override
  String get tagline => 'एक धागा, पूरा कारोबार';
  @override
  String get listen => 'सुनें';
  @override
  String get retry => 'फिर कोशिश करें';
  @override
  String get cancel => 'रहने दें';
  @override
  String get somethingWrong => 'कुछ गड़बड़ हो गई';

  @override
  String get welcomeTitle => 'आपका बही-खाता, अब फ़ोन में';
  @override
  String get welcomeBody => 'बोलिए, फ़ोटो लीजिए — स्टॉक, GST और खाता अपने आप।';
  @override
  String get phoneLabel => 'मोबाइल नंबर';
  @override
  String get sendCode => 'कोड भेजें';
  @override
  String get codeLabel => '6 अंकों का कोड';
  @override
  String codeSentTo(String phone) => '$phone पर कोड भेजा है';
  @override
  String get verify => 'आगे बढ़ें';
  @override
  String get changeNumber => 'नंबर बदलें';
  @override
  String devOtpHint(String code) => 'टेस्ट के लिए कोड: $code';
  @override
  String get consentTitle => 'आपकी जानकारी, आपकी मर्ज़ी';
  @override
  List<String> get consentPoints => const [
        'हम आपका मोबाइल नंबर सिर्फ़ लॉगिन के लिए रखते हैं।',
        'स्टॉक, बिल और खाता सिर्फ़ आपके कारोबार के हिसाब-किताब और बिक्री के लिए हैं।',
        'खरीदार सिर्फ़ वही देखते हैं जो आप कैटलॉग में डालते हैं।',
        'हम आपकी जानकारी किसी को नहीं बेचते।',
        'आप कभी भी अपना डेटा डाउनलोड या खाता बंद करवा सकते हैं।',
      ];
  @override
  String get consentAgree => 'समझ गया, आगे बढ़ें';

  @override
  String get navHome => 'आज';
  @override
  String get navStock => 'स्टॉक';
  @override
  String get navVoice => 'बोलें';
  @override
  String get navKhata => 'खाता';
  @override
  String get navProfile => 'मैं';

  @override
  String get needsAttention => 'ज़रूरी बातें';
  @override
  String get todaysPage => 'आज का पन्ना';
  @override
  String get kpiSales30 => '30 दिन की बिक्री';
  @override
  String invoicesCount(int n) => '$n बिल';
  @override
  String get kpiStockValue => 'माल की कीमत';
  @override
  String get kpiStockValueSub => 'कच्चा + तैयार';
  @override
  String get kpiToReceive => 'लेना है';
  @override
  String get kpiToPay => 'देना है';
  @override
  String get kpiOpenOrders => 'चालू ऑर्डर';
  @override
  String newRequests(int n) => n == 0 ? 'कोई नई माँग नहीं' : '$n नई माँग';
  @override
  String get rawMaterial => 'कच्चा माल';
  @override
  String get seeAll => 'सब देखें';
  @override
  String get speakCta => 'बोलकर लिखें';
  @override
  String get speakCtaSub => '“आज 6 साड़ी बनी, 4 जयपुर भेजी”';

  @override
  String get stockTitle => 'क्या कम है?';
  @override
  String get rawTab => 'कच्चा माल';
  @override
  String get finishedTab => 'तैयार माल';
  @override
  String lastsDays(int days) => '$days दिन चलेगा';
  @override
  String get notInUse => 'अभी इस्तेमाल नहीं';
  @override
  String reorderBy(String date) => '$date तक मँगवाएँ';
  @override
  String get statusCritical => 'ख़त्म';
  @override
  String get statusLow => 'कम';
  @override
  String get statusOk => 'ठीक';
  @override
  String get reorder => 'मँगवाएँ';
  @override
  String get reorderTitle => 'सप्लायर को ऑर्डर';
  @override
  String supplierTakes(String supplier, int days) => '$supplier · $days दिन में पहुँचता है';
  @override
  String get quantity => 'कितना';
  @override
  String get sendOnWhatsApp => 'WhatsApp पर भेजें';
  @override
  String reorderSent(String eta) => 'ऑर्डर भेजा। $eta तक आने की उम्मीद।';
  @override
  String get ready => 'तैयार';
  @override
  String get wholesale => 'थोक दाम';

  @override
  String get voiceTitle => 'बोलकर लिखें';
  @override
  String get tapToSpeak => 'चरखा दबाएँ और बोलें';
  @override
  String get listening => 'सुन रहे हैं… बोलिए';
  @override
  String get micUnavailable => 'इस फ़ोन में माइक नहीं चला। नीचे लिख दें।';
  @override
  String get typeHere => 'या यहाँ लिखें…';
  @override
  String get understand => 'समझो';
  @override
  String get shallIWrite => 'यह लिखूँ?';
  @override
  String get wrong => 'गलत है';
  @override
  String get yesWrite => 'हाँ, लिख दो';
  @override
  String get written => 'लिख लिया';
  @override
  String get kindMade => 'बना';
  @override
  String get kindSold => 'बिका';
  @override
  String get kindBought => 'आया';
  @override
  String get kindMoney => 'पैसा';
  @override
  String get tryThese => 'ऐसे बोलें';
  @override
  String get cannotSave => 'इसे लिख नहीं सकते';
  @override
  String get readBy => 'Sutra ने समझा';

  @override
  String get khataTitle => 'किसका बाकी है?';
  @override
  String get toReceive => 'लेना';
  @override
  String get toPay => 'देना';
  @override
  String get openTab => 'बाकी';
  @override
  String get settledTab => 'चुकता';
  @override
  String dueOn(String date) => '$date तक';
  @override
  String overdueDays(int n) => '$n दिन ऊपर';
  @override
  String msmeDaysLeft(int n) => n >= 0 ? 'MSME 45 दिन: $n दिन बचे' : 'MSME 45 दिन पार';
  @override
  String get remind => 'याद दिलाएँ';
  @override
  String get settle => 'चुकता करें';
  @override
  String settleConfirm(String party, String amount) => '$party का $amount चुकता मान लें?';
  @override
  String get nothingHere => 'यहाँ अभी कुछ नहीं है';
  @override
  String get stampDue => 'बाकी';
  @override
  String get stampPaid => 'चुकता';

  @override
  String get profileTitle => 'मेरा कारोबार';
  @override
  String get language => 'भाषा';
  @override
  String get gstScheme => 'GST';
  @override
  String schemeName(String scheme) => switch (scheme) {
        'COMPOSITION' => 'कंपोज़िशन स्कीम',
        'UNREGISTERED' => 'GST नहीं लिया',
        _ => 'रेगुलर GST',
      };
  @override
  String get udyam => 'उद्यम नंबर';
  @override
  String get notAdded => 'नहीं जोड़ा';
  @override
  String machinesOf(int n, String machineWordHi, String machineWordEn) => '$n $machineWordHi';
  @override
  String get logout => 'लॉग आउट';
  @override
  String get privacy => 'आपकी जानकारी';
}
