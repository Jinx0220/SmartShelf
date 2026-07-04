import 'package:flutter/material.dart';
import '../model/product_model.dart';
import '../model/sale_model.dart';
import '../model/user_model.dart';
import '../repo/product_repo.dart';
import '../repo/sale_repo.dart';
import '../repo/auth_repo.dart';

class DashboardViewModel extends ChangeNotifier {
  final ProductRepo _productRepo;
  final SaleRepo _saleRepo;
  final AuthRepo _authRepo;

  DashboardViewModel({
    required ProductRepo productRepo,
    required SaleRepo saleRepo,
    required AuthRepo authRepo,
  }) : _productRepo = productRepo,
        _saleRepo = saleRepo,
        _authRepo = authRepo;

  bool _loading = false;
  String? _error;
  List<ProductModel> _products = [];
  List<SaleModel> _sales = [];
  UserModel? _user;
  int _todaySales = 0;
  int _weeklySales = 0;
  int _lowStockCount = 0;
  int _totalProducts = 0;
  List<ProductModel> _criticalProducts = [];
  Map<String, int> _topProducts = {};
  String _greeting = 'Good morning';

  // Getters
  bool get loading => _loading;
  String? get error => _error;
  List<ProductModel> get products => _products;
  List<SaleModel> get sales => _sales;
  UserModel? get user => _user;
  int get todaySales => _todaySales;
  int get weeklySales => _weeklySales;
  int get lowStockCount => _lowStockCount;
  int get totalProducts => _totalProducts;
  List<ProductModel> get criticalProducts => _criticalProducts;
  Map<String, int> get topProducts => _topProducts;
  String get greeting => _greeting;

  // Setters
  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  // Load dashboard data
  Future<void> loadDashboardData() async {
    setLoading(true);
    setError(null);
    try {
      // Load all data in parallel
      await Future.wait([
        _loadProducts(),
        _loadSales(),
        _loadUser(),
      ]);

      // Calculate derived data after loading
      _calculateGreeting();
      _calculateTodaySales();
      _calculateWeeklySales();
      _calculateLowStockCount();
      _calculateCriticalProducts();
      _calculateTopProducts();
      _calculateTotalProducts();

      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  // Load products
  Future<void> _loadProducts() async {
    final result = await _productRepo.getAllProduct();
    _products = result ?? [];
  }

  // Load sales
  Future<void> _loadSales() async {
    final result = await _saleRepo.getAllSales();
    _sales = result ?? [];
  }

  // Load user
  Future<void> _loadUser() async {
    _user = await _authRepo.getUserProfile('current');
  }

  // Calculate greeting
  void _calculateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good morning';
    } else if (hour < 17) {
      _greeting = 'Good afternoon';
    } else {
      _greeting = 'Good evening';
    }
  }

  // Calculate today's sales
  void _calculateTodaySales() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _todaySales = _sales
        .where((s) => s.timestamp.isAfter(today))
        .fold(0, (sum, s) => sum + s.totalPrice);
  }

  // Calculate weekly sales
  void _calculateWeeklySales() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));
    _weeklySales = _sales
        .where((s) => s.timestamp.isAfter(weekAgo))
        .fold(0, (sum, s) => sum + s.totalPrice);
  }

  // Calculate low stock count
  void _calculateLowStockCount() {
    _lowStockCount = _products.where((p) => p.isLowStock).length;
  }

  // Calculate critical products
  void _calculateCriticalProducts() {
    _criticalProducts = _products
        .where((p) => p.isLowStock)
        .toList()
      ..sort((a, b) => (a.stock ?? 0).compareTo(b.stock ?? 0));
  }

  // Calculate top products
  void _calculateTopProducts() async {
    final result = await _saleRepo.getTopProducts(limit: 5);
    _topProducts = result ?? {};
  }

  // Calculate total products
  void _calculateTotalProducts() {
    _totalProducts = _products.length;
  }

  // Refresh dashboard
  Future<void> refreshDashboard() async {
    await loadDashboardData();
  }

  // Get total sales (all time)
  int getTotalSales() {
    return _sales.fold(0, (sum, sale) => sum + sale.totalPrice);
  }

  // Get sales count (total)
  int getTotalSalesCount() {
    return _sales.length;
  }

  // Get total products count
  int getTotalProductsCount() {
    return _products.length;
  }

  // Get out of stock count
  int getOutOfStockCount() {
    return _products.where((p) => p.isOutOfStock).length;
  }

  // Get formatted date for display
  String getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  // Get store name
  String getStoreName() {
    return _user?.storeName ?? 'My Store';
  }

  // Get user name
  String getUserName() {
    return _user?.fullName ?? 'User';
  }

  // Check if dashboard is ready
  bool isDashboardReady() {
    return _products.isNotEmpty && _sales.isNotEmpty && !_loading;
  }

  // Get percentage change
  double getPercentageChange(int current, int previous) {
    if (previous == 0) return 0;
    return ((current - previous) / previous * 100);
  }

  // Get today's date range
  String getTodayDateRange() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  // Get week range
  String getWeekRange() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${startOfWeek.day}/${startOfWeek.month} - ${endOfWeek.day}/${endOfWeek.month}';
  }

  // Top products list with names
  List<DashboardTopProduct> getTopProductsList() {
    final productMap = <String, String>{};
    for (var product in _products) {
      if (product.id != null) {
        productMap[product.id!] = product.name ?? 'Unknown';
      }
    }

    final List<DashboardTopProduct> result = [];
    int rank = 1;
    for (var entry in _topProducts.entries) {
      result.add(DashboardTopProduct(
        name: productMap[entry.key] ?? 'Unknown',
        quantity: entry.value,
        rank: rank,
      ));
      rank++;
    }
    return result;
  }

  // Critical products with details
  List<DashboardCriticalProduct> getCriticalProductsList() {
    return _criticalProducts.map((product) {
      return DashboardCriticalProduct(
        name: product.name ?? 'Unknown',
        stock: product.stock ?? 0,
        threshold: product.threshold ?? 0,
        productId: product.id ?? '',
      );
    }).toList();
  }
}

// Helper classes
class DashboardTopProduct {
  final String name;
  final int quantity;
  final int rank;
  DashboardTopProduct({
    required this.name,
    required this.quantity,
    required this.rank,
  });
}

class DashboardCriticalProduct {
  final String name;
  final int stock;
  final int threshold;
  final String productId;
  DashboardCriticalProduct({
    required this.name,
    required this.stock,
    required this.threshold,
    required this.productId,
  });
}