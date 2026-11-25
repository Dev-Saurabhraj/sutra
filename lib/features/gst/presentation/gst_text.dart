import '../../../core/l10n/app_strings.dart';

abstract final class GstText {
  static const title = T('GST का हिसाब', 'GST');
  static const month = T('महीना', 'Month');
  static const quarter = T('तिमाही', 'Quarter');
  static const taxCollected = T('बिक्री पर लिया टैक्स', 'Tax on your sales');
  static const taxCredit = T('ख़रीद पर टैक्स क्रेडिट', 'Credit on your purchases');
  static const payable = T('सरकार को देना', 'To pay the government');
  static const carryForward = T('अगले महीने काम आएगा', 'Credit carried forward');
  static const atRisk = T('क्रेडिट अटका', 'Credit at risk');
  static const compositionTax = T('इस बार का कंपोज़िशन टैक्स', 'Composition tax this period');
  static const compositionHow = T('बिक्री का 1% (आधा CGST, आधा SGST)', '1% of sales (half CGST, half SGST)');
  static const compositionLimit = T('कंपोज़िशन की सीमा', 'Composition limit');
  static const registration = T('GST लेने की सीमा', 'GST registration threshold');
  static const mustRegister = T('GST लेना ज़रूरी', 'Must register');
  static const fyTurnover = T('इस साल की बिक्री', 'Sales this year');
  static const sales = T('बिक्री', 'Sales');
  static const bills = T('बिल', 'bills');
  static const purchases = T('ख़रीद के बिल', 'Purchase bills');
  static const fix = T('ठीक करें', 'To fix');
  static const allGood = T('सब ठीक है', 'All good');
  static const forCa = T('CA को भेजें', 'Send to your CA');
  static const csv = T('एक्सेल (CSV)', 'Excel (CSV)');
  static const gstr1 = T('GSTR-1 (JSON)', 'GSTR-1 (JSON)');
  static const reviewNote = T('ये फ़ाइलें CA के देखने के लिए हैं, Sutra रिटर्न फ़ाइल नहीं करता।', 'These files are for your CA to review; Sutra never files returns.');
  static const recentBills = T('हाल के बिल', 'Recent invoices');
  static const sharePdf = T('PDF भेजें / प्रिंट', 'Share / print PDF');
  static const snapBill = T('बिल की फ़ोटो', 'Snap a bill');
  static const placeOfSupply = T('माल कहाँ गया', 'Place of supply');
  static const buyer = T('ख़रीदार', 'Buyer');
  static const kindTax = T('टैक्स बिल', 'TAX');
  static const kindProforma = T('प्रोफ़ॉर्मा', 'PROFORMA');
  static const kindBos = T('बिल ऑफ़ सप्लाई', 'BILL OF SUPPLY');
}
