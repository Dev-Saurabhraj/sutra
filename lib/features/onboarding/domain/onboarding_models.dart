/// Starter data for an industry, from the API (`GET /industries`).
class IndustryTemplate {
  const IndustryTemplate({
    required this.key,
    required this.name,
    required this.nameHi,
    required this.machine,
    required this.machineHi,
    required this.emoji,
    required this.wageType,
    required this.role,
    required this.roleHi,
    required this.materials,
    required this.products,
  });

  final String key;
  final String name;
  final String nameHi;
  final String machine;
  final String machineHi;
  final String emoji;
  final String wageType;
  final String role;
  final String roleHi;
  final List<DraftMaterial> materials;
  final List<DraftProduct> products;

  factory IndustryTemplate.fromJson(Map<String, dynamic> j) {
    final labour = j['labour'] as Map<String, dynamic>;
    return IndustryTemplate(
      key: j['key'] as String,
      name: j['name'] as String,
      nameHi: j['nameHi'] as String,
      machine: j['machine'] as String,
      machineHi: j['machineHi'] as String,
      emoji: j['emoji'] as String,
      wageType: labour['wageType'] as String,
      role: labour['role'] as String,
      roleHi: labour['roleHi'] as String,
      materials: (j['materials'] as List).map((m) => DraftMaterial.fromTemplate(m as Map<String, dynamic>)).toList(),
      products: (j['products'] as List).map((p) => DraftProduct.fromTemplate(p as Map<String, dynamic>)).toList(),
    );
  }
}

class DraftMaterial {
  const DraftMaterial({
    required this.key,
    required this.name,
    required this.nameHi,
    required this.unit,
    required this.hsn,
    required this.gstRate,
    required this.cost,
    this.stock = 0,
    this.include = true,
    this.supplierName = '',
    this.supplierPhone = '',
  });

  final String key;
  final String name;
  final String nameHi;
  final String unit;
  final String hsn;
  final double gstRate;
  final double cost;
  final double stock;
  final bool include;
  final String supplierName;
  final String supplierPhone;

  factory DraftMaterial.fromTemplate(Map<String, dynamic> j) => DraftMaterial(
        key: j['key'] as String,
        name: j['name'] as String,
        nameHi: j['nameHi'] as String,
        unit: j['unit'] as String,
        hsn: j['hsn'] as String,
        gstRate: (j['gstRate'] as num).toDouble(),
        cost: (j['cost'] as num).toDouble(),
      );

  DraftMaterial copyWith({double? cost, double? stock, bool? include, String? supplierName, String? supplierPhone}) => DraftMaterial(
        key: key,
        name: name,
        nameHi: nameHi,
        unit: unit,
        hsn: hsn,
        gstRate: gstRate,
        cost: cost ?? this.cost,
        stock: stock ?? this.stock,
        include: include ?? this.include,
        supplierName: supplierName ?? this.supplierName,
        supplierPhone: supplierPhone ?? this.supplierPhone,
      );
}

class DraftProduct {
  const DraftProduct({
    required this.key,
    required this.name,
    required this.nameHi,
    required this.category,
    required this.price,
    required this.hsn,
    required this.gstRate,
    required this.unitsPerMachinePerWeek,
    required this.recipe,
    this.stock = 0,
    this.include = true,
  });

  final String key;
  final String name;
  final String nameHi;
  final String category;
  final double price;
  final String hsn;
  final double gstRate;
  final double unitsPerMachinePerWeek;

  /// material key → quantity used per piece
  final Map<String, double> recipe;
  final int stock;
  final bool include;

  factory DraftProduct.fromTemplate(Map<String, dynamic> j) => DraftProduct(
        key: j['key'] as String,
        name: j['name'] as String,
        nameHi: j['nameHi'] as String,
        category: j['category'] as String,
        price: (j['price'] as num).toDouble(),
        hsn: j['hsn'] as String,
        gstRate: (j['gstRate'] as num).toDouble(),
        unitsPerMachinePerWeek: (j['unitsPerMachinePerWeek'] as num).toDouble(),
        recipe: (j['recipe'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toDouble())),
      );

  DraftProduct copyWith({double? price, int? stock, bool? include}) => DraftProduct(
        key: key,
        name: name,
        nameHi: nameHi,
        category: category,
        price: price ?? this.price,
        hsn: hsn,
        gstRate: gstRate,
        unitsPerMachinePerWeek: unitsPerMachinePerWeek,
        recipe: recipe,
        stock: stock ?? this.stock,
        include: include ?? this.include,
      );
}

class DraftWorker {
  const DraftWorker({required this.name, required this.wageType, required this.rate, this.phone = ''});

