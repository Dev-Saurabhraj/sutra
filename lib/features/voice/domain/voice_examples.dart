/// Things a producer might say, per industry — so a potter is never asked to say "saree" (RULES B10).
abstract final class VoiceExamples {
  static const _byIndustry = <String, List<String>>{
    'handloom': ['aaj 6 saree bani, 4 Jaipur bheji', 'आज 10 दुपट्टे बने', 'Jaipur se 5000 rupaye mile'],
    'brass': ['aaj 20 diya set bane', '10 urli Delhi bheje', 'आज 8 हाथी बने'],
    'pottery': ['aaj 60 kulhad bane', '30 gamle Delhi bheje', 'आज 40 कुल्हड़ बने'],
    'toys': ['aaj 100 lattu bane', '20 gudiya set Mysuru bheje', 'आज 50 लट्टू बने'],
    'food': ['aaj 200 achar bane', '50 achar Indore bheje', 'आज 100 अचार बने'],
    'machining': ['aaj 12 bolt box bane', '5 bolt box Rajkot bheje', 'आज 10 बोल्ट बने'],
  };
  static const _generic = ['aaj 10 piece bane', '5 piece Indore bheje'];

  static List<String> forIndustry(String? key) => _byIndustry[key] ?? _generic;
}
