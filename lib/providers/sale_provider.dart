import 'package:flutter/material.dart';
import '../models/sale.dart';

class SaleProvider extends ChangeNotifier {
  List<Sale> _recentSales = [];
  int _todaySales = 0;
  int _weeklySales = 0;
  bool _isLoading = false;

  List<Sale> get recentSales => _recentSales;
  int get todaySales => _todaySales;
  int get weeklySales => _weeklySales;
  bool get isLoading => _isLoading;

  Future<void> loadAllSalesData() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _todaySales = 1250;
    _weeklySales = 8450;

    _recentSales = [
      Sale(
        id: '1',
        productId: 'p1',
        productName: 'Basmati Rice',
        quantity: 2,
        totalPrice: 600,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Sale(
        id: '2',
        productId: 'p2',
        productName: 'MOMO Chutney',
        quantity: 3,
        totalPrice: 390,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Sale(
        id: '3',
        productId: 'p3',
        productName: 'Cooking Oil',
        quantity: 1,
        totalPrice: 180,
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      ),
      Sale(
        id: '4',
        productId: 'p4',
        productName: 'Wheat Flour',
        quantity: 2,
        totalPrice: 120,
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Sale(
        id: '5',
        productId: 'p5',
        productName: 'Sugar',
        quantity: 1,
        totalPrice: 85,
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logSale(String productId, String productName, int quantity, int price) async {
    final newSale = Sale(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: productId,
      productName: productName,
      quantity: quantity,
      totalPrice: price * quantity,
      timestamp: DateTime.now(),
    );

    _recentSales.insert(0, newSale);
    if (_recentSales.length > 10) {
      _recentSales = _recentSales.take(10).toList();
    }

    _todaySales += price * quantity;
    _weeklySales += price * quantity;

    notifyListeners();
  }
}