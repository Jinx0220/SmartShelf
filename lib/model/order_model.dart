import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  String? id;
  List<OrderItemModel> items;
  DateTime generatedDate;
  bool isPlaced;
  DateTime? placedDate;
  String? supplierNotes;

  OrderModel({
    this.id,
    required this.items,
    required this.generatedDate,
    this.isPlaced = false,
    this.placedDate,
    this.supplierNotes,
  });

  int get totalItems => items.length;
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.finalQuantity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((e) => e.toMap()).toList(),
      'generatedDate': generatedDate.toIso8601String(),
      'isPlaced': isPlaced,
      'placedDate': placedDate?.toIso8601String(),
      'supplierNotes': supplierNotes,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return OrderModel(
      id: documentId ?? map['id'] as String?,
      items: map['items'] != null
          ? (map['items'] as List).map((e) => OrderItemModel.fromMap(Map<String, dynamic>.from(e as Map))).toList()
          : [],
      generatedDate: parseDate(map['generatedDate']),
      isPlaced: map['isPlaced'] as bool? ?? false,
      placedDate: parseNullableDate(map['placedDate']),
      supplierNotes: map['supplierNotes'] as String?,
    );
  }
}

class OrderItemModel {
  String productId;
  String productName;
  int suggestedQuantity;
  int finalQuantity;
  int currentStock;
  int threshold;

  OrderItemModel({
    required this.productId,
    required this.productName,
    required this.suggestedQuantity,
    required this.finalQuantity,
    required this.currentStock,
    required this.threshold,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'suggestedQuantity': suggestedQuantity,
      'finalQuantity': finalQuantity,
      'currentStock': currentStock,
      'threshold': threshold,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? 'Unknown Item',
      suggestedQuantity: map['suggestedQuantity'] as int? ?? 0,
      finalQuantity: map['finalQuantity'] as int? ?? 0,
      currentStock: map['currentStock'] as int? ?? 0,
      threshold: map['threshold'] as int? ?? 0,
    );
  }

  int get recommendedOrder => suggestedQuantity;
  int get stockDeficit => threshold - currentStock;
}