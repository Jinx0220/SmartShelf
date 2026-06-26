class UserModel {
  String? id;
  String? fullName;
  String? email;
  String phone;
  String? storeName;
  String? storeAddress;
  int weeklyOffDay;
  String preferredCurrency;
  String preferredLanguage;
  String? profileImageUrl;
  DateTime createdAt;
  DateTime lastLogin;

  UserModel({
    this.id,
    this.fullName,
    this.email,
    required this.phone,
    this.storeName,
    this.storeAddress,
    this.weeklyOffDay = 0,
    this.preferredCurrency = "NPR",
    this.preferredLanguage = "English",
    this.profileImageUrl,
    required this.createdAt,
    required this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'storeName': storeName,
      'storeAddress': storeAddress,
      'weeklyOffDay': weeklyOffDay,
      'preferredCurrency': preferredCurrency,
      'preferredLanguage': preferredLanguage,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      fullName: map['fullName'],
      email: map['email'],
      phone: map['phone'] ?? '',
      storeName: map['storeName'],
      storeAddress: map['storeAddress'],
      weeklyOffDay: map['weeklyOffDay'] ?? 0,
      preferredCurrency: map['preferredCurrency'] ?? 'NPR',
      preferredLanguage: map['preferredLanguage'] ?? 'English',
      profileImageUrl: map['profileImageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin: DateTime.parse(map['lastLogin']),
    );
  }
}