import '../../../core/l10n/app_strings.dart';

abstract final class BillText {
  static const title = T('बिल की फ़ोटो', 'Snap a bill');
  static const subtitle = T('स्टॉक + GST अपने आप', 'Stock + GST, automatic');
  static const camera = T('फ़ोटो लें', 'Take photo');
  static const gallery = T('गैलरी से', 'From gallery');
  static const samples = T('नमूना बिल आज़माएँ', 'Try a sample bill');
  static const aiOff = T('फ़ोटो पढ़ने वाला AI अभी बंद है, नमूना बिल से देखें।', 'Photo reading is off right now; try a sample bill.');
  static const reading = T('Sutra बिल पढ़ रहा है…', 'Sutra is reading the bill…');
  static const readBySutra = T('Sutra ने पढ़ा', 'Sutra read');
  static const sampleRead = T('नमूना बिल', 'Sample bill');
  static const supplier = T('सप्लायर', 'Supplier');
  static const newSupplier = T('नया सप्लायर, जुड़ जाएगा', 'New supplier, will be added');
  static const gstinOk = T('GSTIN सही', 'GSTIN OK');
  static const gstinBad = T('GSTIN गलत', 'GSTIN wrong');
  static const noGstin = T('GSTIN नहीं', 'No GSTIN');
  static const billNo = T('बिल नं.', 'Bill no.');
  static const items = T('क्या आया', 'What came in');
  static const whichMaterial = T('यह कौन सा माल है?', 'Which material is this?');
  static const skip = T('छोड़ दें', 'Skip');
  static const taxable = T('टैक्स से पहले', 'Before tax');
  static const total = T('कुल', 'Total');
  static const mathOk = T('हिसाब ठीक', 'Adds up');
  static const mathBad = T('हिसाब नहीं मिलता', "Doesn't add up");
  static const mathBadHint = T('बिल की रक़म जाँच लें, शायद पढ़ने में गलती हुई।', 'Check the amounts; something may be misread.');
  static const itc = T('टैक्स क्रेडिट मिलेगा', 'Tax credit you get');
  static const itcAtRisk = T('टैक्स क्रेडिट अटक सकता है', 'Tax credit at risk');
  static const itcAtRiskHint = T('सप्लायर से GSTIN ठीक करवाएँ, तभी क्रेडिट मिलेगा।', 'Ask the supplier to fix the GSTIN to get this credit.');
  static const shallISave = T('यह लिखूँ?', 'Shall I save this?');
  static const wrong = T('गलत है', 'Wrong');
  static const save = T('हाँ, लिख दो', 'Yes, save');
  static const saved = T('लिख लिया', 'Saved');
  static const another = T('एक और बिल', 'Another bill');
  static const seeGst = T('GST देखें', 'See GST');
  static const pickMaterial = T('हर लाइन के लिए माल चुनें', 'Pick a material for each line');
}
