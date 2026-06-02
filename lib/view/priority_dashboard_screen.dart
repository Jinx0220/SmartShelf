import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/colors.dart';
import 'log_sale_screen.dart';
import 'product_list_screen.dart';

class PriorityDashboardScreen extends StatefulWidget {
  const PriorityDashboardScreen({super.key});

  @override
  State<PriorityDashboardScreen> createState() => _PriorityDashboardScreenState();
}

class _PriorityDashboardScreenState extends State<PriorityDashboardScreen> {
  int todaySales = 0;
  int weeklySales = 0;
  int lowStockCount = 0;
  String storeName = "Everest Kirana Store";
  String greeting = "";

  List<CriticalProduct> criticalProducts = [];
  List<TopProduct> topProducts = [];
  List<Product> _products = [];
  List<Sale> _sales = [];

  @override
  void initState() {
    super.initState();
    _loadStoreName();
    _setGreeting();
    _loadData();
  }

  Future<void> _loadStoreName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      storeName = prefs.getString('store_name') ?? 'Everest Kirana Store';
    });
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = "Good morning";
    } else if (hour < 17) {
      greeting = "Good afternoon";
    } else {
      greeting = "Good evening";
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load products
    final String? productsJson = prefs.getString('products');
    if (productsJson != null && productsJson.isNotEmpty) {
      try {
        List<dynamic> decoded = json.decode(productsJson);
        setState(() {
          _products = decoded.map((e) => Product.fromJson(e)).toList();
        });
      } catch (e) {
        _products = [];
      }
    }

    // Load sales
    final String? salesJson = prefs.getString('sales');
    if (salesJson != null && salesJson.isNotEmpty) {
      try {
        List<dynamic> decoded = json.decode(salesJson);
        setState(() {
          _sales = decoded.map((e) => Sale.fromJson(e)).toList();
        });
      } catch (e) {
        _sales = [];
      }
    }

    _calculateDashboardData();
  }

  void _calculateDashboardData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = today.subtract(const Duration(days: 7));

    // Calculate today's sales
    todaySales = _sales
        .where((sale) => sale.timestamp.isAfter(today))
        .fold(0, (sum, sale) => sum + sale.totalPrice);

    // Calculate weekly sales
    weeklySales = _sales
        .where((sale) => sale.timestamp.isAfter(weekAgo))
        .fold(0, (sum, sale) => sum + sale.totalPrice);

    // Calculate low stock count
    lowStockCount = _products.where((p) => p.stock <= p.threshold).length;

    // Calculate top 5 products by sales quantity
    Map<String, int> productSales = {};
    for (var sale in _sales) {
      productSales[sale.productId] = (productSales[sale.productId] ?? 0) + sale.quantity;
    }

    var sortedProducts = productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    topProducts = [];
    for (int i = 0; i < sortedProducts.length && i < 5; i++) {
      final product = _products.firstWhere(
            (p) => p.id == sortedProducts[i].key,
        orElse: () => Product(id: '', name: 'Unknown', stock: 0, threshold: 0, price: 0, category: ''),
      );
      topProducts.add(TopProduct(
        name: product.name,
        quantity: sortedProducts[i].value,
        rank: i + 1,
      ));
    }

    // Calculate critical products (stock <= threshold, sorted by stock ascending)
    criticalProducts = _products
        .where((p) => p.stock <= p.threshold)
        .map((p) => CriticalProduct(
      name: p.name,
      stock: p.stock,
      threshold: p.threshold,
      productId: p.id,
    ))
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    setState(() {});
  }

  Future<void> _updateStockAfterOrder(CriticalProduct product, int orderQty) async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsJson = prefs.getString('products');

    if (productsJson != null && productsJson.isNotEmpty) {
      List<dynamic> decoded = json.decode(productsJson);
      List<Product> products = decoded.map((e) => Product.fromJson(e)).toList();

      // Find and update the product
      final index = products.indexWhere((p) => p.id == product.productId);
      if (index != -1) {
        final updatedProduct = Product(
          id: products[index].id,
          name: products[index].name,
          stock: products[index].stock + orderQty,
          threshold: products[index].threshold,
          price: products[index].price,
          category: products[index].category,
          oldPrice: products[index].oldPrice,
        );
        products[index] = updatedProduct;

        // Save back to SharedPreferences
        final String updatedJson = json.encode(products.map((e) => e.toJson()).toList());
        await prefs.setString('products', updatedJson);

        // Reload dashboard data
        await _loadData();
        setState(() {});
      }
    }
  }

  void _showOrderDialog(CriticalProduct product) {
    final TextEditingController quantityController = TextEditingController(
        text: (product.threshold - product.stock).toString()
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Order ${product.name}",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.primary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Current Stock:", style: GoogleFonts.manrope(fontSize: 14)),
                      Text("${product.stock} units", style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Threshold:", style: GoogleFonts.manrope(fontSize: 14)),
                      Text("${product.threshold} units", style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Recommended:", style: GoogleFonts.manrope(fontSize: 14, color: AppColor.success)),
                      Text("${product.threshold - product.stock} units",
                          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppColor.success)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Order Quantity",
                labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColor.primary, width: 2),
                ),
                suffixText: "units",
                suffixStyle: GoogleFonts.manrope(color: AppColor.secondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.manrope(color: AppColor.secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              int orderQty = int.tryParse(quantityController.text) ?? 0;
              if (orderQty > 0) {
                await _updateStockAfterOrder(product, orderQty);
                if (mounted) Navigator.pop(context);
                _showOrderSuccessDialog(product.name, orderQty);
              } else {
                Fluttertoast.showToast(msg: "Please enter valid quantity");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.success,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              "Confirm Order",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderSuccessDialog(String productName, int quantity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColor.success),
            const SizedBox(width: 8),
            Text(
              "Order Placed!",
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
                color: AppColor.success,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Ordered $quantity x $productName",
              style: GoogleFonts.manrope(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              "Stock has been updated",
              style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: GoogleFonts.manrope(color: AppColor.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGreetingHeader(),
                const SizedBox(height: 16),
                _buildSalesCards(),
                const SizedBox(height: 16),
                if (lowStockCount > 0) _buildLowStockAlert(),
                const SizedBox(height: 24),
                if (topProducts.isNotEmpty) _buildTopProductsSection(),
                const SizedBox(height: 24),
                if (criticalProducts.isNotEmpty) _buildCriticalStockSection(),
                const SizedBox(height: 32),
                _buildActionButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.primary, AppColor.primary.withValues(alpha: 0.7)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(Icons.store, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  _getFormattedDate(),
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TODAY'S SALES",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColor.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "NPR $todaySales",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColor.neutral,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "WEEKLY SALES",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColor.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "NPR $weeklySales",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColor.neutral,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "LOW STOCK",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColor.secondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "$lowStockCount",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColor.error,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.warning, size: 16, color: AppColor.error),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlert() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_amber_rounded, color: AppColor.error, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "$lowStockCount products are running low on stock. Please reorder soon.",
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColor.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsSection() {
    if (topProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  "Top 5 Selling Products",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.neutral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topProducts.map((product) => _buildTopProductRow(product)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductRow(TopProduct product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: product.rank == 1
                  ? Colors.amber.withValues(alpha: 0.2)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "${product.rank}",
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: product.rank == 1 ? Colors.amber : AppColor.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product.name,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColor.neutral,
              ),
            ),
          ),
          Text(
            "${product.quantity} units",
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColor.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalStockSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 20, color: AppColor.error),
                const SizedBox(width: 8),
                Text(
                  "Critical Low-Stock Products",
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.neutral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...criticalProducts.take(5).map((product) => _buildCriticalProductRow(product)),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalProductRow(CriticalProduct product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.neutral,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Stock: ${product.stock} (Threshold: ${product.threshold})",
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColor.secondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showOrderDialog(product),
            style: ElevatedButton.styleFrom(
              backgroundColor: product.stock == 0 ? AppColor.error : AppColor.warning,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              product.stock == 0 ? "Order Now" : "Restock",
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LogSaleScreen()),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.sell, size: 20),
              label: Text(
                "Log Sale",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductListScreen()),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                "Add Product",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.primary,
                side: BorderSide(color: AppColor.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

// Models
class CriticalProduct {
  final String name;
  final int stock;
  final int threshold;
  final String productId;
  CriticalProduct({required this.name, required this.stock, required this.threshold, required this.productId});
}

class TopProduct {
  final String name;
  final int quantity;
  final int rank;
  TopProduct({required this.name, required this.quantity, required this.rank});
}

class Product {
  final String id;
  final String name;
  int stock;
  final int threshold;
  final int price;
  final String category;
  final int? oldPrice;

  Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.threshold,
    required this.price,
    required this.category,
    this.oldPrice,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'stock': stock,
    'threshold': threshold,
    'price': price,
    'category': category,
    'oldPrice': oldPrice,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    stock: json['stock'] ?? 0,
    threshold: json['threshold'] ?? 0,
    price: json['price'] ?? 0,
    category: json['category'] ?? 'Grocery',
    oldPrice: json['oldPrice'] ?? json['price'],
  );
}

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'totalPrice': totalPrice,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: json['id'] ?? '',
    productId: json['productId'] ?? '',
    productName: json['productName'] ?? '',
    quantity: json['quantity'] ?? 0,
    totalPrice: json['totalPrice'] ?? 0,
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
  );
}