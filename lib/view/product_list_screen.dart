import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';
import '../viewmodel/product_viewmodel.dart';
import '../model/product_model.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortOption = 'Name';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().getAllProduct();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewModel>();
    final products = vm.allProducts ?? [];

    final categories = ['All', ...products.map((p) => p.category).toSet().where((c) => c.isNotEmpty)];

    var filteredProducts = products;
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_selectedCategory != 'All') {
      filteredProducts = filteredProducts.where((p) => p.category == _selectedCategory).toList();
    }

    switch (_sortOption) {
      case 'Name':
        filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Price':
        filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Stock':
        filteredProducts.sort((a, b) => a.stock.compareTo(b.stock));
        break;
    }

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) => setState(() => _sortOption = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'Price', child: Text('Sort by Price')),
              const PopupMenuItem(value: 'Stock', child: Text('Sort by Stock')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showAddEditProductDialog(context, vm),
          ),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : Column(
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
              children: categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryChip(category),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory, size: 64, color: AppColor.secondary),
                  const SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColor.neutral,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first product',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColor.secondary,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () => vm.getAllProduct(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return _buildProductCard(context, product, vm);
                },
              ),
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

  Widget _buildProductCard(BuildContext context, ProductModel product, ProductViewModel vm) {
    final isLowStock = product.isLowStock;
    final isDiscontinued = product.isDiscontinued;

    if (isDiscontinued) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(productId: product.id!),
          ),
        ).then((_) => vm.getAllProduct());
      },
      child: Container(
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
                color: isLowStock
                    ? AppColor.error.withValues(alpha: 0.1)
                    : AppColor.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isLowStock ? Icons.warning_amber : Icons.inventory_2_outlined,
                color: isLowStock ? AppColor.error : AppColor.primary,
                size: 30,
              ),
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
                    'Stock: ${product.stock} | Price: ${formatCurrency(product.price.toInt())}',
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
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppColor.secondary),
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddEditProductDialog(context, vm, product: product);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, product, vm);
                } else if (value == 'discontinue') {
                  _showDiscontinueConfirmation(context, product, vm);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'discontinue', child: Text('Discontinue')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditProductDialog(
      BuildContext context,
      ProductViewModel vm, {
        ProductModel? product,
      }) {
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?.name ?? '');
    final priceController = TextEditingController(text: product?.price.toString() ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '');
    final thresholdController = TextEditingController(text: product?.threshold.toString() ?? '');
    String selectedCategory = product?.category ?? 'Grocery';

    final categories = ['Grocery', 'Dairy', 'Beverages', 'Snacks', 'Electronics', 'Clothing'];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
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
                          // THIS IS THE FIX: Using setStateDialog to update the UI
                          setStateDialog(() {
                            selectedCategory = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.manrope(color: AppColor.secondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text);
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
                      final updatedProduct = ProductModel(
                        id: product!.id,
                        name: name,
                        price: price,
                        stock: stock,
                        threshold: threshold,
                        category: selectedCategory,
                        oldPrice: product.oldPrice ?? price,
                        isDiscontinued: product.isDiscontinued,
                      );
                      await vm.updateProduct(updatedProduct);
                    } else {
                      final newProduct = ProductModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        price: price,
                        stock: stock,
                        threshold: threshold,
                        category: selectedCategory,
                        oldPrice: price,
                        isDiscontinued: false,
                      );
                      await vm.addProduct(newProduct);
                    }

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
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
            );
          }
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ProductModel product, ProductViewModel vm) {
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
              await vm.deleteProduct(product.id!);  // ✅ FIXED: added !
              if (context.mounted) Navigator.pop(context);
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

  void _showDiscontinueConfirmation(BuildContext context, ProductModel product, ProductViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Discontinue Product',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.warning,
          ),
        ),
        content: Text(
          'Are you sure you want to discontinue "${product.name}"?\n\nThis product will no longer appear in lists or predictions.',
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
              final updatedProduct = product.copyWith(isDiscontinued: true);
              await vm.updateProduct(updatedProduct);
              if (context.mounted) {
                Navigator.pop(context);
                Fluttertoast.showToast(msg: 'Product discontinued');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Discontinue',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}