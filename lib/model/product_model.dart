import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String? id;
  final String name;
  final double price;
  final int stock;
  final int threshold;
  final String category;
  final int? oldPrice;
  final String? imageUrl;
  final bool isDiscontinued;
  final DateTime createdAt;
  final DateTime updatedAt;

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
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => stock <= threshold;
  bool get isOutOfStock => stock == 0;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stock': stock,
      'threshold': threshold,
      'category': category,
      'oldPrice': oldPrice,
      'imageUrl': imageUrl,
      'isDiscontinued': isDiscontinued,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ProductModel(
      id: id ?? map['id'] as String?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int,
      threshold: map['threshold'] as int,
      category: map['category'] as String,
      oldPrice: map['oldPrice'] as int?,
      imageUrl: map['imageUrl'] as String?,
      isDiscontinued: map['isDiscontinued'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    double? price,
    int? stock,
    int? threshold,
    String? category,
    int? oldPrice,
    String? imageUrl,
    bool? isDiscontinued,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}