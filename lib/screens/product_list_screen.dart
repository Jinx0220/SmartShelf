import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/theme_provider.dart';
import '../models/product.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  List<Product> _getFilteredProducts(List<Product> products) {
    var filtered = products;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) => p.category == _selectedCategory).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final products = _getFilteredProducts(productProvider.products);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColor.darkBackground : AppColor.background,
      appBar: AppBar(
        title: Text(
          'Products',
          style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
        ),
        backgroundColor: isDarkMode ? AppColor.darkSurface : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColor.primary),
            onPressed: () => _showAddProductDialog(context, isDarkMode),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
                prefixIcon: Icon(Icons.search, color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDarkMode ? AppColor.darkBorder : AppColor.secondary.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDarkMode ? AppColor.darkBorder : AppColor.secondary.withOpacity(0.3)),
                ),
                filled: true,
                fillColor: isDarkMode ? AppColor.darkCard : Colors.white,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryChip('All', isDarkMode),
                const SizedBox(width: 8),
                _buildCategoryChip('Grocery', isDarkMode),
                const SizedBox(width: 8),
                _buildCategoryChip('Dairy', isDarkMode),
                const SizedBox(width: 8),
                _buildCategoryChip('Beverages', isDarkMode),
                const SizedBox(width: 8),
                _buildCategoryChip('Snacks', isDarkMode),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: productProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                ? Center(child: Text('No products found', style: TextStyle(color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(product, isDarkMode);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isDarkMode) {
    return FilterChip(
      label: Text(category),
      selected: _selectedCategory == category,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : 'All';
        });
      },
      backgroundColor: isDarkMode ? AppColor.darkCard : Colors.white,
      selectedColor: AppColor.primary.withOpacity(0.1),
      checkmarkColor: AppColor.primary,
      labelStyle: TextStyle(
        color: _selectedCategory == category ? AppColor.primary : (isDarkMode ? AppColor.darkText : AppColor.neutral),
      ),
    );
  }

  Widget _buildProductCard(Product product, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColor.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : AppColor.neutral).withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColor.darkBackground : AppColor.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.inventory_2, color: AppColor.primary, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock: ${product.stock} | Price: ${formatCurrency(product.price)}',
                  style: TextStyle(fontSize: 12, color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: product.stock <= product.threshold
                  ? AppColor.warning.withOpacity(0.1)
                  : AppColor.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              product.stock <= product.threshold ? 'Low Stock' : 'In Stock',
              style: TextStyle(
                fontSize: 11,
                color: product.stock <= product.threshold ? AppColor.warning : AppColor.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColor.darkSurface : Colors.white,
        title: Text('Add Product', style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral)),
        content: Text('Add product form coming soon', style: TextStyle(color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}