  final String name;
  final String wageType; // DAILY | PIECE | MONTHLY
  final double rate;
  final String phone;
}

enum GstChoice { regular, composition, unregistered }

/// Everything the onboarding form collects. Immutable; the controller swaps in copies.
class OnboardingDraft {
  const OnboardingDraft({
    this.name = '',
    this.businessName = '',
    this.industryKey,
    this.isTrader = false,
    this.city = '',
    this.state,
    this.machines = 1,
    this.gst = GstChoice.unregistered,
    this.gstin = '',
    this.udyam = '',
    this.upi = '',
    this.materials = const [],
    this.products = const [],
    this.workers = const [],
  });

  final String name;
  final String businessName;
  final String? industryKey;
  final bool isTrader;
  final String city;
  final String? state;
  final int machines;
  final GstChoice gst;
  final String gstin;
  final String udyam;
  final String upi;
  final List<DraftMaterial> materials;
  final List<DraftProduct> products;
  final List<DraftWorker> workers;

  OnboardingDraft copyWith({
    String? name,
    String? businessName,
    String? industryKey,
    bool? isTrader,
    String? city,
    String? state,
    int? machines,
    GstChoice? gst,
    String? gstin,
    String? udyam,
    String? upi,
    List<DraftMaterial>? materials,
    List<DraftProduct>? products,
    List<DraftWorker>? workers,
  }) =>
      OnboardingDraft(
        name: name ?? this.name,
        businessName: businessName ?? this.businessName,
        industryKey: industryKey ?? this.industryKey,
        isTrader: isTrader ?? this.isTrader,
        city: city ?? this.city,
        state: state ?? this.state,
        machines: machines ?? this.machines,
        gst: gst ?? this.gst,
        gstin: gstin ?? this.gstin,
        udyam: udyam ?? this.udyam,
        upi: upi ?? this.upi,
        materials: materials ?? this.materials,
        products: products ?? this.products,
        workers: workers ?? this.workers,
      );

  /// The API payload. Recipes are sent as indexes into the included materials list.
  Map<String, dynamic> toJson({required String language}) {
    final mats = isTrader ? <DraftMaterial>[] : materials.where((m) => m.include).toList();
    final index = {for (final (i, m) in mats.indexed) m.key: i};
    return {
      'name': name.trim(),
      'businessName': businessName.trim(),
      'language': language,
      'industryKey': industryKey,
      'businessKind': isTrader ? 'TRADER' : 'MAKER',
      'city': city.trim(),
      'state': state,
      'machines': machines,
      'gstScheme': switch (gst) {
        GstChoice.regular => 'REGULAR',
        GstChoice.composition => 'COMPOSITION',
        GstChoice.unregistered => 'UNREGISTERED',
      },
      if (gst != GstChoice.unregistered) 'gstin': gstin.trim().toUpperCase(),
      if (udyam.trim().isNotEmpty) 'udyamNumber': udyam.trim().toUpperCase(),
      if (upi.trim().isNotEmpty) 'upiId': upi.trim(),
      'materials': [
        for (final m in mats)
          {
            'name': m.name,
            'nameHi': m.nameHi,
            'unit': m.unit,
            'hsn': m.hsn,
            'gstRate': m.gstRate,
            'costPerUnit': m.cost,
            'stock': m.stock,
            if (m.supplierName.trim().isNotEmpty) 'supplier': {'name': m.supplierName.trim(), 'phone': m.supplierPhone.trim()},
          },
      ],
      'products': [
        for (final p in products.where((p) => p.include))
          {
            'name': p.name,
            'nameHi': p.nameHi,
            'category': p.category,
            'price': p.price,
            'hsn': p.hsn,
            'gstRate': p.gstRate,
            'stock': p.stock,
            'unitsPerMachinePerWeek': p.unitsPerMachinePerWeek,
            'recipe': [
              for (final e in p.recipe.entries)
                if (index.containsKey(e.key)) {'material': index[e.key], 'qtyPerUnit': e.value},
            ],
          },
      ],
      'workers': [
        for (final w in workers)
          {'name': w.name.trim(), if (w.phone.trim().isNotEmpty) 'phone': w.phone.trim(), 'wageType': w.wageType, 'rate': w.rate, 'payCycle': w.wageType == 'MONTHLY' ? 'MONTHLY' : 'WEEKLY'},
      ],
    };
  }
}

abstract interface class OnboardingRepository {
  Future<List<IndustryTemplate>> industries();

  /// Creates the business and stores the new session (its token now carries the producer id).
  Future<void> submit(OnboardingDraft draft, {required String language});
}
