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

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String?,
      items: (map['items'] as List)
          .map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      generatedDate: DateTime.parse(map['generatedDate'] as String),
      isPlaced: map['isPlaced'] as bool? ?? false,
      placedDate: map['placedDate'] != null
          ? DateTime.parse(map['placedDate'] as String)
          : null,
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
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      suggestedQuantity: map['suggestedQuantity'] as int,
      finalQuantity: map['finalQuantity'] as int,
      currentStock: map['currentStock'] as int,
      threshold: map['threshold'] as int,
    );
  }

  int get recommendedOrder => suggestedQuantity;
  int get stockDeficit => threshold - currentStock;
}