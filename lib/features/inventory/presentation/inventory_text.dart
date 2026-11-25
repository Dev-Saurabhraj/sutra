import '../../../core/l10n/app_strings.dart';

abstract final class InvText {
  static const title = T('माल कहाँ है?', 'Where are my goods?');
  static const supplier = T('सप्लायर', 'Suppliers');
  static const raw = T('कच्चा माल', 'Raw');
  static const making = T('बनाना', 'Making');
  static const ready = T('तैयार', 'Ready');
  static const client = T('ग्राहक', 'Clients');

  static const supplierHint = T('यहाँ से कच्चा माल आता है। इन्हें पैसे देने हैं।', 'Raw material comes from here. You pay them.');
  static const rawHint = T('गोदाम में पड़ा कच्चा माल। कम होने पर लाल दिखेगा।','Raw material in store. Red means running low.');
  static const makingHint = T('जो बना, उसे लिखें। रेसिपी से कच्चा माल अपने आप घटेगा।', 'Record what was made. Raw material goes down by recipe.');
  static const readyHint = T('बिकने को तैयार माल। बेचा तो बिल अपने आप।', 'Goods ready to sell. Selling makes the bill.');
  static const clientHint = T('जिन्हें माल बेचते हैं। इनसे पैसे लेने हैं।', 'People you sell to. They pay you.');
  static const traderMakingHint = T('आप ख़रीदकर बेचते हैं, इसलिए बनाना नहीं।', 'You buy and resell, so there is no making step.');

  static const stockIn = T('माल आया', 'Stock in');
  static const fromBill = T('बिल की फ़ोटो से माल चढ़ाएँ', 'Stock in from a bill photo');
  static const made = T('बनाया', 'Made');
  static const sold = T('बेचा', 'Sold');
  static const count = T('गिनती', 'Count');
  static const history = T('हिसाब', 'History');
  static const addSupplier = T('सप्लायर जोड़ें', 'Add supplier');
  static const addClient = T('ग्राहक जोड़ें', 'Add client');
  static const addMaterial = T('कच्चा माल जोड़ें', 'Add material');
  static const addProduct = T('नया माल जोड़ें', 'Add product');
  static const toPay = T('देना', 'To pay');
  static const toReceive = T('लेना', 'To receive');
  static const madeThisWeek = T('इस हफ़्ते बना', 'Made this week');
  static const soldThisWeek = T('इस हफ़्ते बिका', 'Sold this week');
  static const leadDays = T('दिन में पहुँचाता है', 'days to deliver');
  static const none = T('अभी कोई नहीं', 'None yet');

  static const howMuch = T('कितना?', 'How much?');
  static const ratePer = T('दाम प्रति', 'Rate per');
  static const fromSupplier = T('किससे आया?', 'From whom?');
  static const whoMade = T('किसने बनाया? (मज़दूरी जुड़ेगी)', 'Who made it? (adds piece wages)');
  static const nobody = T('ख़ुद / कोई नहीं', 'Myself / nobody');
  static const toWhom = T('किसे बेचा?', 'Sold to whom?');
  static const walkIn = T('कोई और', 'Someone else');
  static const walkInName = T('नाम', 'Name');
  static const walkInCity = T('शहर', 'City');
  static const save = T('लिख दो', 'Save');
  static const saved = T('लिख लिया', 'Saved');
  static const billMade = T('बिल बना', 'Bill made');
  static const actualCount = T('असल में कितना है?', 'How much is there actually?');
  static const name = T('नाम', 'Name');
  static const phone = T('फ़ोन', 'Phone');
  static const city = T('शहर', 'City');
  static const business = T('दुकान का नाम', 'Business name');
  static const unit = T('इकाई (kg, मीटर, नग…)', 'Unit (kg, m, pcs…)');
  static const cost = T('दाम', 'Cost');
  static const opening = T('अभी कितना है', 'In hand now');
  static const price = T('थोक दाम', 'Wholesale price');
  static const recipe = T('एक नग में कितना लगता है?', 'How much goes into one piece?');

  static const kindPurchase = T('आया', 'In');
  static const kindConsume = T('लगा', 'Used');
  static const kindProduce = T('बना', 'Made');
  static const kindSale = T('बिका', 'Sold');
  static const kindAdjust = T('गिनती', 'Count');
}
