import '../../core/l10n/app_strings.dart';

abstract final class MoneyText {
  // B8 advance
  static const advance = T('एडवांस', 'Advance');
  static const askAdvance = T('एडवांस माँगें', 'Ask for an advance');
  static const askSub = T('ख़रीदार सीधे आपके UPI में भेजेगा; Sutra पैसा नहीं छूता।', 'The buyer pays straight into your UPI; Sutra never touches the money.');
  static const percentOf = T('ऑर्डर का कितना हिस्सा', 'Share of the order');
  static const ask = T('माँगें', 'Ask');
  static const asked = T('माँगा, अभी आया नहीं', 'Asked, not paid yet');
  static const claimed = T('ख़रीदार ने कहा भेज दिया', 'Buyer says it\'s paid');
  static const paid = T('एडवांस मिला', 'Advance received');
  static const checkUpi = T('अपने UPI ऐप में देखें, फिर पक्का करें', 'Check your UPI app, then confirm');
  static const confirm = T('हाँ, मिल गया', 'Yes, it arrived');
  static const utrLabel = T('UPI रेफ़रेंस (12 अंक)', 'UPI reference (12 digits)');
  static const payUpi = T('UPI से भरें', 'Pay by UPI');
  static const iPaid = T('मैंने भर दिया', 'I\'ve paid');
  static const payDirect = T('पैसा सीधे कारीगर के UPI में जाता है।', 'The money goes straight to the maker\'s UPI.');
  static const waitingMaker = T('कारीगर के पक्का करने का इंतज़ार', 'Waiting for the maker to confirm');
  static const ref = T('रेफ़रेंस', 'Ref');

  // X6 e-way bill
  static const eway = T('ई-वे बिल', 'E-way bill');
  static const ewayNeeded = T('ई-वे बिल ज़रूरी', 'E-way bill needed');
  static const ewayNotNeeded = T('ई-वे बिल नहीं चाहिए', 'No e-way bill needed');
  static const ewayAfter = T('भेजने पर टैक्स बिल से भर जाएगा', 'Filled from the tax invoice once dispatched');
  static const copyFields = T('जानकारी कॉपी करें', 'Copy the details');
  static const openPortal = T('ई-वे बिल पोर्टल खोलें', 'Open the e-way bill portal');
  static const copied = T('कॉपी हो गया', 'Copied');
  static const vehicle = T('गाड़ी नंबर (ई-वे बिल के लिए)', 'Vehicle number (for the e-way bill)');

  // X7 GSTR-2B
  static const twoB = T('GSTR-2B मिलान', 'Match with GSTR-2B');
  static const twoBSub = T('GST पोर्टल से GSTR-2B (JSON) डाउनलोड करें। Sutra आपके ख़रीद-बिलों से मिलाकर बताएगा कि किसका टैक्स क्रेडिट पक्का है और किसका अटका।',
      'Download GSTR-2B (JSON) from the GST portal. Sutra matches it with your purchase bills and shows which tax credit is safe and which is stuck.');
  static const pickFile = T('2B फ़ाइल चुनें', 'Choose the 2B file');
  static const trySample = T('नमूने से देखें', 'Try with a sample');
  static const sampleNote = T('नमूना: आपके ही बिलों से बना, दो कमियों के साथ', 'Sample: built from your own bills, with two gaps');
  static const safe = T('क्रेडिट पक्का', 'Credit safe');
  static const atRisk = T('क्रेडिट अटका', 'Credit at risk');
  static const matched = T('मिल गया', 'Matched');
  static const amountDiff = T('रकम अलग', 'Amount differs');
  static const notFiled = T('सप्लायर ने भरा नहीं', 'Supplier didn\'t file');
  static const notInBooks = T('आपकी किताब में नहीं', 'Not in your books');
  static const askSupplier = T('सप्लायर से GSTR-1 भरवाएँ, वरना इसका क्रेडिट नहीं मिलेगा', 'Ask the supplier to file GSTR-1, or this credit is lost');
  static const badFile = T('यह फ़ाइल GSTR-2B जैसी नहीं लगती', 'This file doesn\'t look like a GSTR-2B');

  // C6 schemes
  static const schemes = T('सरकारी योजनाएँ', 'Government schemes');
  static const schemesSub = T('आपकी जानकारी देखकर: ये योजनाएँ आपके काम की हो सकती हैं। आख़िरी फ़ैसला विभाग का; आवेदन सरकारी साइट पर ही करें।',
      'From what Sutra knows about you: these may fit. The department decides; apply only on the official site.');
  static const likely = T('काम की लगती है', 'Likely fits');
  static const check = T('देख लें', 'Worth checking');
  static const notNow = T('अभी नहीं', 'Not for now');
  static const officialSite = T('सरकारी साइट', 'Official site');
}
