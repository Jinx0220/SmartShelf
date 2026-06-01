import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../models/sale.dart';
import '../utils/formatters.dart';
import '../utils/colors.dart';

class RecentSalesList extends StatelessWidget {
  final List<Sale> sales;

  const RecentSalesList({super.key, required this.sales});

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColor.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : AppColor.neutral).withOpacity(0.05),
            blurRadius: 10,
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
              Text(
                'Recent Sales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                child: Text(
                  'View All',
                  style: TextStyle(fontSize: 12, color: AppColor.primary, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sales.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No sales recorded yet',
                  style: TextStyle(color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
                ),
              ),
            )
          else
            ...sales.map((sale) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDarkMode ? AppColor.darkBackground : AppColor.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColor.primary.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.shopping_bag_outlined, color: AppColor.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.productName,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sale.quantity} ${sale.quantity == 1 ? 'unit' : 'units'} • ${_getTimeAgo(sale.timestamp)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(sale.totalPrice),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColor.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Completed',
                          style: TextStyle(fontSize: 10, color: AppColor.success),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }
}