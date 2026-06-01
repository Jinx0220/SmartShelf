import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final int stock;
  final int threshold;
  final int price;
  final String category;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.threshold,
    required this.price,
    required this.category,
    required this.createdAt,
  });

  bool get isLowStock => stock <= threshold;
  bool get isCriticalStock => stock == 0;
}