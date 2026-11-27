import '../../../core/l10n/app_strings.dart';

/// Bilingual strings for the FTA feature, kept next to the screen that uses them.
abstract final class FtaText {
  static const title = T('FTA लाभ', 'FTA benefits');
  static const titleSub = T(
    'FTA में आपको अलग से "आवेदन" नहीं करना पड़ता। फ़ायदा तब मिलता है जब आप माल भेजते हैं: उद्गम प्रमाणपत्र (Certificate of Origin) से ख़रीदार के देश में कम या शून्य ड्यूटी लगती है।',
    'You do not apply for an FTA separately. The benefit comes when you ship: a Certificate of Origin lets your buyer pay less — often zero — import duty.',
  );

  // how it works
  static const howItWorks = T('यह कैसे काम करता है', 'How it works');
  static const step1 = T('पहले सामान "भारत में बना" साबित करना होता है — यही उद्गम नियम (Rules of Origin) है।', 'First your goods must qualify as "made in India" — the Rules of Origin.');
  static const step2 = T('हर खेप पर उद्गम प्रमाणपत्र लिया जाता है: DGFT के एक पोर्टल (e-CoO) पर, सबके लिए एक ही ऑनलाइन रास्ता।', 'Each consignment gets a Certificate of Origin: one online route on DGFT\'s e-CoO portal.');
  static const step3 = T('एक बार "अनुमोदित निर्यातक" (Approved Exporter) बन जाएँ, तो खुद प्रमाणपत्र जारी कर सकते हैं — बार-बार आवेदन नहीं।', 'Become an "Approved Exporter" once and self-certify every shipment — no repeated application.');

  // destination checker
  static const destinationTitle = T('किस देश को माल भेजना है?', 'Where are you exporting?');
  static const destinationLabel = T('देश चुनें', 'Choose a destination');
  static const destinationHint = T('ऊपर से देश चुनें — हम बताएँगे कौन-सा FTA लागू होता है।', 'Pick a destination above to see which FTA applies.');
  static const applies = T('यह FTA लागू होता है', 'This FTA applies');
  static const coverageLabel = T('क्या छूट मिलती है', 'What it covers');
  static const valueAddLabel = T('आम नियम: कम से कम इतना भारतीय मूल्य', 'Typical rule: minimum Indian value added');
  static const valueAddNote = T('यह अंदाज़ा है — असली शर्त हर उत्पाद (HS कोड) के हिसाब से अलग होती है।', 'This is a guide — the exact rule depends on your product\'s HS code.');
  static const inForce = T('लागू है', 'In force');
  static const signed = T('हस्ताक्षरित', 'Signed');

  // estimator
  static const estimatorTitle = T('कितनी ड्यूटी बचेगी?', 'How much duty will you save?');
  static const invoiceValue = T('खेप की कीमत (₹)', 'Consignment value (₹)');
  static const normalRate = T('बिना FTA ड्यूटी (%)', 'Duty without FTA (%)');
  static const prefRate = T('FTA से ड्यूटी (%)', 'Duty with FTA (%)');
  static const normalDuty = T('बिना FTA ड्यूटी', 'Duty without FTA');
  static const prefDuty = T('FTA से ड्यूटी', 'Duty with FTA');
  static const youSave = T('हर खेप पर बचत', 'You save per consignment');
  static const estimatorHint = T('तीनों खाने भरें — बचत खुद निकल आएगी।', 'Fill all three boxes and the saving works itself out.');
  static const estimatorNote = T('यह सिर्फ़ अनुमान है; असली दर ख़रीदार के देश के कस्टम और आपके HS कोड पर तय होती है।', 'An estimate only; the real rate depends on the buyer\'s customs and your HS code.');

  // rules of origin
  static const rulesTitle = T('उद्गम नियम (Rules of Origin)', 'Rules of Origin');
  static const rulesNote = T(
    'आम तौर पर दो रास्तों में से एक चाहिए: माल की कीमत का एक हिस्सा भारत में जुड़ा हो (मूल्य-वृद्धि), या प्रोसेसिंग से उसका HS कोड बदल जाए। यह उत्पाद-विशिष्ट है।',
    'Usually one of two tests: a share of the value is added in India (value addition), or processing changes the HS code. It is product-specific.',
  );

  // checklist
  static const checklistTitle = T('पहली खेप के लिए क्या चाहिए', 'What you need for the first shipment');
  static const checklist = <T>[
    T('IEC — आयात-निर्यात कोड (DGFT से, एक बार)', 'IEC — Import Export Code (from DGFT, once)'),
    T('चालू GSTIN', 'Active GSTIN'),
    T('उद्यम (MSME) पंजीकरण', 'Udyam (MSME) registration'),
    T('कमर्शियल इनवॉइस और पैकिंग लिस्ट', 'Commercial invoice and packing list'),
    T('उत्पाद का HS कोड', 'Your product\'s HS code'),
    T('लागत-पत्र / मूल्य-वृद्धि का हिसाब', 'Cost sheet / value-addition working'),
    T('उद्गम प्रमाणपत्र — e-CoO पोर्टल पर', 'Certificate of Origin — on the e-CoO portal'),
  ];

  // apply
  static const applyTitle = T('कहाँ से करें', 'Where to apply');
  static const eCoo = T('DGFT e-CoO पोर्टल खोलें', 'Open the DGFT e-CoO portal');
  static const approvedExporter = T('अनुमोदित निर्यातक योजना (स्व-प्रमाणन)', 'Approved Exporter scheme (self-certification)');
  static const dgft = T('DGFT की वेबसाइट', 'DGFT website');

  // footer
  static const footer = T(
    'Sutra सिर्फ़ रास्ता दिखाता है — असली प्रमाणपत्र और दरें DGFT / कस्टम तय करते हैं। जटिल मामले में अपने CHA या निर्यात सलाहकार से पूछें।',
    'Sutra only shows the way — the actual certificate and rates come from DGFT / customs. Ask your CHA or export advisor for complex cases.',
  );
}
