import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';

class StatsCard extends StatelessWidget {
  final int todaySales;
  final int weeklySales;

  const StatsCard({super.key, required this.todaySales, required this.weeklySales});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Sales",
                  style: TextStyle(fontSize: 14, color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
                ),
                const SizedBox(height: 8),
                Text(
                  formatCurrency(todaySales),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: (isDarkMode ? AppColor.darkBorder : AppColor.secondary).withOpacity(0.2),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "This Week",
                  style: TextStyle(fontSize: 14, color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary),
                ),
                const SizedBox(height: 8),
                Text(
                  formatCurrency(weeklySales),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}