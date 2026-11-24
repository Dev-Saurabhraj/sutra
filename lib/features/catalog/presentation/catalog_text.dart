import '../../../core/l10n/app_strings.dart';

abstract final class CatalogText {
  static const title = T('कैटलॉग', 'Catalog');
  static const shown = T('ख़रीदारों को दिख रहे', 'shown to buyers');
  static const live = T('दिख रहा', 'Live');
  static const hidden = T('छुपा', 'Hidden');
  static const needsPhoto = T('फ़ोटो जोड़ें', 'Add a photo');
  static const intro = T('फ़ोटो लें, दो लाइन बोलें या लिखें, Sutra ख़रीदारों के लिए साफ़ फ़ोटो और सच्चा विवरण बनाएगा।',
      'Take a photo, add a line about it; Sutra makes a clean photo and an honest description for buyers.');

  // editor
  static const step1 = T('1 · फ़ोटो', '1 · Photo');
  static const step2 = T('2 · आपके शब्द', '2 · In your words');
  static const step3 = T('3 · ख़रीदार क्या पढ़ेगा', '3 · What buyers read');
  static const step4 = T('4 · दाम', '4 · Price');
  static const camera = T('कैमरा', 'Camera');
  static const gallery = T('गैलरी', 'Gallery');
  static const cleanNote = T('फ़ोटो सीधी, चौकोर और साफ़ रोशनी में की जाएगी; रंग नहीं बदले जाते।', 'The photo is straightened, squared and evenly lit; colours are not changed.');
  static const noteHint = T('जैसे: हल्की साड़ी, गर्मी के लिए, हाथ से बूटी', 'e.g. light saree for summer, hand-woven butis');
  static const makeStory = T('विवरण बनाएँ', 'Write the description');
  static const writing = T('लिख रहे हैं…', 'Writing…');
  static const byTemplate = T('सादा नमूना (AI बंद है), अपने हिसाब से बदलें', 'Plain template (AI is off); edit it as you like');
  static const keptStory = T('AI बंद है, इसलिए आपका लिखा विवरण वैसा ही रखा', 'AI is off, so your own description was kept');
  static const byClaude = T('फ़ोटो और आपके शब्दों से लिखा गया, जाँच लें', 'Written from your photo and words; check it');
  static const name = T('नाम (अंग्रेज़ी)', 'Name (English)');
  static const story = T('विवरण (अंग्रेज़ी)', 'Description (English)');
  static const listPrice = T('थोक दाम (प्रति पीस)', 'Wholesale price (per piece)');
  static const save = T('सहेजें', 'Save');
  static const publish = T('सहेजें और दिखाएँ', 'Save and show to buyers');
  static const unpublish = T('ख़रीदारों से छुपाएँ', 'Hide from buyers');
  static const saved = T('सहेज लिया', 'Saved');
  static const published = T('अब ख़रीदारों को दिख रहा है', 'Now live for buyers');
  static const belowCostTitle = T('इस दाम में घाटा है', 'You lose money at this price');
  static const belowCostAnyway = T('फिर भी दिखाएँ', 'Show it anyway');
  static const fixPrice = T('दाम ठीक करें', 'Fix the price');
}
