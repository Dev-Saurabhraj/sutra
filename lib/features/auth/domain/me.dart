/// The logged-in user and, once onboarded, their business: a maker/seller (producer) or a buyer.
class Me {
  const Me({required this.user, required this.producer, required this.consentVersion, this.buyer, this.cluster, this.caName});

  final SessionUser user;
  final ProducerProfile? producer;
  final BuyerProfile? buyer;

  /// Set for a cluster admin (cooperative / FPO secretary).
  final ClusterBrief? cluster;
  final String consentVersion;

  /// Buyers get the marketplace (Bazaar), makers get the bahi.
  bool get isBuyer => buyer != null;
  bool get isClusterAdmin => cluster != null;

  /// Set for a chartered accountant (CA portal).
  final String? caName;
  bool get isCa => caName != null;

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        user: SessionUser.fromJson(j['user'] as Map<String, dynamic>),
        producer: j['producer'] == null ? null : ProducerProfile.fromJson(j['producer'] as Map<String, dynamic>),
        buyer: j['buyer'] == null ? null : BuyerProfile.fromJson(j['buyer'] as Map<String, dynamic>),
        cluster: j['cluster'] == null ? null : ClusterBrief.fromJson(j['cluster'] as Map<String, dynamic>),
        caName: (j['ca'] as Map<String, dynamic>?)?['name'] as String?,
        consentVersion: j['consentVersion'] as String,
      );

  Me copyWith({SessionUser? user}) => Me(user: user ?? this.user, producer: producer, buyer: buyer, cluster: cluster, caName: caName, consentVersion: consentVersion);
}

class ClusterBrief {
  const ClusterBrief({required this.id, required this.name, required this.city});
  final String id;
  final String name;
  final String city;

  factory ClusterBrief.fromJson(Map<String, dynamic> j) => ClusterBrief(id: j['id'] as String, name: j['name'] as String, city: j['city'] as String);
}

/// A shop, boutique or exporter buying from makers.
class BuyerProfile {
  const BuyerProfile({required this.id, required this.name, required this.business, required this.city, required this.state, required this.gstin, required this.phone});

  final String id;
  final String name;
  final String business;
  final String city;
  final String state;
  final String? gstin;
  final String phone;

  factory BuyerProfile.fromJson(Map<String, dynamic> j) => BuyerProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        business: j['business'] as String,
        city: j['city'] as String,
        state: j['state'] as String,
        gstin: j['gstin'] as String?,
        phone: j['phone'] as String,
      );
}

class SessionUser {
  const SessionUser({required this.id, required this.phone, required this.role, required this.language, required this.needsConsent, required this.needsOnboarding});

  final String id;
  final String phone;
  final String role;
  final String language;
  final bool needsConsent;

  /// A new number: no business yet, so onboarding comes first.
  final bool needsOnboarding;

  factory SessionUser.fromJson(Map<String, dynamic> j) => SessionUser(
        id: j['id'] as String,
        phone: j['phone'] as String,
        role: j['role'] as String,
        language: (j['language'] as String?) ?? 'hi',
        needsConsent: (j['needsConsent'] as bool?) ?? false,
        needsOnboarding: (j['needsOnboarding'] as bool?) ?? false,
      );

  SessionUser withConsent() =>
      SessionUser(id: id, phone: phone, role: role, language: language, needsConsent: false, needsOnboarding: needsOnboarding);
}

class IndustryProfile {
  const IndustryProfile({required this.key, required this.name, required this.nameHi, required this.machine, required this.machineHi, required this.emoji});

  final String key;
  final String name;
  final String nameHi;
  final String machine;
  final String machineHi;
  final String emoji;

  factory IndustryProfile.fromJson(Map<String, dynamic> j) => IndustryProfile(
        key: j['key'] as String,
        name: j['name'] as String,
        nameHi: j['nameHi'] as String,
        machine: j['machine'] as String,
        machineHi: j['machineHi'] as String,
        emoji: j['emoji'] as String,
      );
}

class ProducerProfile {
  const ProducerProfile({
    required this.id,
    required this.name,
    required this.businessName,
    required this.city,
    required this.state,
    required this.gstin,
    required this.gstScheme,
    required this.udyamNumber,
    required this.machines,
    required this.avatarColor,
    required this.clusterName,
    required this.industry,
    required this.isTrader,
  });

  final String id;
  final String name;
  final String businessName;
  final String city;
  final String state;
  final String? gstin;
  final String gstScheme;
  final String? udyamNumber;
  final int machines;
  final String avatarColor;
  final String? clusterName;
  final IndustryProfile industry;

  /// Traders buy finished goods and resell: the app hides making and recipes for them.
  final bool isTrader;

  factory ProducerProfile.fromJson(Map<String, dynamic> j) => ProducerProfile(
        id: j['id'] as String,
        name: j['name'] as String,
        businessName: j['businessName'] as String,
        city: j['city'] as String,
        state: j['state'] as String,
        gstin: j['gstin'] as String?,
        gstScheme: j['gstScheme'] as String,
        udyamNumber: j['udyamNumber'] as String?,
        machines: (j['machines'] as num).toInt(),
        avatarColor: j['avatarColor'] as String,
        clusterName: (j['cluster'] as Map<String, dynamic>?)?['name'] as String?,
        industry: IndustryProfile.fromJson(j['industry'] as Map<String, dynamic>),
        isTrader: j['businessKind'] == 'TRADER',
      );
}
