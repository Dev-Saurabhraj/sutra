/// GSTIN checks on the phone, so a typo is caught while typing (same mod-36 rule as the API).
library;

const _chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
final _format = RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');

/// GST state codes (first two digits of a GSTIN), in alphabetical order of state.
const gstStates = <String, String>{
  'Andaman and Nicobar Islands': '35',
  'Andhra Pradesh': '37',
  'Arunachal Pradesh': '12',
  'Assam': '18',
  'Bihar': '10',
  'Chandigarh': '04',
  'Chhattisgarh': '22',
  'Dadra and Nagar Haveli and Daman and Diu': '26',
  'Delhi': '07',
  'Goa': '30',
  'Gujarat': '24',
  'Haryana': '06',
  'Himachal Pradesh': '02',
  'Jammu and Kashmir': '01',
  'Jharkhand': '20',
  'Karnataka': '29',
  'Kerala': '32',
  'Ladakh': '38',
  'Lakshadweep': '31',
  'Madhya Pradesh': '23',
  'Maharashtra': '27',
  'Manipur': '14',
  'Meghalaya': '17',
  'Mizoram': '15',
  'Nagaland': '13',
  'Odisha': '21',
  'Puducherry': '34',
  'Punjab': '03',
  'Rajasthan': '08',
  'Sikkim': '11',
  'Tamil Nadu': '33',
  'Telangana': '36',
  'Tripura': '16',
  'Uttar Pradesh': '09',
  'Uttarakhand': '05',
  'West Bengal': '19',
};

String gstinCheckDigit(String first14) {
  var sum = 0;
  for (var i = 0; i < 14; i++) {
    final v = _chars.indexOf(first14[i]);
    final p = v * (i.isEven ? 1 : 2);
    sum += p ~/ 36 + p % 36;
  }
  return _chars[(36 - sum % 36) % 36];
}

enum GstinProblem { length, format, state, checkDigit, wrongState }

/// null when the GSTIN is valid (and, if [state] is given, belongs to that state).
GstinProblem? checkGstin(String raw, {String? state}) {
  final g = raw.trim().toUpperCase();
  if (g.length != 15) return GstinProblem.length;
  if (!_format.hasMatch(g)) return GstinProblem.format;
  final code = g.substring(0, 2);
  if (!gstStates.containsValue(code)) return GstinProblem.state;
  if (gstinCheckDigit(g.substring(0, 14)) != g[14]) return GstinProblem.checkDigit;
  if (state != null && gstStates[state] != code) return GstinProblem.wrongState;
  return null;
}
