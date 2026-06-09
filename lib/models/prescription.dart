/// 处方数据模型
class Prescription {
  final String id;
  final String userId;
  final String? doctorName;
  final String? hospitalName;
  final String? department;
  final String? prescriptionNumber;
  final String? issueDate;
  final String? expiryDate;
  final String? diagnosis;
  final List<PrescriptionMedicine> medicines;
  final String? imageUrl;
  final String? ocrStatus;
  final String status;
  final String? notes;
  final DateTime? createdAt;

  Prescription({
    required this.id,
    required this.userId,
    this.doctorName,
    this.hospitalName,
    this.department,
    this.prescriptionNumber,
    this.issueDate,
    this.expiryDate,
    this.diagnosis,
    this.medicines = const [],
    this.imageUrl,
    this.ocrStatus,
    this.status = 'active',
    this.notes,
    this.createdAt,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      doctorName: json['doctorName'],
      hospitalName: json['hospitalName'],
      department: json['department'],
      prescriptionNumber: json['prescriptionNumber'],
      issueDate: json['issueDate'],
      expiryDate: json['expiryDate'],
      diagnosis: json['diagnosis'],
      medicines: (json['medicines'] as List<dynamic>?)
              ?.map((e) => PrescriptionMedicine.fromJson(e))
              .toList() ??
          [],
      imageUrl: json['imageUrl'],
      ocrStatus: json['ocrStatus'],
      status: json['status'] ?? 'active',
      notes: json['notes'],
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'doctorName': doctorName,
      'hospitalName': hospitalName,
      'department': department,
      'prescriptionNumber': prescriptionNumber,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'diagnosis': diagnosis,
      'medicines': medicines.map((e) => e.toJson()).toList(),
      'imageUrl': imageUrl,
      'ocrStatus': ocrStatus,
      'status': status,
      'notes': notes,
    };
  }

  /// 获取状态标签
  String get statusLabel {
    switch (status) {
      case 'active':
        return '有效';
      case 'expired':
        return '已过期';
      case 'archived':
        return '已归档';
      default:
        return '未知';
    }
  }

  /// 是否有效
  bool get isValid => status == 'active';
}

/// 处方中的药品项
class PrescriptionMedicine {
  final String name;
  final String? dosage;
  final String? frequency;
  final String? duration;

  PrescriptionMedicine({
    required this.name,
    this.dosage,
    this.frequency,
    this.duration,
  });

  factory PrescriptionMedicine.fromJson(Map<String, dynamic> json) {
    return PrescriptionMedicine(
      name: json['name'] ?? '',
      dosage: json['dosage'],
      frequency: json['frequency'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
    };
  }
}
