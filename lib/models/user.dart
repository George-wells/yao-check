/// 用户数据模型
class User {
  final String id;
  final String phone;
  final String name;
  final String? avatarUrl;
  final String? gender;
  final String? birthDate;
  final int? age;
  final bool isElderlyMode;
  final double fontScale;
  final bool highContrast;
  final bool enableVoice;
  final bool pushEnabled;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.phone,
    required this.name,
    this.avatarUrl,
    this.gender,
    this.birthDate,
    this.age,
    this.isElderlyMode = false,
    this.fontScale = 1.0,
    this.highContrast = false,
    this.enableVoice = false,
    this.pushEnabled = true,
    this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      avatarUrl: json['avatarUrl'],
      gender: json['gender'],
      birthDate: json['birthDate'],
      age: json['age'],
      isElderlyMode: json['isElderlyMode'] ?? false,
      fontScale: (json['fontScale'] ?? 1.0).toDouble(),
      highContrast: json['highContrast'] ?? false,
      enableVoice: json['enableVoice'] ?? false,
      pushEnabled: json['pushEnabled'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      lastLoginAt: json['lastLoginAt'] != null ? DateTime.tryParse(json['lastLoginAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'birthDate': birthDate,
      'age': age,
      'isElderlyMode': isElderlyMode,
      'fontScale': fontScale,
      'highContrast': highContrast,
      'enableVoice': enableVoice,
      'pushEnabled': pushEnabled,
    };
  }

  User copyWith({
    String? name,
    String? avatarUrl,
    String? gender,
    String? birthDate,
    bool? isElderlyMode,
    double? fontScale,
    bool? highContrast,
    bool? enableVoice,
    bool? pushEnabled,
  }) {
    return User(
      id: id,
      phone: phone,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      age: age,
      isElderlyMode: isElderlyMode ?? this.isElderlyMode,
      fontScale: fontScale ?? this.fontScale,
      highContrast: highContrast ?? this.highContrast,
      enableVoice: enableVoice ?? this.enableVoice,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
    );
  }
}
