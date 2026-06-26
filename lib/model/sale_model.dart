import 'package:cloud_firestore/cloud_firestore.dart';

class SaleModel {
  final String? id;
  final String productId;
  final String productName;
  final int quantity;
  final int totalPrice;
  final int unitPrice;
  final DateTime timestamp;
  final String? notes;

  SaleModel({
    this.id,
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
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'unitPrice': unitPrice,
      'timestamp': Timestamp.fromDate(timestamp),
      'notes': notes,
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return SaleModel(
      id: id ?? map['id'] as String?,
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      quantity: map['quantity'] as int,
      totalPrice: map['totalPrice'] as int,
      unitPrice: map['unitPrice'] as int,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
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