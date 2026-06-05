import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';
import '../dialogs/confirmation_dialog.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  List<Sale> _productSales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    // Load product
    final String? productsJson = prefs.getString('products');
    if (productsJson != null && productsJson.isNotEmpty) {
      List<dynamic> decoded = json.decode(productsJson);
      List<Product> products = decoded.map((e) => Product.fromJson(e)).toList();
      _product = products.firstWhere((p) => p.id == widget.productId);
    }

    // Load sales for this product
    final String? salesJson = prefs.getString('sales');
    if (salesJson != null && salesJson.isNotEmpty) {
      List<dynamic> decoded = json.decode(salesJson);
      List<Sale> allSales = decoded.map((e) => Sale.fromJson(e)).toList();
      _productSales = allSales
          .where((s) => s.productId == widget.productId)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    setState(() => _isLoading = false);
  }

  List<FlSpot> _getSalesSpots() {
    if (_productSales.isEmpty) return [];

    // Group by day and sum quantities
    Map<DateTime, int> dailySales = {};
    for (var sale in _productSales) {
      final day = DateTime(sale.timestamp.year, sale.timestamp.month, sale.timestamp.day);
      dailySales[day] = (dailySales[day] ?? 0) + sale.quantity;
    }

    // Sort dates and create spots
    final sortedDates = dailySales.keys.toList()..sort();
    if (sortedDates.isEmpty) return [];

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedDates.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailySales[sortedDates[i]]!.toDouble()));
    }
    return spots;
  }

  Future<void> _editProduct() async {
    // Navigate to edit product (using add/edit dialog from product_list_screen)
    // For now, show a toast
    Fluttertoast.showToast(msg: "Edit functionality coming soon");
  }

  Future<void> _deleteProduct() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if product has sales
    if (_productSales.isNotEmpty) {
      Fluttertoast.showToast(msg: "Cannot delete product with sales history");
      return;
    }

    // Load all products and remove this one
    final String? productsJson = prefs.getString('products');
    if (productsJson != null && productsJson.isNotEmpty) {
      List<dynamic> decoded = json.decode(productsJson);
      List<Product> products = decoded.map((e) => Product.fromJson(e)).toList();
      products.removeWhere((p) => p.id == widget.productId);

      final String updatedJson = json.encode(products.map((e) => e.toJson()).toList());
      await prefs.setString('products', updatedJson);

      Fluttertoast.showToast(msg: "Product deleted");
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Product Details", style: GoogleFonts.spaceGrotesk(color: Colors.white)),
          backgroundColor: AppColor.primary,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColor.primary)),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Product Details", style: GoogleFonts.spaceGrotesk(color: Colors.white)),
          backgroundColor: AppColor.primary,
        ),
        body: Center(
          child: Text(
            "Product not found",
            style: GoogleFonts.manrope(color: AppColor.secondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          _product!.name,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _editProduct,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () => _showDeleteConfirmation(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Current Stock",
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: AppColor.secondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _product!.isLowStock
                              ? AppColor.error.withValues(alpha: 0.1)
                              : AppColor.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _product!.isLowStock ? "Low Stock" : "In Stock",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _product!.isLowStock ? AppColor.error : AppColor.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${_product!.stock} units",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _product!.isLowStock ? AppColor.error : AppColor.success,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip("Price", formatCurrency(_product!.price)),
                      _buildInfoChip("Threshold", "${_product!.threshold} units"),
                      _buildInfoChip("Category", _product!.category),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sales Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sales History",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColor.neutral,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_productSales.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "No sales recorded yet",
                          style: GoogleFonts.manrope(color: AppColor.secondary),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: true),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (_productSales.isEmpty) return const Text("");
                                  final index = value.toInt();
                                  if (index >= 0 && index < _getSalesSpots().length) {
                                    final date = _productSales[index].timestamp;
                                    return Text(
                                      "${date.day}/${date.month}",
                                      style: GoogleFonts.manrope(fontSize: 10),
                                    );
                                  }
                                  return const Text("");
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: GoogleFonts.manrope(fontSize: 10),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _getSalesSpots(),
                              isCurved: true,
                              color: AppColor.primary,
                              barWidth: 3,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColor.primary.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Recent Sales
            if (_productSales.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recent Sales",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.neutral,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._productSales.reversed.take(5).map((sale) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(sale.timestamp),
                            style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
                          ),
                          Text(
                            "${sale.quantity} units",
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColor.primary,
                            ),
                          ),
                          Text(
                            formatCurrency(sale.totalPrice),
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColor.success,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColor.neutral,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Delete Product",
        message: "Are you sure you want to delete ${_product!.name}? This cannot be undone.",
        confirmText: "Delete",
        confirmColor: AppColor.error,
        onConfirm: _deleteProduct,
      ),
    );
  }
}

// ==================== MODELS ====================
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

  bool get isLowStock => stock <= threshold;

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
    category: json['category'] ?? '',
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
  final int unitPrice;

  Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.timestamp,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'totalPrice': totalPrice,
    'timestamp': timestamp.toIso8601String(),
    'unitPrice': unitPrice,
  };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: json['id'] ?? '',
    productId: json['productId'] ?? '',
    productName: json['productName'] ?? '',
    quantity: json['quantity'] ?? 0,
    totalPrice: json['totalPrice'] ?? 0,
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    unitPrice: json['unitPrice'] ?? (json['totalPrice'] / json['quantity']).round(),
  );
}