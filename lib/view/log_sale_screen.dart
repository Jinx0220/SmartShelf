import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../dialogs/negative_stock_dialog.dart';
import '../dialogs/price_change_dialog.dart';

class LogSaleScreen extends StatefulWidget {
  const LogSaleScreen({super.key});

  @override
  State<LogSaleScreen> createState() => _LogSaleScreenState();
}

class _LogSaleScreenState extends State<LogSaleScreen> {
  Product? selectedProduct;
  int quantity = 1;
  final TextEditingController quantityController = TextEditingController(text: '1');
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // ==================== DATA METHODS (Future Firebase Ready) ====================

  Future<List<Product>> _loadProductsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsJson = prefs.getString('products');

    if (productsJson != null && productsJson.isNotEmpty) {
      try {
        List<dynamic> decoded = json.decode(productsJson);
        return decoded.map((e) => Product.fromJson(e)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  Future<void> _saveProductsToStorage(List<Product> products) async {
    final prefs = await SharedPreferences.getInstance();
    final String productsJson = json.encode(products.map((e) => e.toJson()).toList());
    await prefs.setString('products', productsJson);
  }

  Future<void> _saveSaleToStorage(Sale sale) async {
    final prefs = await SharedPreferences.getInstance();
    final String? existingSalesJson = prefs.getString('sales');
    List<Sale> sales = [];

    if (existingSalesJson != null && existingSalesJson.isNotEmpty) {
      try {
        List<dynamic> decoded = json.decode(existingSalesJson);
        sales = decoded.map((e) => Sale.fromJson(e)).toList();
      } catch (e) {
        sales = [];
      }
    }

    sales.add(sale);
    final String salesJson = json.encode(sales.map((e) => e.toJson()).toList());
    await prefs.setString('sales', salesJson);
  }

  // ==================== SALE METHODS ====================

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    _products = await _loadProductsFromStorage();

    if (_products.isEmpty) {
      await _loadDemoData();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadDemoData() async {
    _products = [
      Product(
        id: '1',
        name: 'Basmati Rice',
        stock: 5,
        threshold: 10,
        price: 300,
        category: 'Grocery',
        oldPrice: 300,
      ),
      Product(
        id: '2',
        name: 'Momo Chutney',
        stock: 8,
        threshold: 5,
        price: 130,
        category: 'Snacks',
        oldPrice: 100,
      ),
      Product(
        id: '3',
        name: 'Cooking Oil',
        stock: 2,
        threshold: 8,
        price: 180,
        category: 'Grocery',
        oldPrice: 180,
      ),
      Product(
        id: '4',
        name: 'Milk 1L',
        stock: 0,
        threshold: 10,
        price: 90,
        category: 'Dairy',
        oldPrice: 90,
      ),
      Product(
        id: '5',
        name: 'Wheat Flour',
        stock: 2,
        threshold: 10,
        price: 60,
        category: 'Grocery',
        oldPrice: 60,
      ),
      Product(
        id: '6',
        name: 'Tea Leaves',
        stock: 1,
        threshold: 8,
        price: 120,
        category: 'Beverages',
        oldPrice: 120,
      ),
    ];
    await _saveProductsToStorage(_products);
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  void _processSale() {
    if (selectedProduct == null) {
      Fluttertoast.showToast(msg: "Please select a product");
      return;
    }

    final product = selectedProduct!;
    final saleQuantity = quantity;

    if (saleQuantity > product.stock) {
      showDialog(
        context: context,
        builder: (context) => NegativeStockDialog(
          productName: product.name,
          requestedQty: saleQuantity,
          currentStock: product.stock,
          onLogAnyway: () {
            Navigator.pop(context);
            _completeSale(product: product, quantity: saleQuantity, ignoreStock: true);
          },
        ),
      );
      return;
    }

    if (product.oldPrice != null && product.price != product.oldPrice) {
      showDialog(
        context: context,
        builder: (context) => PriceChangeDialog(
          productName: product.name,
          oldPrice: product.oldPrice!,
          newPrice: product.price,
          onConfirm: () {
            Navigator.pop(context);
            _completeSale(product: product, quantity: saleQuantity);
          },
        ),
      );
      return;
    }

    _completeSale(product: product, quantity: saleQuantity);
  }

  Future<void> _completeSale({
    required Product product,
    required int quantity,
    bool ignoreStock = false,
  }) async {
    // Update stock
    final productIndex = _products.indexWhere((p) => p.id == product.id);
    if (productIndex != -1) {
      final newStock = product.stock - quantity;

      _products[productIndex] = Product(
        id: product.id,
        name: product.name,
        stock: newStock < 0 ? 0 : newStock,
        threshold: product.threshold,
        price: product.price,
        category: product.category,
        oldPrice: product.oldPrice,
      );

      await _saveProductsToStorage(_products);
    }

    // Save sale record
    final sale = Sale(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      totalPrice: product.price * quantity,
      timestamp: DateTime.now(),
    );
    await _saveSaleToStorage(sale);

    // Reset form
    setState(() {
      selectedProduct = null;
      this.quantity = 1;
      quantityController.text = '1';
    });

    // Show success dialog
    _showSaleSuccessDialog(productName: product.name, quantity: quantity, totalPrice: product.price * quantity);
  }

  void _showSaleSuccessDialog({
    required String productName,
    required int quantity,
    required int totalPrice,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColor.success),
            const SizedBox(width: 8),
            Text(
              "Sale Completed",
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
                color: AppColor.success,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sold ${quantity}x $productName",
              style: GoogleFonts.manrope(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              "Total: NPR $totalPrice",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColor.primary,
              ),
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
            child: Text(
              "OK",
              style: GoogleFonts.manrope(color: AppColor.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = selectedProduct != null ? selectedProduct!.price * quantity : 0;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "Log Sale",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : _products.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 64, color: AppColor.secondary),
            const SizedBox(height: 16),
            Text(
              "No Products Found",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please add products from the Products tab",
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColor.secondary,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Product",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Product>(
                  isExpanded: true,
                  hint: Text(
                    "Choose a product",
                    style: GoogleFonts.manrope(color: AppColor.secondary),
                  ),
                  value: selectedProduct,
                  items: _products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(
                        "${product.name} - NPR ${product.price} (Stock: ${product.stock})",
                        style: GoogleFonts.manrope(color: AppColor.neutral),
                      ),
                    );
                  }).toList(),
                  onChanged: (product) {
                    setState(() {
                      selectedProduct = product;
                      quantity = 1;
                      quantityController.text = '1';
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (selectedProduct != null) ...[
              Text(
                "Quantity",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.neutral,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (quantity > 1) {
                        setState(() {
                          quantity--;
                          quantityController.text = quantity.toString();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.remove, size: 20, color: AppColor.secondary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        final qty = int.tryParse(value);
                        if (qty != null && qty > 0) {
                          setState(() => quantity = qty);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        quantity++;
                        quantityController.text = quantity.toString();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, size: 20, color: AppColor.secondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColor.primary.withValues(alpha: 0.1), AppColor.primary.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Amount",
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.neutral,
                      ),
                    ),
                    Text(
                      "NPR $totalPrice",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (selectedProduct!.oldPrice != null && selectedProduct!.price != selectedProduct!.oldPrice)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColor.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColor.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Price changed from NPR ${selectedProduct!.oldPrice} to NPR ${selectedProduct!.price}",
                          style: GoogleFonts.manrope(fontSize: 12, color: AppColor.warning),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _processSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    "Confirm Sale",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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