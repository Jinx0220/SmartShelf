import 'package:flutter/material.dart';
import '../model/sale_model.dart';
import '../model/product_model.dart';
import '../repo/sale_repo.dart';
import '../repo/product_repo.dart';

class AnalyticsViewModel extends ChangeNotifier {
  final SaleRepo _saleRepo;
  final ProductRepo _productRepo;

  AnalyticsViewModel({
    required SaleRepo saleRepo,
    required ProductRepo productRepo,
  }) : _saleRepo = saleRepo,
        _productRepo = productRepo;

  bool _loading = false;
  String? _error;
  List<SaleModel>? _sales;
  List<ProductModel>? _products;
  int _todaySales = 0;
  int _weeklySales = 0;
  int _monthlySales = 0;
  int _totalSales = 0;
  Map<String, int>? _topProducts;
  Map<String, int>? _bottomProducts;
  Map<String, List<int>>? _salesHistory;

  // Getters
  bool get loading => _loading;
  String? get error => _error;
  List<SaleModel>? get sales => _sales;
  List<ProductModel>? get products => _products;
  int get todaySales => _todaySales;
  int get weeklySales => _weeklySales;
  int get monthlySales => _monthlySales;
  int get totalSales => _totalSales;
  Map<String, int>? get topProducts => _topProducts;
  Map<String, int>? get bottomProducts => _bottomProducts;
  Map<String, List<int>>? get salesHistory => _salesHistory;

  // Setters
  setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // Load all data
  Future<void> loadAllData() async {
    setLoading(true);
    setError(null);
    try {
      await Future.wait([
        _loadSales(),
        _loadProducts(),
        _calculateTodaySales(),
        _calculateWeeklySales(),
        _calculateMonthlySales(),
        _calculateTotalSales(),
        _calculateTopProducts(),
        _calculateBottomProducts(),
        _calculateSalesHistory(),
      ]);
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Load sales
  Future<void> _loadSales() async {
    _sales = await _saleRepo.getAllSales();
  }

  // Load products
  Future<void> _loadProducts() async {
    _products = await _productRepo.getAllProduct();
  }

  // Calculate today's sales
  Future<void> _calculateTodaySales() async {
    _todaySales = await _saleRepo.getTodaySales();
  }

  // Calculate weekly sales
  Future<void> _calculateWeeklySales() async {
    _weeklySales = await _saleRepo.getWeeklySales();
  }

  // Calculate monthly sales
  Future<void> _calculateMonthlySales() async {
    _monthlySales = await _saleRepo.getMonthlySales();
  }

  // Calculate total sales
  Future<void> _calculateTotalSales() async {
    final allSales = await _saleRepo.getAllSales();
    _totalSales = allSales.fold(0, (sum, sale) => sum + sale.totalPrice);
  }

  // Calculate top products
  Future<void> _calculateTopProducts() async {
    _topProducts = await _saleRepo.getTopProducts(limit: 5);
  }

  // Calculate bottom products
  Future<void> _calculateBottomProducts() async {
    _bottomProducts = await _saleRepo.getBottomProducts(limit: 5);
  }

  // Calculate sales history (grouped by day/week/month)
  Future<void> _calculateSalesHistory() async {
    final allSales = await _saleRepo.getAllSales();
    final Map<String, List<int>> history = {};

    // Group by product
    for (var sale in allSales) {
      history[sale.productId] ??= [];
      history[sale.productId]!.add(sale.quantity);
    }

    _salesHistory = history;
  }

  // Get weekly sales data for chart
  List<DailySalesData> getWeeklySalesData() {
    final sales = _sales ?? [];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    List<DailySalesData> weeklyData = [];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final daySales = sales
          .where((s) => s.timestamp.isAfter(dayStart) && s.timestamp.isBefore(dayEnd))
          .fold(0, (sum, s) => sum + s.totalPrice);

      final dayName = _getDayName(date.weekday);
      weeklyData.add(DailySalesData(day: dayName, amount: daySales));
    }

    return weeklyData;
  }

  // Get monthly sales data for chart
  List<DailySalesData> getMonthlySalesData() {
    final sales = _sales ?? [];
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    List<DailySalesData> monthlyData = [];

    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(now.year, now.month, i);
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final daySales = sales
          .where((s) => s.timestamp.isAfter(dayStart) && s.timestamp.isBefore(dayEnd))
          .fold(0, (sum, s) => sum + s.totalPrice);

      monthlyData.add(DailySalesData(day: '$i', amount: daySales));
    }

    return monthlyData;
  }

