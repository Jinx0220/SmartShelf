import 'package:cloud_firestore/cloud_firestore.dart';

class SaleModel {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final int totalPrice;
  final int unitPrice;
  final DateTime timestamp;
  final String? notes;

  SaleModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.unitPrice,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'unitPrice': unitPrice,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map) {
    return SaleModel(
      id: map['id'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 0,
      totalPrice: map['totalPrice'] as int? ?? 0,
      unitPrice: map['unitPrice'] as int? ?? 0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'] as String?,
    );
  }

  SaleModel copyWith({
    String? id,
    String? productId,
    String? productName,
    int? quantity,
    int? totalPrice,
    int? unitPrice,
    DateTime? timestamp,
    String? notes,
  }) {
    return SaleModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      unitPrice: unitPrice ?? this.unitPrice,
      timestamp: timestamp ?? this.timestamp,
      notes: notes ?? this.notes,
    );
  }
}