import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';
import '../dialogs/confirmation_dialog.dart';
import '../dialogs/edit_sale_dialog.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<Sale> _sales = [];
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    // Load sales
    final String? salesJson = prefs.getString('sales');
    if (salesJson != null && salesJson.isNotEmpty) {
      List<dynamic> decoded = json.decode(salesJson);
      setState(() {
        _sales = decoded.map((e) => Sale.fromJson(e)).toList();
        // Sort by timestamp (newest first)
        _sales.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    }

    // Load products to get current stock info
    final String? productsJson = prefs.getString('products');
    if (productsJson != null && productsJson.isNotEmpty) {
      List<dynamic> decoded = json.decode(productsJson);
      setState(() {
        _products = decoded.map((e) => Product.fromJson(e)).toList();
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteSale(Sale sale) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove from sales list
    _sales.removeWhere((s) => s.id == sale.id);
    final String salesJson = json.encode(_sales.map((e) => e.toJson()).toList());
    await prefs.setString('sales', salesJson);

    // Restore stock to product
    final productIndex = _products.indexWhere((p) => p.id == sale.productId);
    if (productIndex != -1) {
      _products[productIndex] = Product(
        id: _products[productIndex].id,
        name: _products[productIndex].name,
        stock: _products[productIndex].stock + sale.quantity,
        threshold: _products[productIndex].threshold,
        price: _products[productIndex].price,
        category: _products[productIndex].category,
        oldPrice: _products[productIndex].oldPrice,
      );

      final String productsJson = json.encode(_products.map((e) => e.toJson()).toList());
      await prefs.setString('products', productsJson);
    }

    await _loadData();
    Fluttertoast.showToast(msg: "Sale deleted and stock restored");
  }

  Future<void> _editSale(Sale sale, int newQuantity) async {
    final prefs = await SharedPreferences.getInstance();

    // Calculate quantity difference
    final int quantityDiff = newQuantity - sale.quantity;

    // Check if enough stock for increase
    final product = _products.firstWhere((p) => p.id == sale.productId);
    if (quantityDiff > 0 && product.stock < quantityDiff) {
      Fluttertoast.showToast(msg: "Not enough stock available");
      return;
    }

    // Update product stock
    final productIndex = _products.indexWhere((p) => p.id == sale.productId);
    if (productIndex != -1) {
      _products[productIndex] = Product(
        id: _products[productIndex].id,
        name: _products[productIndex].name,
        stock: _products[productIndex].stock - quantityDiff,
        threshold: _products[productIndex].threshold,
        price: _products[productIndex].price,
        category: _products[productIndex].category,
        oldPrice: _products[productIndex].oldPrice,
      );

      final String productsJson = json.encode(_products.map((e) => e.toJson()).toList());
      await prefs.setString('products', productsJson);
    }

    // Update sale record
    final updatedSale = Sale(
      id: sale.id,
      productId: sale.productId,
      productName: sale.productName,
      quantity: newQuantity,
      totalPrice: sale.unitPrice * newQuantity,
      timestamp: sale.timestamp,
      unitPrice: sale.unitPrice,
    );

    final index = _sales.indexWhere((s) => s.id == sale.id);
    if (index != -1) {
      _sales[index] = updatedSale;
    }

    final String salesJson = json.encode(_sales.map((e) => e.toJson()).toList());
    await prefs.setString('sales', salesJson);

    await _loadData();
    Fluttertoast.showToast(msg: "Sale updated successfully");
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "Sales History",
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : _sales.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppColor.secondary),
            const SizedBox(height: 16),
            Text(
              "No Sales Yet",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Log your first sale from the Sale tab",
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColor.secondary,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sales.length,
        itemBuilder: (context, index) {
          final sale = _sales[index];
          return _buildSaleCard(sale);
        },
      ),
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sale.productName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.neutral,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${sale.quantity} units",
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.attach_money, size: 14, color: AppColor.secondary),
              const SizedBox(width: 4),
              Text(
                formatCurrency(sale.totalPrice),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColor.success,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 14, color: AppColor.secondary),
              const SizedBox(width: 4),
              Text(
                _formatDate(sale.timestamp),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColor.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showEditDialog(sale),
                icon: Icon(Icons.edit, size: 16, color: AppColor.primary),
                label: Text(
                  "Edit",
                  style: GoogleFonts.manrope(color: AppColor.primary),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showDeleteConfirmation(sale),
                icon: Icon(Icons.delete, size: 16, color: AppColor.error),
                label: Text(
                  "Delete",
                  style: GoogleFonts.manrope(color: AppColor.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => EditSaleDialog(
        productName: sale.productName,
        currentQuantity: sale.quantity,
        currentTotalPrice: sale.totalPrice,
        unitPrice: sale.unitPrice,
        onSave: (newQuantity) => _editSale(sale, newQuantity),
      ),
    );
  }

  void _showDeleteConfirmation(Sale sale) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Delete Sale",
        message: "Are you sure you want to delete this sale? Stock will be restored.",
        confirmText: "Delete",
        confirmColor: AppColor.error,
        onConfirm: () => _deleteSale(sale),
      ),
    );
  }
}

// ==================== MODELS ====================
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
    category: json['category'] ?? '',
    oldPrice: json['oldPrice'] ?? json['price'],
  );
}