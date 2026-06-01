import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/product.dart';
import '../utils/colors.dart';

class LowStockSection extends StatelessWidget {
  final List<Product> criticalProducts;

  const LowStockSection({super.key, required this.criticalProducts});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColor.darkCard : AppColor.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColor.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.warning_amber_rounded, color: AppColor.error, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Low Stock Alert',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                      ),
                    ),
                    Text(
                      '${criticalProducts.length} products ${criticalProducts.length == 1 ? 'is' : 'are'} running low',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Order Now',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ],
          ),
          if (criticalProducts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: (isDarkMode ? AppColor.darkBorder : AppColor.secondary).withOpacity(0.2)),
            const SizedBox(height: 12),
            ...criticalProducts.take(3).map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColor.darkBackground : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: (isDarkMode ? AppColor.darkBorder : AppColor.secondary).withOpacity(0.2)),
                    ),
                    child: Icon(Icons.inventory_2_outlined, size: 20, color: AppColor.secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                          ),
                        ),
                        Text(
                          'Stock: ${product.stock} (Threshold: ${product.threshold})',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: product.stock == 0
                          ? AppColor.error.withOpacity(0.1)
                          : AppColor.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      product.stock == 0 ? 'Out of Stock' : 'Low Stock',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: product.stock == 0 ? AppColor.error : AppColor.warning,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
}