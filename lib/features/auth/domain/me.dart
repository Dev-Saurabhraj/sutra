/// The logged-in user and, for producers, their business profile.
class Me {
  const Me({required this.user, required this.producer, required this.consentVersion});

  final SessionUser user;
  final ProducerProfile? producer;
  final String consentVersion;

  factory Me.fromJson(Map<String, dynamic> j) => Me(
        user: SessionUser.fromJson(j['user'] as Map<String, dynamic>),
        producer: j['producer'] == null ? null : ProducerProfile.fromJson(j['producer'] as Map<String, dynamic>),
        consentVersion: j['consentVersion'] as String,
      );

  Me copyWith({SessionUser? user}) => Me(user: user ?? this.user, producer: producer, consentVersion: consentVersion);
}

class SessionUser {
  const SessionUser({required this.id, required this.phone, required this.role, required this.language, required this.needsConsent});

  final String id;
  final String phone;
  final String role;
  final String language;
  final bool needsConsent;

  factory SessionUser.fromJson(Map<String, dynamic> j) => SessionUser(
        id: j['id'] as String,
        phone: j['phone'] as String,
        role: j['role'] as String,
        language: (j['language'] as String?) ?? 'hi',
        needsConsent: (j['needsConsent'] as bool?) ?? false,
      );

  SessionUser withConsent() => SessionUser(id: id, phone: phone, role: role, language: language, needsConsent: false);
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
  final String clusterName;
  final IndustryProfile industry;

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
        clusterName: (j['cluster'] as Map<String, dynamic>)['name'] as String,
        industry: IndustryProfile.fromJson(j['industry'] as Map<String, dynamic>),
      );
}
