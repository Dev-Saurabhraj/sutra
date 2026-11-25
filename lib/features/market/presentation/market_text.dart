import '../../../core/l10n/app_strings.dart';

abstract final class MarketText {
  // shell
  static const navBazaar = T('बाज़ार', 'Bazaar');
  static const navOrders = T('मेरे ऑर्डर', 'My orders');
  static const navAccount = T('खाता', 'Account');

  // bazaar
  static const bazaarTitle = T('सीधे कारीगर से', 'Straight from the maker');
  static const bazaarSub = T('हर दाम कारीगर का अपना है। "दे सकते हैं" में असली स्टॉक और हफ़्ते का काम दिखता है।',
      'Every price is the maker\'s own. "Can deliver" shows real stock and this week\'s capacity.');
  static const search = T('साड़ी, दीया, शहर, कारीगर…', 'Saree, diya, city, maker…');
  static const all = T('सब', 'All');
  static const nothing = T('इन फ़िल्टर में कुछ नहीं मिला।', 'Nothing matches these filters.');
  static const ready = T('तैयार', 'ready');
  static const perWeek = T('हफ़्ते में', '/week');
  static const slowWeek = T('इस हफ़्ते छुट्टी', 'days off this week');
  static const onTime = T('समय पर', 'on time');

  // product
  static const about = T('इसके बारे में', 'About this piece');
  static const mrp = T('MRP', 'MRP');
  static const wholesale = T('थोक दाम, GST अलग', 'Wholesale, GST extra');
  static const askQuote = T('कितने, कब तक?', 'How many, by when?');
  static const qty = T('कितने पीस', 'Pieces');
  static const wantedBy = T('कब तक चाहिए', 'Wanted by');
  static const check = T('देखें कौन दे सकता है', 'Check who can deliver');
  static const checking = T('हिसाब लग रहा है…', 'Working it out…');
  static const moreFromMaker = T('इसी कारीगर से और', 'More from this maker');

  // quote
  static const answer = T('सच्चा जवाब', 'The honest answer');
  static const allInTime = T('सब समय पर', 'All in time');
  static const partInTime = T('कुछ समय पर', 'Part in time');
  static const notInTime = T('समय पर नहीं', 'Not in time');
  static const byYourDate = T('आपकी तारीख़ तक', 'By your date');
  static const allBy = T('पूरे कब तक', 'All of it by');
  static const countedDaysOff = T('कारीगर की छुट्टियाँ गिनी गईं', 'The maker\'s days off are counted');
  static const sameEngine = T('यही हिसाब कारीगर को भी दिखता है।', 'The maker sees exactly this answer too.');
  static const taxable = T('दाम', 'Value');
  static const gst = T('GST', 'GST');
  static const igst = T('IGST (दूसरा राज्य)', 'IGST (other state)');
  static const cgstSgst = T('CGST + SGST', 'CGST + SGST');
  static const noGst = T('बिल ऑफ़ सप्लाई (GST नहीं)', 'Bill of supply (no GST)');
  static const total = T('कुल', 'Total');
  static const cannotSell = T('यह कारीगर आपके राज्य में नहीं बेच सकता', 'This maker can\'t sell to your state');
  static const clusterTitle = T('क्लस्टर मिलकर बनाए', 'Let the cluster share it');
  static const clusterSub = T('एक कारीगर तारीख़ तक नहीं बना सकता; उसी क्लस्टर के दूसरे कारीगर बाकी बनाएँगे। हर कारीगर का अलग प्रोफ़ॉर्मा।',
      'One maker can\'t make it all by your date; makers in the same cluster share the rest. A proforma from each.');
  static const covered = T('तारीख़ तक', 'by your date');
  static const beforeGst = T('GST से पहले', 'before GST');
  static const pieces = T('पीस', 'pcs');
  static const note = T('कारीगर के लिए नोट (अंग्रेज़ी ठीक है, हिंदी में पहुँचेगा)', 'Note for the maker (they read it in Hindi)');
  static const requestOne = T('इस कारीगर से माँगें', 'Request from this maker');
  static const requestSplit = T('क्लस्टर से माँगें', 'Request from the cluster');
  static const requested = T('माँग भेज दी', 'Request sent');
  static const requestedSub = T('हर कारीगर देखकर हाँ या ना कहेगा। प्रोफ़ॉर्मा अभी देख सकते हैं।', 'Each maker checks and accepts or declines. Your proformas are ready now.');
  static const seeOrders = T('मेरे ऑर्डर देखें', 'See my orders');
  static const proforma = T('प्रोफ़ॉर्मा', 'Proforma');

