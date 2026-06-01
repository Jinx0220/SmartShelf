import 'package:flutter/material.dart';

class Sale {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final int totalPrice;
  final DateTime timestamp;

  Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.timestamp,
  });
}