import '../../../core/l10n/app_strings.dart';

/// Onboarding phrases (Hindi first). Kept next to the feature that uses them.
abstract final class OnbText {
  static const welcomeTitle = T('चलिए, आपका बही-खाता बनाते हैं', "Let's set up your bahi-khata");
  static const welcomeBody = T('कुछ आसान सवाल, 3–4 मिनट। सब कुछ बाद में बदल सकते हैं।', 'A few easy questions, 3–4 minutes. You can change anything later.');
  static const howItWorks = T('Sutra आपके माल का पूरा सफ़र रखता है', 'Sutra keeps the whole journey of your goods');
  static const flowSupplier = T('सप्लायर', 'Supplier');
  static const flowRaw = T('कच्चा माल', 'Raw');
  static const flowMaking = T('बनाना', 'Making');
  static const flowReady = T('तैयार', 'Ready');
  static const flowClient = T('ग्राहक', 'Client');

  static const youTitle = T('आपके बारे में', 'About you');
  static const yourName = T('आपका नाम', 'Your name');
  static const businessName = T('दुकान / कारखाने का नाम', 'Business name');
  static const languageQ = T('ऐप किस भाषा में चलाएँ?', 'Which language for the app?');

  static const tradeTitle = T('आप क्या बनाते या बेचते हैं?', 'What do you make or sell?');
  static const howYouWork = T('आप कैसे काम करते हैं?', 'How do you work?');
  static const maker = T('मैं ख़ुद बनाता हूँ', 'I make goods');
  static const makerSub = T('कच्चा माल लेकर माल तैयार करते हैं', 'Buy raw material, make finished goods');
  static const trader = T('मैं ख़रीदकर बेचता हूँ', 'I buy and resell');
  static const traderSub = T('तैयार माल ख़रीदते और आगे बेचते हैं', 'Buy finished goods and sell them on');

  static const placeTitle = T('कहाँ से काम करते हैं?', 'Where do you work from?');
  static const city = T('शहर / क़स्बा', 'City / town');
  static const state = T('राज्य', 'State');
  static const capacityHint = T('इससे Sutra बताएगा कि आप कितना माल कब तक बना सकते हैं।', 'This lets Sutra tell buyers how much you can make, by when.');

  static const gstTitle = T('GST के बारे में', 'About GST');
  static const gstBody = T('सही बिल अपने आप बने, इसलिए पूछ रहे हैं।', 'So the right bill is made automatically.');
  static const gstRegular = T('GST लिया है (रेगुलर)', 'GST registered (regular)');
  static const gstRegularSub = T('टैक्स वाला बिल, दूसरे राज्य में भी बेच सकते हैं', 'Tax invoices; can sell to other states');
  static const gstComposition = T('कंपोज़िशन स्कीम', 'Composition scheme');
  static const gstCompositionSub = T('कम टैक्स, बिल ऑफ़ सप्लाई, सिर्फ़ अपने राज्य में', 'Lower tax, bill of supply, own state only');
  static const gstNone = T('GST नहीं लिया', 'Not registered');
  static const gstNoneSub = T('छोटा कारोबार, बाद में जोड़ सकते हैं', 'Small business; add it later');
  static const gstin = T('GSTIN (15 अक्षर)', 'GSTIN (15 characters)');
  static const gstinOk = T('GSTIN सही है', 'GSTIN looks right');
  static const gstinLength = T('15 अक्षर होने चाहिए', 'Must be 15 characters');
  static const gstinFormat = T('बनावट गलत है, जैसे 23ABCDE1234F1Z5', 'Wrong format, e.g. 23ABCDE1234F1Z5');
  static const gstinCheck = T('आख़िरी अक्षर मेल नहीं खाता, शायद टाइपिंग में गलती', 'Check digit does not match, likely a typo');
  static const gstinState = T('यह GSTIN दूसरे राज्य का है', 'This GSTIN belongs to another state');
  static const udyam = T('उद्यम नंबर (हो तो)', 'Udyam number (if any)');
  static const udyamHint = T('इससे बड़े ख़रीदारों से 45 दिन में भुगतान का हक़ दिखेगा', 'Shows your right to be paid within 45 days by business buyers');
  static const upi = T('UPI ID (हो तो)', 'UPI ID (if any)');
  static const upiHint = T('तक़ाज़े के मैसेज में पैसे भेजने का लिंक जुड़ेगा', 'Adds a pay link to payment reminders');

  static const materialsTitle = T('कच्चा माल', 'Raw material');
  static const materialsBody = T('जो इस्तेमाल करते हैं उन पर ✓ लगाएँ और अभी कितना पड़ा है, लिखें।', 'Tick what you use and write how much you have now.');
  static const inHand = T('अभी है', 'In hand');
  static const costPer = T('दाम', 'Cost');
  static const supplier = T('सप्लायर का नाम (हो तो)', 'Supplier name (if any)');
  static const supplierPhone = T('फ़ोन', 'Phone');

  static const productsTitle = T('आप क्या बेचते हैं?', 'What do you sell?');
  static const productsBody = T('दाम और अभी तैयार पड़ा माल लिखें।', 'Set the price and how many are ready now.');
  static const price = T('थोक दाम', 'Wholesale price');
  static const readyNow = T('तैयार पड़ा', 'Ready now');
  static const usesPerPiece = T('एक नग में लगता है', 'Each piece uses');

  static const teamTitle = T('आपके कारीगर', 'Your workers');
  static const teamBody = T('जिन्हें मज़दूरी देते हैं। अभी जोड़ें या बाद में।', 'People you pay wages to. Add now or later.');
  static const addWorker = T('कारीगर जोड़ें', 'Add worker');
  static const workerName = T('नाम', 'Name');
  static const noTeam = T('अभी कोई नहीं, कोई बात नहीं', 'No one yet, that is fine');
  static const wageDaily = T('रोज़ाना', 'Daily');
  static const wagePiece = T('नग के हिसाब से', 'Per piece');
  static const wageMonthly = T('महीने की तनख़्वाह', 'Monthly');
  static const perDay = T('प्रति दिन', 'per day');
  static const perPiece = T('प्रति नग', 'per piece');
  static const perMonth = T('प्रति माह', 'per month');

  static const doneTitle = T('सब तैयार है!', 'All set!');
  static const doneBody = T('आपका माल, खाता और कारीगर, अब एक धागे में।', 'Your goods, khata and team, now on one thread.');
  static const next = T('आगे', 'Next');
  static const back = T('पीछे', 'Back');
  static const start = T('शुरू करें', 'Start');
  static const materials = T('कच्चा माल', 'materials');
  static const products = T('माल', 'products');
  static const workers = T('कारीगर', 'workers');
}