  // trust
  static const trust = T('भरोसा', 'Trust');
  static const gstinChecked = T('GSTIN का फ़ॉर्मेट सही', 'GSTIN format checked');
  static const gstinNote = T('चेकसम जाँचा; सरकारी स्थिति अभी नहीं', 'Checksum verified; live status not yet');
  static const unregistered = T('GST में पंजीकृत नहीं', 'Not GST-registered');
  static const composition = T('कंपोज़िशन स्कीम', 'Composition scheme');
  static const udyam = T('उद्यम (MSME) पंजीकृत', 'Udyam (MSME) registered');
  static const ordersDone = T('ऑर्डर पूरे', 'orders done');
  static const onTimeRate = T('समय पर पहुँचे', 'delivered on time');
  static const since = T('Sutra पर', 'On Sutra since');
  static const looms = T('मशीन/करघे', 'machines');
  static const theirWords = T('उनकी कहानी', 'Their story');
  static const allProducts = T('सारे उत्पाद', 'All products');

  // orders
  static const myOrders = T('मेरे ऑर्डर', 'My orders');
  static const noOrders = T('अभी कोई ऑर्डर नहीं। बाज़ार में कोई चीज़ चुनें और पूछें।', 'No orders yet. Pick something in the bazaar and ask.');
  static const stageAsked = T('माँगा', 'Requested');
  static const stageMaking = T('बन रहा', 'Making');
  static const stageSent = T('भेजा', 'Shipped');
  static const stageReached = T('पहुँचा', 'Delivered');
  static const declined = T('मना हुआ', 'Declined');
  static const partOf = T('एक माँग, कई कारीगर', 'One request, several makers');
  static const promise = T('कारीगर का वादा', 'Maker\'s promise');
  static const shipped = T('रवाना', 'Shipped');
  static const proof = T('पैकिंग की फ़ोटो', 'Photo of the packed goods');
  static const documents = T('काग़ज़', 'Documents');
  static const letters = T('कारीगर से बात', 'Talk to the maker');
  static const write = T('लिखें (कारीगर हिंदी में पढ़ेंगे)', 'Write (the maker reads it in Hindi)');
  static const translatedFromHindi = T('हिंदी से अनुवाद', 'translated from Hindi');
  static const notTranslated = T('अनुवाद बंद, जैसा लिखा', 'not translated; as written');
  static const original = T('असली देखें', 'Show original');
  static const you = T('आप', 'You');

  // account
  static const yourBusiness = T('आपका कारोबार', 'Your business');
  static const buyerGstinMissing = T('GSTIN नहीं जोड़ा: बिल B2C बनेंगे, टैक्स क्रेडिट नहीं मिलेगा', 'No GSTIN: invoices will be B2C and you can\'t claim tax credit');

  // onboarding
  static const roleTitle = T('आप Sutra पर क्या करेंगे?', 'What brings you to Sutra?');
  static const roleMaker = T('मैं बनाता / बेचता हूँ', 'I make or sell');
  static const roleMakerSub = T('स्टॉक, कारीगर, GST बिल, ऑर्डर', 'Stock, workers, GST bills, orders');
  static const roleBuyer = T('मैं दुकान के लिए ख़रीदता हूँ', 'I buy for my shop');
  static const roleBuyerSub = T('बुटीक, दुकान, निर्यातक: सीधे कारीगर से', 'Boutiques, stores, exporters: straight from makers');
  static const buyerTitle = T('आपकी दुकान', 'Your shop');
  static const buyerBody = T('चार बातें, फिर बाज़ार खुल जाएगा।', 'Four things, then the bazaar opens.');
  static const yourName = T('आपका नाम', 'Your name');
  static const business = T('दुकान / कंपनी का नाम', 'Shop or company name');
  static const city = T('शहर', 'City');
  static const state = T('राज्य', 'State');
  static const gstin = T('GSTIN (हो तो)', 'GSTIN (if you have one)');
  static const gstinWhy = T('GSTIN से टैक्स क्रेडिट मिलता है; राज्य से तय होता है कि IGST लगेगा या CGST+SGST।',
      'A GSTIN lets you claim tax credit; your state decides IGST or CGST + SGST.');
  static const openBazaar = T('बाज़ार खोलें', 'Open the bazaar');
  static const back = T('पीछे', 'Back');
}

/// Quality marks a maker can hold, in words.
String markLabel(AppStrings s, String code) => switch (code) {
      'HANDLOOM_MARK' => s.pick('हैंडलूम मार्क', 'Handloom Mark'),
      'SILK_MARK' => s.pick('सिल्क मार्क', 'Silk Mark'),
      'GI_CHANDERI' => s.pick('GI: चंदेरी साड़ी', 'GI: Chanderi Sarees'),
      'GI_MORADABAD_METAL' => s.pick('GI: मुरादाबाद धातु शिल्प', 'GI: Moradabad Metal Craft'),
      'CRAFTMARK' => 'Craftmark',
      _ => code.replaceAll('_', ' '),
    };
