import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../design/tokens.dart';
import '../../orders/domain/order_models.dart';

abstract final class CapText {
  static const title = T('काम का कैलेंडर', 'Work calendar');
  static const sub = T('छुट्टी, शादी, बिजली कटौती, मरम्मत: यहाँ लिखें, तो हर वादा इन्हें गिनकर बनेगा।',
      'Holidays, weddings, power cuts, repairs: note them here and every promise counts them.');
  static const lost = T('अगले 6 हफ़्तों में कम काम', 'Work lost in the next 6 weeks');
  static const machineDays = T('मशीन-दिन', 'machine-days');
  static const entries = T('लिखी हुई छुट्टियाँ', 'Days off noted');
  static const none = T('अभी कोई छुट्टी नहीं लिखी।', 'No days off noted yet.');
  static const add = T('छुट्टी / कम काम जोड़ें', 'Add days off');
  static const addTitle = T('कब कम काम होगा?', 'When will fewer machines run?');
  static const why = T('क्यों', 'Why');
  static const from = T('से', 'From');
  static const to = T('तक', 'To');
  static const howMany = T('कितनी मशीनें बंद', 'Machines off');
  static const all = T('सब', 'all');
  static const note = T('नोट (जैसे: मोहल्ले में शादी)', 'Note (e.g. wedding in the mohalla)');
  static const save = T('जोड़ें', 'Add');
  static const saved = T('जोड़ दिया; वादे अब इसे गिनेंगे', 'Added; promises now count it');
  static const atRiskTitle = T('ये ऑर्डर देर से हो सकते हैं', 'These orders may now be late');
  static const atRiskSub = T('ख़रीदार को पहले बता दें। अलर्ट भी बन गया है।', 'Tell the buyer early. An alert was added too.');
  static const removed = T('हटा दिया', 'Removed');
  static const counted = T('गिनी गई छुट्टियाँ', 'Days off counted');
  static const today = T('आज', 'Today');
  static const off = T('बंद', 'off');

  static const kindHoliday = T('छुट्टी', 'Holiday');
  static const kindFestival = T('त्योहार', 'Festival');
  static const kindWedding = T('शादी', 'Wedding');
  static const kindPower = T('बिजली कटौती', 'Power cut');
  static const kindAbsence = T('कारीगर छुट्टी पर', 'Workers away');
  static const kindRepair = T('मशीन मरम्मत', 'Repair');
  static const kindOther = T('और कुछ', 'Other');
}

T kindLabel(CapacityKind k) => switch (k) {
      CapacityKind.holiday => CapText.kindHoliday,
      CapacityKind.festival => CapText.kindFestival,
      CapacityKind.wedding => CapText.kindWedding,
      CapacityKind.powerCut => CapText.kindPower,
      CapacityKind.absence => CapText.kindAbsence,
      CapacityKind.repair => CapText.kindRepair,
      CapacityKind.other => CapText.kindOther,
    };

IconData kindIcon(CapacityKind k) => switch (k) {
      CapacityKind.holiday => Icons.beach_access_outlined,
      CapacityKind.festival => Icons.celebration_outlined,
      CapacityKind.wedding => Icons.favorite_border_rounded,
      CapacityKind.powerCut => Icons.power_off_outlined,
      CapacityKind.absence => Icons.person_off_outlined,
      CapacityKind.repair => Icons.build_outlined,
      CapacityKind.other => Icons.event_busy_outlined,
    };

/// "Wedding · 1–6 Dec · 3 off": a counted stretch of days off, small enough to sit in a quote.
class DaysOffChip extends StatelessWidget {
  const DaysOffChip({super.key, required this.event, required this.strings});
  final CapacityEvent event;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final e = event;
    final dates = e.days == 1
        ? Fmt.shortDate(e.startsOn, hindi: s.isHindi)
        : '${Fmt.shortDate(e.startsOn, hindi: s.isHindi)}–${Fmt.shortDate(e.endsOn, hindi: s.isHindi)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(color: SutraColors.haldiWash, borderRadius: BorderRadius.all(SutraRadius.sm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(kindIcon(e.kind), size: 14, color: SutraColors.haldiDeep),
          const SizedBox(width: 4),
          Text('${s.tr(kindLabel(e.kind))} · $dates · ${e.machinesOff} ${s.tr(CapText.off)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SutraColors.haldiDeep)),
        ],
      ),
    );
  }
}
