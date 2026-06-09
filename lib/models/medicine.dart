/// 药品数据模型
class Medicine {
  final String id;
  final String name;
  final String? genericName;
  final String? category;
  final String? dosageForm;
  final String? specification;
  final String? manufacturer;
  final String? barcode;
  final String? indications;
  final String? usageDosage;
  final String? contraindications;
  final String? sideEffects;
  final String? precautions;
  final String? drugInteractions;
  final String? plainLanguageExplanation;

  Medicine({
    required this.id,
    required this.name,
    this.genericName,
    this.category,
    this.dosageForm,
    this.specification,
    this.manufacturer,
    this.barcode,
    this.indications,
    this.usageDosage,
    this.contraindications,
    this.sideEffects,
    this.precautions,
    this.drugInteractions,
    this.plainLanguageExplanation,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      genericName: json['genericName'],
      category: json['category'],
      dosageForm: json['dosageForm'],
      specification: json['specification'],
      manufacturer: json['manufacturer'],
      barcode: json['barcode'],
      indications: json['indications'],
      usageDosage: json['usageDosage'],
      contraindications: json['contraindications'],
      sideEffects: json['sideEffects'],
      precautions: json['precautions'],
      drugInteractions: json['drugInteractions'],
      plainLanguageExplanation: json['plainLanguageExplanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'genericName': genericName,
      'category': category,
      'dosageForm': dosageForm,
      'specification': specification,
      'manufacturer': manufacturer,
      'barcode': barcode,
      'indications': indications,
      'usageDosage': usageDosage,
      'contraindications': contraindications,
      'sideEffects': sideEffects,
      'precautions': precautions,
      'drugInteractions': drugInteractions,
      'plainLanguageExplanation': plainLanguageExplanation,
    };
  }
}
