import '../../../core/l10n/app_strings.dart';

abstract final class OrderText {
  static const title = T('ऑर्डर', 'Orders');
  static const tabNew = T('नई माँग', 'New');
  static const tabActive = T('चल रहे', 'Active');
  static const tabDone = T('पूरे', 'Done');
  static const emptyNew = T('अभी कोई नई माँग नहीं। ख़रीदार आपका कैटलॉग देखकर पूछेंगे।', 'No new requests. Buyers ask after seeing your catalog.');
  static const emptyActive = T('कोई ऑर्डर नहीं चल रहा।', 'Nothing in progress.');
  static const emptyDone = T('अभी कोई पूरा ऑर्डर नहीं।', 'No finished orders yet.');
  static const wanted = T('चाहिए', 'Wanted by');
  static const pieces = T('पीस', 'pcs');

  // stages
  static const stageAsked = T('माँग', 'Asked');
  static const stageMaking = T('बन रहा', 'Making');
  static const stageSent = T('भेजा', 'Sent');
  static const stageReached = T('पहुँचा', 'Reached');
  static const declined = T('मना किया', 'Declined');

  // can I deliver
  static const canDeliver = T('क्या समय पर दे पाएँगे?', 'Can you deliver in time?');
  static const yesInTime = T('हाँ, समय पर', 'Yes, in time');
  static const partly = T('कुछ समय पर', 'Partly in time');
  static const notInTime = T('समय पर नहीं', 'Not in time');
  static const readyNow = T('अभी तैयार', 'Ready now');
  static const perDay = T('रोज़ बनते', 'Made per day');
  static const byWanted = T('चाहिए की तारीख़ तक', 'By the wanted date');
  static const allBy = T('पूरे कब तक', 'All of it by');
  static const orderMaterial = T('कच्चा माल मँगाएँ', 'Order material');
  static const orderBy = T('तक मँगा लें', 'order by');
  static const late = T('देर हो चुकी', 'already late');
  static const curveNote = T('लाइन: रोज़ कितने तैयार होंगे (स्टॉक + करघे, बाकी ऑर्डर गिनकर)', 'Line: pieces ready each day (stock + looms, after your other orders)');

  // price
  static const priceCheck = T('इस दाम में बचत', 'What you keep at this price');
  static const theyPay = T('ख़रीदार देगा', 'Buyer pays');
  static const materials = T('कच्चा माल', 'Materials');
  static const labour = T('मज़दूरी', 'Wages');
  static const keep = T('आपकी बचत', 'You keep');
  static const loss = T('घाटा', 'Loss');
  static const thin = T('कम बचत', 'Thin margin');
  static const fair = T('ठीक बचत', 'Fair margin');
  static const perPiece = T('प्रति पीस', 'per piece');
  static const noLabour = T('पीस-रेट कारीगर नहीं जुड़ा, मज़दूरी नहीं गिनी', 'No piece-rate karigar linked; wages not counted');

  // actions
  static const accept = T('हाँ, ऑर्डर लें', 'Accept order');
  static const acceptPartial = T('जितना हो सके, लें', 'Accept with these dates');
  static const decline = T('मना करें', 'Decline');
  static const declineSure = T('यह ऑर्डर मना करें?', 'Decline this order?');
  static const declineNote = T('ख़रीदार को विनम्र संदेश जाएगा।', 'The buyer gets a polite note.');
  static const accepted = T('ऑर्डर लिया, ख़रीदार को तारीख़ें भेजीं', 'Accepted; dates sent to the buyer');
  static const dispatch = T('माल भेजें', 'Dispatch');
  static const madeSoFar = T('पीस तैयार', 'pieces made');
  static const recordMade = T('बना माल लिखें', 'Record production');
  static const dispatchTitle = T('माल रवाना', 'Goods dispatched');
  static const dispatchSub = T('बिल अपने-आप बनेगा, स्टॉक घटेगा, पैसा खाते में आएगा', 'The invoice is made, stock goes down, the money goes to khata');
  static const transporter = T('ट्रांसपोर्ट / गाड़ी', 'Transporter');
  static const lr = T('LR / बिल्टी नंबर', 'LR / bilty number');
  static const proofPhoto = T('पैकिंग की फ़ोटो (सबूत)', 'Photo of the packed goods (proof)');
  static const addPhoto = T('फ़ोटो लें', 'Take photo');
  static const changePhoto = T('दूसरी फ़ोटो', 'Change photo');
  static const dispatched = T('माल भेजा, बिल बन गया', 'Dispatched; invoice made');
  static const deliver = T('पहुँच गया', 'Mark delivered');
  static const delivered = T('ऑर्डर पूरा', 'Order complete');
  static const sentVia = T('भेजा', 'Sent');
  static const bills = T('बिल', 'Invoices');

  // chat
  static const letters = T('ख़रीदार से बात', 'Talk to the buyer');
  static const writeHint = T('हिंदी में लिखें, ख़रीदार को अंग्रेज़ी में जाएगा', 'Write in Hindi; the buyer reads English');
  static const send = T('भेजें', 'Send');
  static const translatedFrom = T('अंग्रेज़ी से अनुवाद', 'translated from English');
  static const notTranslated = T('अनुवाद बंद है, जैसा लिखा वैसा जाएगा', 'translation is off; sent as written');
  static const showOriginal = T('असली देखें', 'Show original');
  static const showTranslation = T('अनुवाद देखें', 'Show translation');
  static const you = T('आप', 'You');
}
