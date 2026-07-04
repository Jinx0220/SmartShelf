class UserModel {
  String? id;
  String? fullName;
  String email;
  String? storeName;
  String? storeAddress;

  int weeklyOffDay;
  String preferredCurrency;
  String preferredLanguage;

  String? profileImageUrl;

  bool isEmailVerified;

  DateTime createdAt;
  DateTime lastLogin;

  UserModel({
    this.id,
    this.fullName,
    required this.email,
    this.storeName,
    this.storeAddress,
    this.weeklyOffDay = 0,
    this.preferredCurrency = 'NPR',
    this.preferredLanguage = 'English',
    this.profileImageUrl,
    this.isEmailVerified = false,
    DateTime? createdAt,
    DateTime? lastLogin,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastLogin = lastLogin ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'storeName': storeName,
      'storeAddress': storeAddress,
      'weeklyOffDay': weeklyOffDay,
      'preferredCurrency': preferredCurrency,
      'preferredLanguage': preferredLanguage,
      'profileImageUrl': profileImageUrl,
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String?,
      fullName: map['fullName'] as String?,
      email: map['email'] ?? '',
      storeName: map['storeName'] as String?,
      storeAddress: map['storeAddress'] as String?,
      weeklyOffDay: map['weeklyOffDay'] ?? 0,
      preferredCurrency: map['preferredCurrency'] ?? 'NPR',
      preferredLanguage: map['preferredLanguage'] ?? 'English',
      profileImageUrl: map['profileImageUrl'] as String?,
      isEmailVerified: map['isEmailVerified'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      lastLogin: map['lastLogin'] != null
          ? DateTime.parse(map['lastLogin'])
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? storeName,
    String? storeAddress,
    int? weeklyOffDay,
    String? preferredCurrency,
    String? preferredLanguage,
    String? profileImageUrl,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      weeklyOffDay: weeklyOffDay ?? this.weeklyOffDay,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}