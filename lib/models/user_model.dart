import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String email;

  @HiveField(2)
  String passwordHash;

  @HiveField(3)
  String name;

  @HiveField(4)
  String? phone;

  @HiveField(5)
  String? profileImageUrl;

  @HiveField(6)
  String defaultCurrency;

  @HiveField(7)
  String defaultTimezone;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime? updatedAt;

  @HiveField(10)
  bool notificationsEnabled;

  UserModel({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.name,
    this.phone,
    this.profileImageUrl,
    this.defaultCurrency = 'USD',
    this.defaultTimezone = 'UTC',
    required this.createdAt,
    this.updatedAt,
    this.notificationsEnabled = true,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? passwordHash,
    String? name,
    String? phone,
    String? profileImageUrl,
    String? defaultCurrency,
    String? defaultTimezone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? notificationsEnabled,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      defaultTimezone: defaultTimezone ?? this.defaultTimezone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'passwordHash': passwordHash,
      'name': name,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'defaultCurrency': defaultCurrency,
      'defaultTimezone': defaultTimezone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      defaultCurrency: json['defaultCurrency'] as String? ?? 'USD',
      defaultTimezone: json['defaultTimezone'] as String? ?? 'UTC',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name)';
  }
}

@HiveType(typeId: 1)
class SessionModel extends HiveObject {
  @HiveField(0)
  String userId;

  @HiveField(1)
  String sessionToken;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime expiresAt;

  SessionModel({
    required this.userId,
    required this.sessionToken,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid => !isExpired;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'sessionToken': sessionToken,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      userId: json['userId'] as String,
      sessionToken: json['sessionToken'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
