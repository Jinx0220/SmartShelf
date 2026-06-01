import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sale_provider.dart';
import '../providers/product_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/greeting_header.dart';
import '../widgets/stats_card.dart';
import '../widgets/low_stock_section.dart';
import '../widgets/recent_sales_list.dart';
import '../utils/colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final saleProvider = Provider.of<SaleProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    await Future.wait([
      saleProvider.loadAllSalesData(),
      productProvider.fetchProducts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final saleProvider = Provider.of<SaleProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColor.darkBackground : AppColor.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColor.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              GreetingHeader(storeName: 'Everest Kirana Store'),
              if (saleProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                StatsCard(
                  todaySales: saleProvider.todaySales,
                  weeklySales: saleProvider.weeklySales,
                ),
              if (productProvider.criticalStockProducts.isNotEmpty)
                LowStockSection(
                  criticalProducts: productProvider.criticalStockProducts,
                ),
              if (saleProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                RecentSalesList(sales: saleProvider.recentSales),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}