  // Get yearly sales data for chart
  List<DailySalesData> getYearlySalesData() {
    final sales = _sales ?? [];
    final now = DateTime.now();

    List<DailySalesData> yearlyData = [];

    for (int month = 1; month <= 12; month++) {
      final monthStart = DateTime(now.year, month, 1);
      final monthEnd = DateTime(now.year, month + 1, 1);

      final monthSales = sales
          .where((s) => s.timestamp.isAfter(monthStart) && s.timestamp.isBefore(monthEnd))
          .fold(0, (sum, s) => sum + s.totalPrice);

      yearlyData.add(DailySalesData(day: _getMonthName(month - 1), amount: monthSales));
    }

    return yearlyData;
  }

  // Get product sales data for a specific product
  Future<List<DailySalesData>> getProductSalesData(String productId) async {
    final sales = await _saleRepo.getSalesForProduct(productId);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    List<DailySalesData> productData = [];

    for (int i = 29; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final daySales = sales
          .where((s) => s.timestamp.isAfter(dayStart) && s.timestamp.isBefore(dayEnd))
          .fold(0, (sum, s) => sum + s.quantity);

      productData.add(DailySalesData(
          day: '${date.day}/${date.month}',
          amount: daySales
      ));
    }

    return productData;
  }

  // Calculate total amount
  int calculateTotalAmount() {
    final sales = _sales ?? [];
    return sales.fold(0, (sum, sale) => sum + sale.totalPrice);
  }

  // Calculate percentage change
  double calculatePercentageChange(int current, int previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous * 100);
  }

  // Get top products as list with names
  List<TopProductData> getTopProductsList() {
    final map = _topProducts ?? {};
    final productMap = _products?.fold<Map<String, String>>(
      {},
          (map, product) {
        map[product.id ?? ''] = product.name ?? 'Unknown';
        return map;
      },
    ) ?? {};

    return map.entries.map((entry) {
      return TopProductData(
        name: productMap[entry.key] ?? 'Unknown',
        quantity: entry.value,
        rank: 0,
      );
    }).toList().asMap().entries.map((entry) {
      return TopProductData(
        name: entry.value.name,
        quantity: entry.value.quantity,
        rank: entry.key + 1,
      );
    }).toList();
  }

  // Get bottom products as list with names
  List<TopProductData> getBottomProductsList() {
    final map = _bottomProducts ?? {};
    final productMap = _products?.fold<Map<String, String>>(
      {},
          (map, product) {
        map[product.id ?? ''] = product.name ?? 'Unknown';
        return map;
      },
    ) ?? {};

    return map.entries.map((entry) {
      return TopProductData(
        name: productMap[entry.key] ?? 'Unknown',
        quantity: entry.value,
        rank: 0,
      );
    }).toList().asMap().entries.map((entry) {
      return TopProductData(
        name: entry.value.name,
        quantity: entry.value.quantity,
        rank: entry.key + 1,
      );
    }).toList();
  }

  String _getDayName(int index) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[index - 1];
  }

  String _getMonthName(int index) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[index];
  }
}

// Helper classes
class DailySalesData {
  final String day;
  final int amount;
  DailySalesData({required this.day, required this.amount});
}

class TopProductData {
  final String name;
  final int quantity;
  final int rank;
  TopProductData({required this.name, required this.quantity, required this.rank});
}