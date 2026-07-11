// File: lib/view/product_list_screen.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smartshelf/model/sale_model.dart';
import 'package:smartshelf/view/scanner_screen.dart';
import 'package:smartshelf/viewmodel/sale_viewmodel.dart';
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
  bool _viewArchived = false;
  bool _filterLowStockOnly = false;

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
    final saleVm = context.watch<SaleViewModel>();
    final products = vm.allProducts ?? [];

    // Global loading guard for button operations
    final isSystemBusy = vm.loading || saleVm.loading;

    // 1. Filter out items by active vs archived status first
    var filteredProducts = products.where((p) => p.isDiscontinued == _viewArchived).toList();

    // 2. Build categories dynamically based on what's visible
    final categories = ['All', ...filteredProducts.map((p) => p.category).toSet().where((c) => c.isNotEmpty)];

    // 3. Apply search query
    if (_searchQuery.isNotEmpty) {
      filteredProducts = filteredProducts.where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // --- LOW STOCK FILTER INJECTION ---
    if (_filterLowStockOnly && !_viewArchived) {
      filteredProducts = filteredProducts.where((p) => p.stock <= p.threshold).toList();
    }

    // 4. Apply category filter
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

    final lowStockItemsCount = products.where((p) => !p.isDiscontinued && p.stock <= p.threshold).length;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          _viewArchived ? 'Archived Inventory' : 'Products',
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
            icon: Icon(_viewArchived ? Icons.inventory : Icons.archive_outlined, color: Colors.white),
            tooltip: _viewArchived ? "View Active Stock" : "View Archived Items",
            onPressed: () {
              setState(() {
                _viewArchived = !_viewArchived;
                _filterLowStockOnly = false; // Reset low stock layout when swapping tabs
              });
            },
          ),
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
      body: vm.loading && products.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : Column(
        children: [
          // --- DYNAMIC DASHBOARD ALERT BANNER ---
          if (lowStockItemsCount > 0 && !_viewArchived)
            GestureDetector(
              onTap: () {
                setState(() {
                  _filterLowStockOnly = !_filterLowStockOnly;
                });
              },
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _filterLowStockOnly
                      ? Colors.amber.shade900
                      : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _filterLowStockOnly ? Colors.amber.shade900 : Colors.amber.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: _filterLowStockOnly ? Colors.white : Colors.amber.shade900,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$lowStockItemsCount Items Running Low!",
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _filterLowStockOnly ? Colors.white : Colors.amber.shade900,
                            ),
                          ),
                          Text(
                            _filterLowStockOnly
                                ? "Showing low stock items. Tap to clear filter."
                                : "Tap to review items needing restocking.",
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: _filterLowStockOnly ? Colors.white70 : Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _filterLowStockOnly ? Icons.bookmark_remove : Icons.arrow_forward_ios,
                      size: 16,
                      color: _filterLowStockOnly ? Colors.white : Colors.amber.shade700,
                    ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: GoogleFonts.manrope(color: AppColor.neutral),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: GoogleFonts.manrope(color: AppColor.secondary),
                prefixIcon: const Icon(Icons.search, color: AppColor.secondary),
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
                  const Icon(Icons.inventory, size: 64, color: AppColor.secondary),
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
                  return _buildProductCard(context, product, vm, isSystemBusy);
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

  Widget _buildProductCard(BuildContext context, ProductModel product, ProductViewModel vm, bool isSystemBusy) {
    final isLowStock = product.isLowStock;

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
              child: (product.imagePath != null && File(product.imagePath!).existsSync())
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(product.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      isLowStock ? Icons.warning_amber : Icons.inventory_2_outlined,
                      color: isLowStock ? AppColor.error : AppColor.primary,
                      size: 30,
                    );
                  },
                ),
              )
                  : Icon(
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

                  // --- VISUAL BARCODE DISPLAY LINE ---
                  if (product.barcode != null && product.barcode!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.qr_code, size: 12, color: AppColor.secondary),
                          const SizedBox(width: 4),
                          Text(
                            product.barcode!,
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColor.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (!product.isDiscontinued)
              IconButton(
                icon: const Icon(Icons.add_shopping_cart, color: AppColor.success, size: 24),
                tooltip: 'Quick 1-Tap Sale',
                onPressed: isSystemBusy ? null : () async {
                  if (product.stock <= 0) {
                    Fluttertoast.showToast(
                      msg: "Cannot log sale: ${product.name} is completely out of stock!",
                      backgroundColor: AppColor.error,
                      textColor: Colors.white,
                    );
                    return;
                  }

                  try {
                    final updatedProduct = product.copyWith(stock: product.stock - 1);
                    await vm.updateProduct(updatedProduct);

                    final saleVm = context.read<SaleViewModel>();
                    final sale = SaleModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      productId: product.id ?? '',
                      productName: product.name,
                      quantity: 1,
                      totalPrice: product.price.toInt(),
                      unitPrice: product.price.toInt(),
                      timestamp: DateTime.now(),
                    );
                    await saleVm.addSale(sale);

                    // FIXED: Update financial metrics on backends instantly
                    await saleVm.getAllSales();

                    Fluttertoast.showToast(
                      msg: "1x ${product.name} Sold!",
                      backgroundColor: AppColor.success,
                      textColor: Colors.white,
                    );
                  } catch (e) {
                    Fluttertoast.showToast(msg: "Quick Sale Failed: ${e.toString()}");
                  }
                },
              ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: product.isDiscontinued
                    ? Colors.grey.shade200
                    : isLowStock
                    ? AppColor.error.withValues(alpha: 0.1)
                    : AppColor.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.isDiscontinued
                    ? 'Archived'
                    : isLowStock ? 'Low Stock' : 'In Stock',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: product.isDiscontinued
                      ? Colors.grey.shade600
                      : isLowStock ? AppColor.error : AppColor.success,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColor.secondary),
              onSelected: (value) {
                if (value == 'edit') {
                  _showAddEditProductDialog(context, vm, product: product);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context, product, vm);
                } else if (value == 'discontinue') {
                  _showDiscontinueConfirmation(context, product, vm);
                } else if (value == 'restore') {
                  _showRestoreConfirmation(context, product, vm);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (!product.isDiscontinued)
                  const PopupMenuItem(value: 'discontinue', child: Text('Discontinue'))
                else
                  const PopupMenuItem(value: 'restore', child: Text('Restore to Shelf')),
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
    final customCategoryController = TextEditingController();
    final barcodeController = TextEditingController(text: product?.barcode ?? '');

    String? currentImagePath = product?.imagePath;

    final allCategories = vm.allProducts
        ?.map((p) => p.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList() ?? [];

    String selectedCategory = product?.category ?? (allCategories.isNotEmpty ? allCategories.first : 'General');
    bool isAddingNew = false;

    Future<void> pickImage(ImageSource source, StateSetter setStateDialog) async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

      if (pickedFile != null) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final String fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final String permanentPath = '${directory.path}/$fileName';
          final File savedImage = await File(pickedFile.path).copy(permanentPath);

          setStateDialog(() {
            currentImagePath = savedImage.path;
          });
        } catch (e) {
          Fluttertoast.showToast(msg: "Failed to save photo locally: $e");
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              isEditing ? 'Edit Product' : 'Add Product',
              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.neutral),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Choose from Gallery'),
                                  onTap: () {
                                    pickImage(ImageSource.gallery, setStateDialog);
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Take a Photo'),
                                  onTap: () {
                                    pickImage(ImageSource.camera, setStateDialog);
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: currentImagePath != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(File(currentImagePath!), fit: BoxFit.cover),
                        )
                            : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: AppColor.primary, size: 28),
                            SizedBox(height: 4),
                            Text("Add Photo", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Barcode / SKU (Optional)',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: AppColor.primary),
                          onPressed: () async {
                            final scannedCode = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ScannerScreen()),
                            );
                            if (scannedCode != null && scannedCode is String) {
                              setStateDialog(() {
                                barcodeController.text = scannedCode;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: 'Price ($globalCurrencySymbol)',
                          border: const OutlineInputBorder()
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Current Stock', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: thresholdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Low Stock Threshold', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),

                    if (isAddingNew)
                      TextField(
                        controller: customCategoryController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'New Category Name',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setStateDialog(() => isAddingNew = false),
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: allCategories.contains(selectedCategory) ? selectedCategory : (allCategories.isNotEmpty ? allCategories.first : null),
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: [
                          ...allCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                          const DropdownMenuItem(
                            value: 'ADD_NEW',
                            child: Text('+ Add New Category', style: TextStyle(color: AppColor.primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == 'ADD_NEW') {
                            setStateDialog(() => isAddingNew = true);
                          } else {
                            setStateDialog(() => selectedCategory = value!);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel', style: GoogleFonts.manrope(color: AppColor.secondary)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final price = double.tryParse(priceController.text);
                  final stock = int.tryParse(stockController.text);
                  final threshold = int.tryParse(thresholdController.text);
                  final finalCategory = isAddingNew ? customCategoryController.text.trim() : selectedCategory;
                  final barcodeValue = barcodeController.text.trim();

                  if (name.isEmpty || price == null || stock == null || threshold == null || finalCategory.isEmpty) {
                    Fluttertoast.showToast(msg: 'Please fill all fields correctly');
                    return;
                  }

                  bool success = false;

                  if (isEditing) {
                    final updatedProduct = ProductModel(
                      id: product!.id,
                      name: name,
                      price: price,
                      stock: stock,
                      threshold: threshold,
                      category: finalCategory,
                      oldPrice: product.oldPrice ?? price,
                      isDiscontinued: product.isDiscontinued,
                      barcode: barcodeValue.isNotEmpty ? barcodeValue : null,
                      imagePath: currentImagePath,
                    );
                    success = await vm.updateProduct(updatedProduct);
                  } else {
                    final newProduct = ProductModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      price: price,
                      stock: stock,
                      threshold: threshold,
                      category: finalCategory,
                      oldPrice: price,
                      isDiscontinued: false,
                      barcode: barcodeValue.isNotEmpty ? barcodeValue : null,
                      imagePath: currentImagePath,
                    );
                    success = await vm.addProduct(newProduct);
                  }

                  if (success) {
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    Fluttertoast.showToast(
                      msg: isEditing ? 'Product updated successfully' : 'Product added successfully',
                      backgroundColor: AppColor.success,
                      textColor: Colors.white,
                    );
                  } else {
                    Fluttertoast.showToast(
                      msg: vm.error ?? 'Failed to save configuration settings',
                      backgroundColor: AppColor.error,
                      textColor: Colors.white,
                      toastLength: Toast.LENGTH_LONG,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
                child: Text(isEditing ? 'Update' : 'Add', style: GoogleFonts.manrope(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // FIXED: Implemented missing confirmation dialogues completely
  void _showDeleteConfirmation(BuildContext context, ProductModel product, ProductViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Product',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.error),
        ),
        content: Text(
          "Are you sure you want to permanently delete '${product.name}'? This action cannot be undone and clears transaction association contexts.",
          style: GoogleFonts.manrope(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.manrope(color: AppColor.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.error),
            onPressed: () async {
              final success = await vm.deleteProduct(product.id!);
              if (!context.mounted) return;
              Navigator.pop(context);
              if (success) {
                Fluttertoast.showToast(msg: "Product deleted from ecosystem");
              }
            },
            child: Text('Delete', style: GoogleFonts.manrope(color: Colors.white)),
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
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.neutral),
        ),
        content: Text(
          "Archive '${product.name}'? It won't show up for sales transactions but historical records remain safe.",
          style: GoogleFonts.manrope(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.manrope(color: AppColor.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
            onPressed: () async {
              final updated = product.copyWith(isDiscontinued: true);
              final success = await vm.updateProduct(updated);
              if (!context.mounted) return;
              Navigator.pop(context);
              if (success) {
                Fluttertoast.showToast(msg: "Product moved to archive shelf");
              }
            },
            child: Text('Archive', style: GoogleFonts.manrope(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRestoreConfirmation(BuildContext context, ProductModel product, ProductViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Restore Product',
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.success),
        ),
        content: Text(
          "Bring '${product.name}' back to the active shelf display?",
          style: GoogleFonts.manrope(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.manrope(color: AppColor.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.success),
            onPressed: () async {
              final updated = product.copyWith(isDiscontinued: false);
              final success = await vm.updateProduct(updated);
              if (!context.mounted) return;
              Navigator.pop(context);
              if (success) {
                Fluttertoast.showToast(msg: "Product restored to sales channels");
              }
            },
            child: Text('Restore', style: GoogleFonts.manrope(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}