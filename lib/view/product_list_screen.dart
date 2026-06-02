import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<Product> _products = [];
  bool _isLoading = true;

  final List<String> _categories = ['All', 'Grocery', 'Dairy', 'Beverages', 'Snacks'];

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

  // ==================== PRODUCT CRUD METHODS ====================

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
      Product(
        id: '7',
        name: 'Salt',
        stock: 22,
        threshold: 5,
        price: 20,
        category: 'Grocery',
        oldPrice: 20,
      ),
      Product(
        id: '8',
        name: 'Sugar',
        stock: 18,
        threshold: 5,
        price: 85,
        category: 'Grocery',
        oldPrice: 85,
      ),
    ];
    await _saveProductsToStorage(_products);
  }

  Future<void> _addProduct(Product product) async {
    setState(() {
      _products.add(product);
    });
    await _saveProductsToStorage(_products);
    Fluttertoast.showToast(msg: 'Product added successfully');
  }

  Future<void> _updateProduct(Product updatedProduct) async {
    setState(() {
      final index = _products.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
    });
    await _saveProductsToStorage(_products);
    Fluttertoast.showToast(msg: 'Product updated successfully');
  }

  Future<void> _deleteProduct(String productId) async {
    setState(() {
      _products.removeWhere((p) => p.id == productId);
    });
    await _saveProductsToStorage(_products);
    Fluttertoast.showToast(msg: 'Product deleted successfully');
  }

  List<Product> _getFilteredProducts() {
    var filtered = _products;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    return filtered;
  }

  // ==================== UI METHODS ====================

  @override
  Widget build(BuildContext context) {
    final products = _getFilteredProducts();

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          'Products',
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
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddEditProductDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: GoogleFonts.manrope(color: AppColor.neutral),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: GoogleFonts.manrope(color: AppColor.secondary),
                prefixIcon: Icon(Icons.search, color: AppColor.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColor.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryChip(category),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
                : products.isEmpty
                ? Center(
              child: Text(
                'No products found',
                style: GoogleFonts.manrope(color: AppColor.secondary),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(product);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;

    return FilterChip(
      label: Text(
        category,
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColor.neutral,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : 'All';
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppColor.primary,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isLowStock = product.isLowStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.inventory_2_outlined, color: AppColor.primary, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.neutral,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock: ${product.stock} | Price: ${formatCurrency(product.price)}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColor.secondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isLowStock
                  ? AppColor.error.withValues(alpha: 0.1)
                  : AppColor.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isLowStock ? 'Low Stock' : 'In Stock',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isLowStock ? AppColor.error : AppColor.success,
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColor.secondary),
            onSelected: (value) {
              if (value == 'edit') {
                _showAddEditProductDialog(product: product);
              } else if (value == 'delete') {
                _showDeleteConfirmation(product);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddEditProductDialog({Product? product}) {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '');
    final thresholdController = TextEditingController(text: product?.threshold.toString() ?? '');
    String selectedCategory = product?.category ?? 'Grocery';
    final List<String> categories = ['Grocery', 'Dairy', 'Beverages', 'Snacks'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEditing ? 'Edit Product' : 'Add Product',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.neutral,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Price (NPR)',
                    labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Current Stock',
                    labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: thresholdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Low Stock Threshold',
                    labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category, style: GoogleFonts.manrope()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedCategory = value!;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppColor.secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = int.tryParse(priceController.text);
              final stock = int.tryParse(stockController.text);
              final threshold = int.tryParse(thresholdController.text);

              if (name.isEmpty) {
                Fluttertoast.showToast(msg: 'Please enter product name');
                return;
              }
              if (price == null || price <= 0) {
                Fluttertoast.showToast(msg: 'Please enter valid price');
                return;
              }
              if (stock == null || stock < 0) {
                Fluttertoast.showToast(msg: 'Please enter valid stock');
                return;
              }
              if (threshold == null || threshold < 0) {
                Fluttertoast.showToast(msg: 'Please enter valid threshold');
                return;
              }

              if (isEditing) {
                final updatedProduct = Product(
                  id: product!.id,
                  name: name,
                  stock: stock,
                  threshold: threshold,
                  price: price,
                  category: selectedCategory,
                  oldPrice: product.oldPrice ?? price,
                );
                await _updateProduct(updatedProduct);
              } else {
                final newProduct = Product(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  stock: stock,
                  threshold: threshold,
                  price: price,
                  category: selectedCategory,
                  oldPrice: price,
                );
                await _addProduct(newProduct);
              }

              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isEditing ? 'Update' : 'Add',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Product',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.error,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"?',
          style: GoogleFonts.manrope(fontSize: 14, color: AppColor.neutral),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(color: AppColor.secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _deleteProduct(product.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== PRODUCT MODEL ====================
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
  bool get isOutOfStock => stock == 0;

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