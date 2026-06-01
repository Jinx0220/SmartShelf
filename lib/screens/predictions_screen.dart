import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';

class PredictionsScreen extends StatelessWidget {
  const PredictionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColor.darkBackground : AppColor.background,
      appBar: AppBar(
        title: Text(
          'AI Predictions',
          style: TextStyle(color: isDarkMode ? AppColor.darkText : AppColor.neutral),
        ),
        backgroundColor: isDarkMode ? AppColor.darkSurface : Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColor.primary, AppColor.primary.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Sales Predictions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Based on your sales history, AI predicts next week\'s demand',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Recommended Order Quantities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? AppColor.darkText : AppColor.neutral,
              ),
            ),
            const SizedBox(height: 16),

            _buildPredictionCard('Basmati Rice', 45, 30, 'High', isDarkMode),
            _buildPredictionCard('MOMO Chutney', 32, 25, 'High', isDarkMode),
            _buildPredictionCard('Cooking Oil', 28, 20, 'Medium', isDarkMode),
            _buildPredictionCard('Salt', 22, 15, 'Low', isDarkMode),
            _buildPredictionCard('Sugar', 18, 12, 'Low', isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard(String name, int predicted, int current, String confidence, bool isDarkMode) {
    Color confidenceColor;
    IconData confidenceIcon;

    switch (confidence) {
      case 'High':
        confidenceColor = AppColor.success;
        confidenceIcon = Icons.trending_up;
        break;
      case 'Medium':
        confidenceColor = AppColor.warning;
        confidenceIcon = Icons.trending_flat;
        break;
      default:
        confidenceColor = AppColor.error;
        confidenceIcon = Icons.trending_down;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColor.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.black : AppColor.neutral).withOpacity(0.05),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? AppColor.darkText : AppColor.neutral,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(confidenceIcon, size: 14, color: confidenceColor),
                    const SizedBox(width: 4),
                    Text(
                      confidence,
                      style: TextStyle(fontSize: 11, color: confidenceColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPredictionStat('Current Stock', current.toString(), AppColor.secondary, isDarkMode),
              _buildPredictionStat('Predicted Need', predicted.toString(), AppColor.primary, isDarkMode),
              _buildPredictionStat('Suggested Order', (predicted - current).toString(), AppColor.success, isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionStat(String label, String value, Color color, bool isDarkMode) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: isDarkMode ? AppColor.darkTextSecondary : AppColor.secondary)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}