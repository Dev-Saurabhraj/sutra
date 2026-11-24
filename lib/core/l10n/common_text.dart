import 'app_strings.dart';

/// Phrases shared by many features (Phase 6–7 additions).
abstract final class CommonText {
  // P27 offline outbox
  static const savedOffline = T('नेट नहीं है: फ़ोन में सेव किया, नेट आते ही भेज देंगे', 'No network: saved on the phone, it will go out when you\'re online');
  static const waiting = T('फ़ोन में रुकी एंट्री', 'entries waiting on the phone');
  static const sendNow = T('अभी भेजें', 'Send now');
  static const sent = T('भेज दीं', 'sent');

  // X5 spoken alerts
  static const voiceAlerts = T('नए अलर्ट बोलकर सुनाएँ', 'Read new alerts aloud');
  static const voiceAlertsSub = T('नया ऑर्डर, कम स्टॉक, महँगा माल: ऐप खुला हो तो बोलकर बताएगा', 'New orders, low stock, price rises: spoken while the app is open');
  static const open = T('खोलें', 'Open');

  // X4 privacy
  static const myData = T('मेरा डेटा', 'My data');
  static const download = T('सारा डेटा डाउनलोड करें', 'Download all my data');
  static const deleteAccount = T('खाता मिटाएँ', 'Delete my account');
  static const deleteSure = T('खाता हमेशा के लिए मिटाएँ?', 'Delete your account for good?');
  static const deleteBody = T('लॉगिन, नाम, फ़ोन और कहानी मिट जाएगी, आपका सामान बाज़ार से हट जाएगा। GST क़ानून के कारण टैक्स बिल 6 साल रखे जाते हैं।',
      'Your login, name, phone and story are erased and your products leave the bazaar. Tax invoices are kept for 6 years as GST law requires.');
  static const deleteYes = T('हाँ, मिटाएँ', 'Yes, delete');

  // P26 munim (helper) mode
  static const helperMode = T('मुनीम मोड', 'Helper (munim) mode');
  static const helperSub = T('घर के किसी सदस्य या मुनीम को फ़ोन दें: वे माल और बोलकर एंट्री कर सकेंगे, पैसे, खाता, GST और मज़दूरी नहीं दिखेंगे।',
      'Hand the phone to a helper: they can record goods and voice entries, but money, khata, GST and wages stay hidden.');
  static const setPin = T('मालिक का 4 अंकों का PIN रखें', 'Set a 4-digit owner PIN');
  static const enterPin = T('मालिक का PIN', 'Owner PIN');
  static const startHelper = T('मुनीम मोड चालू करें', 'Start helper mode');
  static const helperOn = T('मुनीम मोड चालू', 'Helper mode on');
  static const unlock = T('मालिक: खोलें', 'Owner: unlock');
  static const wrongPin = T('PIN ग़लत है', 'Wrong PIN');
  static const helperNoMoney = T('मुनीम मोड में पैसे और मज़दूरी की एंट्री मालिक ही करेंगे', 'In helper mode, payments and wages are for the owner to record');

  // P25 price watch
  static const prices = T('माल के दाम', 'Material prices');
  static const pricesSub = T('हर बिल से दाम लिखे जाते हैं। कोई सप्लायर दाम बढ़ाए तो अलर्ट आता है।', 'Every bill records a rate. If a supplier raises it, you get an alert.');
  static const now = T('अभी', 'Now');
  static const cheapest = T('सबसे सस्ता', 'Cheapest');
  static const lastRates = T('पिछले दाम', 'Recent rates');
  static const per = T('प्रति', 'per');
  static const noBills = T('अभी कोई बिल नहीं', 'No bills yet');
}
