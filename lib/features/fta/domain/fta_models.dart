/// Free-trade-benefit logic, pure Dart: no Flutter, no HTTP, easy to unit test.
///
/// The FTA benefit for an Indian MSME is a lower (often zero) import duty in the
/// buyer's country. It is claimed at export time with a Certificate of Origin —
/// there is no separate "FTA application". This module models that: which India
/// agreement covers a destination, the rule-of-thumb origin requirement, and the
/// duty a consignment saves.
library;

/// Whether an agreement is already in force or signed and being phased in.
enum FtaStatus {
  inForce,
  signed;

  bool get inForce => this == FtaStatus.inForce;
}

/// One India FTA / CEPA / PTA and the broad origin rule of thumb for it.
class FtaAgreement {
  const FtaAgreement({
    required this.key,
    required this.name,
    required this.nameHi,
    required this.countryCodes,
    required this.year,
    required this.status,
    required this.coverage,
    required this.coverageHi,
    required this.valueAddPct,
  });

  final String key;

  /// Short English name, e.g. "India–UAE CEPA".
  final String name;
  final String nameHi;

  /// Partner country / bloc codes this agreement covers (used for lookup).
  final List<String> countryCodes;

  /// Year it entered into force (or was signed, for [FtaStatus.signed]).
  final int year;
  final FtaStatus status;

  /// What it broadly covers, one line, in each language.
  final String coverage;
  final String coverageHi;

  /// Typical minimum local value addition in percent. The exact rule is
  /// product-specific (Product Specific Rules), so this is a guide, not a filing value.
  final int valueAddPct;
}

/// One export destination, bilingual.
class FtaDestination {
  const FtaDestination(this.code, this.name, this.nameHi);

  final String code;
  final String name;
  final String nameHi;
}

/// How much import duty a consignment saves under an FTA.
class DutySaving {
  const DutySaving({
    required this.invoiceValue,
    required this.normalRate,
    required this.preferentialRate,
  });

  final double invoiceValue;

  /// Duty the buyer would pay without the FTA, percent.
  final double normalRate;

  /// Duty under the FTA, percent.
  final double preferentialRate;

  double get normalDuty => invoiceValue * normalRate / 100;
  double get preferentialDuty => invoiceValue * preferentialRate / 100;

  double get saved => (normalDuty - preferentialDuty).clamp(0, double.infinity).toDouble();
  double get savedPct => (normalRate - preferentialRate).clamp(0, 100).toDouble();

  /// Returns null for incomplete or nonsensical inputs, so the UI can stay quiet.
  static DutySaving? calc({double? invoiceValue, double? normalRate, double? preferentialRate}) {
    if (invoiceValue == null || normalRate == null || preferentialRate == null) return null;
    if (invoiceValue < 0 || normalRate < 0 || preferentialRate < 0) return null;
    if (preferentialRate > normalRate) return null;
    return DutySaving(
      invoiceValue: invoiceValue,
      normalRate: normalRate,
      preferentialRate: preferentialRate,
    );
  }
}

/// Looks up which agreements cover a destination.
class FtaEngine {
  FtaEngine({required List<FtaAgreement> agreements, required List<FtaDestination> destinations})
      : agreements = List.unmodifiable(agreements),
        destinations = List.unmodifiable(destinations),
        _byCountry = _index(agreements);

  final List<FtaAgreement> agreements;
  final List<FtaDestination> destinations;
  final Map<String, List<FtaAgreement>> _byCountry;

  static Map<String, List<FtaAgreement>> _index(List<FtaAgreement> agreements) {
    final m = <String, List<FtaAgreement>>{};
    for (final a in agreements) {
      for (final c in a.countryCodes) {
        m.putIfAbsent(c, () => []).add(a);
      }
    }
    return m;
  }

  List<FtaAgreement> forCountry(String countryCode) => _byCountry[countryCode] ?? const [];
}
