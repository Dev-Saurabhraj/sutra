import '../../../core/l10n/app_strings.dart';

abstract final class LabText {
  static const title = T('किसका कितना बाकी?', "Who's owed what?");
  static const wagesDue = T('कारीगरों का देना', 'Wages due');
  static const overdue = T('समय पार', 'Late');
  static const advanceOut = T('पेशगी बाहर', 'Advance out');
  static const cameToday = T('आज आए', 'Came today');
  static const rollCall = T('आज की हाज़िरी', "Today's roll call");
  static const rollCallHint = T('नाम पर टैप करें: आया → आधा दिन → नहीं आया', 'Tap a name: present → half day → absent');
  static const saveRollCall = T('हाज़िरी लिख दो', 'Save roll call');
  static const present = T('आया', 'Present');
  static const half = T('आधा', 'Half');
  static const absent = T('नहीं', 'Absent');
  static const team = T('कारीगर', 'Team');
  static const addWorker = T('कारीगर जोड़ें', 'Add worker');
  static const pay = T('पैसे दें', 'Pay');
  static const addWork = T('+ काम', '+ Work');
  static const advance = T('पेशगी', 'Advance');
  static const due = T('बाकी', 'Due');
  static const paidUp = T('हिसाब बराबर', 'All paid');
  static const payBy = T('तक देना है', 'pay by');
  static const perDay = T('/ दिन', '/ day');
  static const perPiece = T('/ नग', '/ piece');
  static const perMonth = T('/ माह', '/ month');
  static const noTeam = T('अभी कोई कारीगर नहीं। जोड़ें, फिर हाज़िरी और मज़दूरी यहीं से।', 'No workers yet. Add them, then do attendance and wages here.');

  static const earnedDue = T('कमाई बाकी', 'Wages earned, unpaid');
  static const advanceCut = T('पेशगी कटेगी', 'Advance adjusted');
  static const advanceRule = T('क़ानून के हिसाब से इस बार की मज़दूरी का आधा ही कट सकता है', 'By law, at most half of this period\'s wages can be adjusted');
  static const inHand = T('हाथ में देना है', 'To hand over');
  static const how = T('कैसे दिया?', 'Paid how?');
  static const cash = T('नक़द', 'Cash');
  static const upi = T('UPI', 'UPI');
  static const bank = T('बैंक', 'Bank');
  static const sendSlip = T('पर्ची WhatsApp पर भेजें', 'Send wage slip on WhatsApp');
  static const paid = T('पैसे दिए, लिख लिया', 'Paid and recorded');
  static const nothingDue = T('अभी कुछ बाकी नहीं', 'Nothing due right now');

  static const advanceTitle = T('पेशगी दें', 'Give an advance');
  static const advanceHint = T('मज़दूरी से धीरे-धीरे कटेगी, हर बार आधी तक।', 'Recovered from wages bit by bit, at most half each time.');
  static const amount = T('रक़म', 'Amount');
  static const advanceGiven = T('पेशगी लिख ली', 'Advance recorded');

  static const pieceTitle = T('कितने नग बनाए?', 'How many pieces?');
  static const pieceSaved = T('काम लिख लिया', 'Work recorded');

  static const name = T('नाम', 'Name');
  static const phone = T('फ़ोन (पर्ची भेजने के लिए)', 'Phone (for wage slips)');
  static const wageDaily = T('रोज़ाना', 'Daily');
  static const wagePiece = T('नग के हिसाब से', 'Per piece');
  static const wageMonthly = T('महीने की तनख़्वाह', 'Monthly');
  static const rate = T('रेट', 'Rate');
  static const workerAdded = T('कारीगर जुड़ गया', 'Worker added');

  static const history = T('पूरा हिसाब', 'Full history');
  static const kindAttendance = T('हाज़िरी', 'Attendance');
  static const kindPiece = T('काम', 'Work');
  static const kindWage = T('मज़दूरी दी', 'Wages paid');
  static const kindAdvance = T('पेशगी दी', 'Advance given');
  static const kindRecovery = T('पेशगी कटी', 'Advance adjusted');
  static const days = T('दिन', 'day');
  static const pieces = T('नग', 'pcs');
  static const slip = T('पर्ची भेजें', 'Send slip');
}
