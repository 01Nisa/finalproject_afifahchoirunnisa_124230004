import 'package:hive/hive.dart';

part 'tawaran_model.g.dart';

@HiveType(typeId: 5)
class TawaranModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String lelangId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final double hargaTawaran;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final bool isWinner;

  TawaranModel({
    required this.id,
    required this.lelangId,
    required this.userId,
    required this.hargaTawaran,
    required this.timestamp,
    this.isWinner = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lelang_id': lelangId,
      'user_id': userId,
      'harga_tawaran': hargaTawaran,
      'timestamp': timestamp.toIso8601String(),
      'is_winner': isWinner,
    };
  }

  factory TawaranModel.fromJson(dynamic json) {
    final data =
        json is Map<String, dynamic> ? json : json as Map<String, dynamic>;
    return TawaranModel(
      id: data['tawaran_id'] as String? ??
          data['id'] as String? ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      lelangId:
          data['lelang_id'] as String? ?? data['lelangId'] as String? ?? '',
      userId: data['user_id'] as String? ?? data['userId'] as String? ?? '',
      hargaTawaran: (data['harga_tawaran'] as num?)?.toDouble() ??
          (data['hargaTawaran'] as num?)?.toDouble() ??
          0.0,
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'].toString())
          : DateTime.now(),
      isWinner:
          data['is_winner'] as bool? ?? data['isWinner'] as bool? ?? false,
    );
  }

  TawaranModel copyWith({
    String? id,
    String? lelangId,
    String? userId,
    double? hargaTawaran,
    DateTime? timestamp,
    bool? isWinner,
  }) {
    return TawaranModel(
      id: id ?? this.id,
      lelangId: lelangId ?? this.lelangId,
      userId: userId ?? this.userId,
      hargaTawaran: hargaTawaran ?? this.hargaTawaran,
      timestamp: timestamp ?? this.timestamp,
      isWinner: isWinner ?? this.isWinner,
    );
  }
}
