import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String? id;
  final String name;
  final double price;
  final int stock;
  final int threshold;
  final String category;
  final double? oldPrice;
  final String? imageUrl;
  final bool isDiscontinued;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? barcode;
  final String? imagePath;

  ProductModel({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.threshold,
    required this.category,
    this.oldPrice,
    this.imageUrl,
    this.isDiscontinued = false,
    this.barcode,
    this.imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isLowStock => stock <= threshold;
  bool get isOutOfStock => stock == 0;

  factory ProductModel.fromCsvRow(List<dynamic> row, String generatedId) {
    return ProductModel(
      id: generatedId,
      name: row.isNotEmpty ? row[0].toString().trim() : 'Unnamed Demo Item',
      price: row.length > 1 ? (double.tryParse(row[1].toString()) ?? 0.0) : 0.0,
      stock: row.length > 2 ? (int.tryParse(row[2].toString()) ?? 0) : 0,
      threshold: row.length > 3 ? (int.tryParse(row[3].toString()) ?? 5) : 5,
      category: row.length > 4 ? row[4].toString().trim() : 'General',
      barcode: row.length > 5 ? row[5].toString().trim() : null,
      isDiscontinued: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'threshold': threshold,
      'category': category,
      'oldPrice': oldPrice,
      'imageUrl': imageUrl,
      'isDiscontinued': isDiscontinued,
      'barcode': barcode,
      'imagePath': imagePath,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    // Adaptive date parsing helper
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ProductModel(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      stock: map['stock'] as int? ?? 0,
      threshold: map['threshold'] as int? ?? 0,
      category: map['category'] as String? ?? '',
      oldPrice: (map['oldPrice'] as num?)?.toDouble(),
      imageUrl: map['imageUrl'] as String?,
      isDiscontinued: map['isDiscontinued'] as bool? ?? false,
      barcode: map['barcode'] as String?,
      imagePath: map['imagePath'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    int? stock,
    int? threshold,
    String? category,
    double? oldPrice,
    String? imageUrl,
    bool? isDiscontinued,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? barcode,
    String? imagePath,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      threshold: threshold ?? this.threshold,
      category: category ?? this.category,
      oldPrice: oldPrice ?? this.oldPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      isDiscontinued: isDiscontinued ?? this.isDiscontinued,
      barcode: barcode ?? this.barcode,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      // Note: Kept DateTime.now() fallback to auto-update modification logs during code mutations
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}