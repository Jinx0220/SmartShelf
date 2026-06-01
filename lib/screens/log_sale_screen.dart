import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/theme_provider.dart';
import '../models/product.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';

class LogSaleScreen extends StatefulWidget {
  const LogSaleScreen({super.key});

  @override
  State<LogSaleScreen> createState() => _LogSaleScreenState();
}

class _LogSaleScreenState extends State<LogSaleScreen> {
  Product? _selectedProduct;
  int _quantity = 1;
  final TextEditingController _quantityController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final totalPrice = _selectedProduct != null
        ? _selectedProduct!.price * _quantity
        : 0;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColor.darkBackground : AppColor.background,
      appBar: AppBar(
        title: Text(
          'Log Sale',
          style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
        ),
        backgroundColor: isDarkMode ? AppColor.darkSurface : Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Product',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColor.darkText : AppColor.neutral,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColor.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDarkMode ? AppColor.darkBorder : AppColor.secondary.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Product>(
                  isExpanded: true,
                  hint: Text(
                    'Choose a product',
                    style: TextStyle(color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
                  ),
                  value: _selectedProduct,
                  dropdownColor: isDarkMode ? AppColor.darkSurface : Colors.white,
                  items: productProvider.products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(
                        '${product.name} - ${formatCurrency(product.price)}',
                        style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
                      ),
                    );
                  }).toList(),
                  onChanged: (product) {
                    setState(() {
                      _selectedProduct = product;
                      _quantity = 1;
                      _quantityController.text = '1';
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_selectedProduct != null) ...[
              Text(
                'Quantity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColor.darkCard : AppColor.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDarkMode ? AppColor.darkBorder : AppColor.secondary.withOpacity(0.3)),
                      ),
                      child: Icon(Icons.remove, size: 20, color: isDarkMode ? AppColor.darkText : AppColor.neutral),
                    ),
                    onPressed: () {
                      if (_quantity > 1) {
                        setState(() {
                          _quantity--;
                          _quantityController.text = _quantity.toString();
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        filled: true,
                        fillColor: isDarkMode ? AppColor.darkCard : Colors.white,
                      ),
                      onChanged: (value) {
                        final int? qty = int.tryParse(value);
                        if (qty != null && qty > 0) {
                          setState(() => _quantity = qty);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColor.darkCard : AppColor.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDarkMode ? AppColor.darkBorder : AppColor.secondary.withOpacity(0.3)),
                      ),
                      child: Icon(Icons.add, size: 20, color: isDarkMode ? AppColor.darkText : AppColor.neutral),
                    ),
                    onPressed: () {
                      setState(() {
                        _quantity++;
                        _quantityController.text = _quantity.toString();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                      ),
                    ),
                    Text(
                      formatCurrency(totalPrice),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _logSale(context, isDarkMode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Log Sale',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _logSale(BuildContext context, bool isDarkMode) async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    if (_quantity > _selectedProduct!.stock) {
      _showNegativeStockDialog(context, isDarkMode);
      return;
    }

    final saleProvider = Provider.of<SaleProvider>(context, listen: false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sold ${_quantity}x ${_selectedProduct!.name}'),
        backgroundColor: AppColor.success,
      ),
    );

    setState(() {
      _selectedProduct = null;
      _quantity = 1;
      _quantityController.text = '1';
    });
  }

  void _showNegativeStockDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? AppColor.darkSurface : Colors.white,
        title: Text('Insufficient Stock', style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral)),
        content: Text(
          'You are trying to sell $_quantity units but only ${_selectedProduct!.stock} are in stock.',
          style: TextStyle(color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.warning,
            ),
            child: const Text('Log Anyway'),
          ),
        ],
      ),
    );
  }
}