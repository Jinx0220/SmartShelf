// File: lib/view/priority_dashboard_screen.dart
// ignore_for_file: spell_check_ignore_names, unknown_lints, type_checker
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smartshelf/viewmodel/analytics_viewmodel.dart';
import 'package:smartshelf/viewmodel/dashboard_viewmodel.dart';
import 'package:smartshelf/viewmodel/order_viewmodel.dart';
import 'package:smartshelf/viewmodel/prediction_viewmodel.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';
import '../viewmodel/product_viewmodel.dart';
import '../viewmodel/sale_viewmodel.dart';
import '../viewmodel/auth_viewmodel.dart';
import '../model/product_model.dart';
import '../model/sale_model.dart';
import 'log_sale_screen.dart';
import 'product_list_screen.dart';

class PriorityDashboardScreen extends StatefulWidget {
  const PriorityDashboardScreen({super.key});

  @override
  State<PriorityDashboardScreen> createState() => _PriorityDashboardScreenState();
}

class _PriorityDashboardScreenState extends State<PriorityDashboardScreen> {
  String greeting = "";

  @override
  void initState() {
    super.initState();
    _setGreeting();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboardData();
    });
  }

  // 🟢 ENHANCED FIX: Method to fix existing data - checks ALL sales
  Future<void> _fixExistingSalesData() async {
    try {
      final saleVm = context.read<SaleViewModel>();
      final productVm = context.read<ProductViewModel>();

      await productVm.getAllProduct();
      await saleVm.getAllSales();

      final sales = saleVm.sales ?? [];
      final products = productVm.allProducts ?? [];

      if (sales.isEmpty || products.isEmpty) {
        debugPrint("📝 No data to fix");
        return;
      }

      debugPrint("📝 Checking ${sales.length} sales records for fixes...");
      int fixedCount = 0;
      int checkedCount = 0;

      // Build a map of product ID to name for quick lookup
      final productNameMap = <String, String>{};
      for (var product in products) {
        productNameMap[product.id ?? ''] = product.name;
      }

      for (var sale in sales) {
        checkedCount++;

        // Get the correct product name from the map
        final String correctName = productNameMap[sale.productId] ?? sale.productName;

        // Check if the sale's productName is different from the correct name
        if (sale.productName != correctName && correctName.isNotEmpty) {
          debugPrint("📝 Fixing sale #$checkedCount: '${sale.productName}' → '$correctName'");

          // Use the SaleViewModel helper to fix this sale
          await saleVm.fixSaleProductName(sale.id, correctName);
          fixedCount++;
        } else {
          debugPrint("✅ Sale #$checkedCount already correct: '${sale.productName}'");
        }
      }

      debugPrint("📝 ===== SUMMARY =====");
      debugPrint("Total sales checked: $checkedCount");
      debugPrint("Fixed sales: $fixedCount");

      // Refresh all ViewModels
      if (mounted) {
        await _refreshAllViewModels();
        if (fixedCount > 0) {
          Fluttertoast.showToast(
            msg: "Fixed $fixedCount sales records!",
            backgroundColor: AppColor.success,
            textColor: Colors.white,
          );
        } else {
          Fluttertoast.showToast(
            msg: "✅ All sales already have correct names!",
            backgroundColor: AppColor.primary,
            textColor: Colors.white,
          );
        }
      }

    } catch (e) {
      debugPrint("❌ Error fixing sales data: $e");
      Fluttertoast.showToast(
        msg: "Error fixing data: $e",
        backgroundColor: AppColor.error,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _refreshDashboardData() async {
    if (!mounted) return;
    final productVm = context.read<ProductViewModel>();
    final saleVm = context.read<SaleViewModel>();
    final authVm = context.read<AuthViewModel>();
    final dashboardVm = context.read<DashboardViewModel>();

    try {
      await Future.wait([
        productVm.getAllProduct(),
        saleVm.getAllSales(),
        authVm.loadCurrentUser(),
        dashboardVm.loadDashboardData(),
      ]);

      // 🟢 Run fix once after data loads
      await _fixExistingSalesData();

    } catch (e) {
      debugPrint("Error loading dashboard metrics: $e");
    }
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = "Good morning";
    } else if (hour < 17) {
      greeting = "Good afternoon";
    } else {
      greeting = "Good evening";
    }
  }

  // 🟢 Refresh all ViewModels after CSV import
  Future<void> _refreshAllViewModels() async {
    final productVm = context.read<ProductViewModel>();
    final saleVm = context.read<SaleViewModel>();
    final dashboardVm = context.read<DashboardViewModel>();

    debugPrint("🔄 Refreshing all ViewModels...");

    // 1. Core Models
    await productVm.getAllProduct();
    await saleVm.getAllSales();

    // 2. Dashboard
    try {
      await dashboardVm.loadDashboardData();
      debugPrint("🔄 DashboardViewModel updated.");
    } catch (e) {
      debugPrint("Dashboard refresh failed: $e");
    }

    // 3. Analytics
    try {
      final analyticsVm = context.read<AnalyticsViewModel>();
      await analyticsVm.loadAllData();
      debugPrint("🔄 AnalyticsViewModel updated.");
    } catch (e) {
      debugPrint("Analytics refresh failed: $e");
    }

    // 4. Predictions
    try {
      final predictionVm = context.read<PredictionViewModel>();
      final products = productVm.allProducts ?? [];
      final sales = saleVm.sales ?? [];
      await predictionVm.generatePredictions(products, sales, 30);
      debugPrint("🔄 PredictionViewModel updated.");
    } catch (e) {
      debugPrint("Predictions refresh failed: $e");
    }

    // 5. Orders
    try {
      final orderVm = context.read<OrderViewModel>();
      final products = productVm.allProducts ?? [];
      final predictionVm = context.read<PredictionViewModel>();
      final predictions = predictionVm.predictions ?? [];
      await orderVm.generateSuggestedOrder(products, predictions);
      debugPrint("🔄 OrderViewModel updated.");
    } catch (e) {
      debugPrint("Orders refresh failed: $e");
    }

    debugPrint("✅ All ViewModels refreshed!");
  }

  Future<void> _importUnifiedCSV(BuildContext context) async {
    final saleVm = context.read<SaleViewModel>();
    final productVm = context.read<ProductViewModel>();

    debugPrint("=== CSV IMPORT STARTED ===");

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null) {
        Fluttertoast.showToast(msg: "File picking cancelled.");
        return;
      }

      String csvString = "";
      if (result.files.single.bytes != null) {
        csvString = utf8.decode(result.files.single.bytes!);
      } else if (result.files.single.path != null) {
        final file = File(result.files.single.path!);
        csvString = await file.readAsString();
      }

      if (csvString.trim().isEmpty) {
        Fluttertoast.showToast(msg: "Selected CSV file is empty.");
        return;
      }

      List<String> lines = csvString.split('\n');
      int progressCount = 0;
      final DateTime fallbackNow = DateTime.now();

      for (int i = 1; i < lines.length; i++) {
        String currentLine = lines[i].trim();
        if (currentLine.isEmpty) continue;

        List<String> columns = currentLine.split(',');
        if (columns.length < 4) continue;

        DateTime saleDate = fallbackNow;
        String pName = columns[1].trim();
        int qty = int.tryParse(columns[2].trim()) ?? 0;
        double customPrice = double.tryParse(columns[3].trim()) ?? 100.0;
        String categoryName = columns.length > 4 ? columns[4].trim() : 'General';

        await saleVm.addHistoricalSaleWithProfile(
          productName: pName,
          quantity: qty,
          date: saleDate,
          fallbackPrice: customPrice,
          category: categoryName,
        );

        progressCount++;
      }

      Fluttertoast.showToast(
        msg: "Successfully imported $progressCount transaction history logs!",
        backgroundColor: AppColor.success,
        textColor: Colors.white,
      );

      // 🟢 CALL THE REFRESH METHOD
      if (context.mounted) {
        await _refreshAllViewModels();
      }
    } catch (e) {
      debugPrint("💥 CRITICAL CORE FAILURE: $e");
      Fluttertoast.showToast(
        msg: "Import Failure: $e",
        backgroundColor: AppColor.error,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _executeInstantQuickSale(
      String productName,
      List<ProductModel> totalCatalog,
      SaleViewModel saleVm,
      ProductViewModel productVm,
      ) async {
    try {
      // 🟢 Find product by name (case-insensitive)
      ProductModel target;
      try {
        target = totalCatalog.firstWhere(
              (element) => element.name.trim().toLowerCase() == productName.trim().toLowerCase(),
        );
      } catch (_) {
        // 🟢 Product not found - create a proper stub with the NAME
        target = ProductModel(
          id: 'stub_${productName.replaceAll(' ', '_').toLowerCase()}',
          name: productName,
          price: 150.0,
          stock: 10,
          threshold: 2,
          category: 'Fast-Moving',
        );
      }

      // Check stock for real products only
      if (!target.id!.startsWith('stub_') && target.stock <= 0) {
        Fluttertoast.showToast(
          msg: "Cannot log sale: $productName is completely out of stock!",
          backgroundColor: AppColor.error,
          textColor: Colors.white,
        );
        return;
      }

      final int productUnitPrice = target.price.toInt();

      // 🟢 CRITICAL FIX: Always use the product NAME, not the ID
      final SaleModel instantSaleRecord = SaleModel(
        id: "quick_${DateTime.now().microsecondsSinceEpoch}",
        productId: target.id ?? 'unknown',
        productName: target.name,
        quantity: 1,
        unitPrice: productUnitPrice,
        totalPrice: productUnitPrice,
        timestamp: DateTime.now(),
        notes: "Logged via Quick-Add Shortcut Panel",
      );

      debugPrint("📝 Quick Sale: Product Name: ${instantSaleRecord.productName}, ID: ${instantSaleRecord.productId}");

      final bool status = await saleVm.addSale(instantSaleRecord);

      if (status && !target.id!.startsWith('stub_')) {
        await productVm.updateProduct(target.copyWith(stock: target.stock - 1));
        if (context.mounted) {
          await context.read<DashboardViewModel>().loadDashboardData();
          await _refreshAllViewModels();
        }
      }

      if (status) {
        Fluttertoast.showToast(
          msg: "⚡ Quick Added: 1x ${target.name}!",
          backgroundColor: AppColor.success,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      debugPrint("Quick sale error: $e");
      Fluttertoast.showToast(
        msg: "Error: ${e.toString()}",
        backgroundColor: AppColor.error,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardVm = context.watch<DashboardViewModel>();
    final productVm = context.watch<ProductViewModel>();
    final saleVm = context.watch<SaleViewModel>();
    final authVm = context.watch<AuthViewModel>();

    final products = productVm.allProducts ?? [];
    final sales = saleVm.sales ?? [];
    final user = authVm.user;

    final int todaySalesAmount = dashboardVm.todaySales;
    final int weeklySalesAmount = dashboardVm.weeklySales;
    final int lowStockCount = dashboardVm.lowStockCount;

    Map<String, int> productSalesMap = {};
    for (var sale in sales) {
      if (sale.productId.isNotEmpty) {
        productSalesMap[sale.productId] = (productSalesMap[sale.productId] ?? 0) + sale.quantity;
      }
    }

    int misalignedThresholds = 0;
    for (var product in products) {
      final qtySold = productSalesMap[product.id] ?? 0;
      double dailyVelocity = qtySold / 7.0;
      int recommendedThreshold = (dailyVelocity * 3 + 4).ceil();
      if (recommendedThreshold != product.threshold) {
        misalignedThresholds++;
      }
    }

    final topProducts = <TopProduct>[];
    if (saleVm.topProducts != null && saleVm.topProducts!.isNotEmpty) {
      int rankCounter = 1;
      saleVm.topProducts!.forEach((productName, unitsSold) {
        if (rankCounter <= 5) {
          topProducts.add(TopProduct(name: productName, quantity: unitsSold, rank: rankCounter));
          rankCounter++;
        }
      });
    }

    final criticalProducts = products
        .where((p) => p.isLowStock)
        .map((p) => CriticalProduct(name: p.name, stock: p.stock, threshold: p.threshold, productId: p.id ?? ''))
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    final isLoading = productVm.loading || saleVm.loading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColor.background,
        body: RefreshIndicator(
          onRefresh: _refreshDashboardData,
          color: AppColor.primary,
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
              : SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreetingHeader(greeting, user?.storeName ?? 'Everest Kirana Store'),
                  const SizedBox(height: 16),

                  _buildSalesCards(todaySalesAmount, weeklySalesAmount, lowStockCount),
                  const SizedBox(height: 16),

                  _buildGamificationCard(saleVm),
                  const SizedBox(height: 16),

                  // 🟢 QUICK-ADD ROW REMOVED

                  if (misalignedThresholds > 0)
                    _buildAiInsightBanner(misalignedThresholds),

                  if (lowStockCount > 0 && misalignedThresholds == 0)
                    _buildLowStockAlert(lowStockCount),

                  const SizedBox(height: 24),
                  if (topProducts.isNotEmpty) _buildTopProductsSection(topProducts),
                  const SizedBox(height: 24),
                  if (criticalProducts.isNotEmpty) _buildCriticalStockSection(context, criticalProducts),
                  const SizedBox(height: 32),
                  _buildActionButtons(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(String greeting, String storeName) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColor.primary, AppColor.primary.withValues(alpha: 0.7)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: const Icon(Icons.store, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$greeting,', style: GoogleFonts.manrope(fontSize: 14, color: Colors.white70)),
                    Text(
                      storeName,
                      style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_none, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(_getFormattedDate(), style: GoogleFonts.manrope(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamificationCard(SaleViewModel saleVm) {
    final int streak = saleVm.currentDailyStreak;
    final String badge = saleVm.businessMilestoneBadge;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColor.primary, AppColor.primary.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColor.primary.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge,
                    style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    streak > 0
                        ? 'Awesome! Keep your consecutive sales record going strong.'
                        : 'Log a sale today to start your consecutive streak run!',
                    style: GoogleFonts.manrope(fontSize: 11, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🔥 STREAK',
                    style: GoogleFonts.spaceGrotesk(
                        color: streak > 0 ? Colors.orangeAccent : Colors.white60,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$streak ${streak == 1 ? "Day" : "Days"}',
                    style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCards(int todaySales, int weeklySales, int lowStockCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildMetricCard("TODAY'S SALES", formatCurrency(todaySales))),
          const SizedBox(width: 12),
          Expanded(child: _buildMetricCard("WEEKLY SALES", formatCurrency(weeklySales))),
          const SizedBox(width: 12),
          Expanded(child: _buildMetricCard("LOW STOCK", "$lowStockCount")),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.manrope(fontSize: 11, color: AppColor.secondary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.bold, color: AppColor.neutral)),
        ],
      ),
    );
  }

  Widget _buildAiInsightBanner(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColor.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.primary.withValues(alpha: 0.25), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColor.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Smart Reorder Suggestions",
                    style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.bold, color: AppColor.neutral),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Based on your recent sales speed, we recommend updating low-stock alert points for $count items.",
                    style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockAlert(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.error.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: AppColor.error, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "$count items are running low. Reorder them soon to avoid running out.",
                style: GoogleFonts.manrope(fontSize: 13, color: AppColor.error, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductsSection(List<TopProduct> topProducts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  "Top 5 Selling Products",
                  style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.neutral),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...topProducts.map((product) => _buildTopProductRow(product)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductRow(TopProduct product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: product.rank == 1 ? Colors.amber.withValues(alpha: 0.2) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "${product.rank}",
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: product.rank == 1 ? Colors.amber : AppColor.secondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product.name,
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.neutral),
            ),
          ),
          Text(
            "${product.quantity} units",
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalStockSection(BuildContext context, List<CriticalProduct> criticalProducts) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 20, color: AppColor.error),
                const SizedBox(width: 8),
                Text(
                  "Critical Low-Stock Products",
                  style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.neutral),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...criticalProducts.take(5).map((product) => _buildCriticalProductRow(context, product)),
          ],
        ),
      ),
    );
  }

  Widget _buildCriticalProductRow(BuildContext context, CriticalProduct product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.neutral),
                ),
                const SizedBox(height: 4),
                Text(
                  "Stock: ${product.stock} (Alert at: ${product.threshold})",
                  style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showOrderDialog(context, product),
            style: ElevatedButton.styleFrom(
              backgroundColor: product.stock == 0 ? AppColor.error : AppColor.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              product.stock == 0 ? "Order Now" : "Restock",
              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderDialog(BuildContext context, CriticalProduct product) {
    final int recommendedQty = (product.threshold - product.stock) < 0 ? 0 : (product.threshold - product.stock);
    final TextEditingController quantityController = TextEditingController(text: recommendedQty.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Restock ${product.name}",
          style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.primary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Current Stock:", style: GoogleFonts.manrope(fontSize: 14)),
                      Text("${product.stock} units", style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Alert Limit:", style: GoogleFonts.manrope(fontSize: 14)),
                      Text("${product.threshold} units", style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Suggested Add:", style: GoogleFonts.manrope(fontSize: 14, color: AppColor.success)),
                      Text("$recommendedQty units", style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppColor.success)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.manrope(fontSize: 16, color: AppColor.neutral),
              decoration: InputDecoration(
                labelText: "Amount to Add",
                labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColor.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixText: "units",
                suffixStyle: GoogleFonts.manrope(color: AppColor.secondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.manrope(color: AppColor.secondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              int orderQty = int.tryParse(quantityController.text) ?? 0;
              if (orderQty > 0) {
                final productVm = context.read<ProductViewModel>();
                final originalProduct = productVm.allProducts?.firstWhere(
                      (p) => p.id == product.productId,
                  orElse: () => ProductModel(id: product.productId, name: product.name, price: 0, stock: 0, threshold: 0, category: ''),
                );
                if (originalProduct != null) {
                  await productVm.updateProduct(
                    originalProduct.copyWith(stock: originalProduct.stock + orderQty),
                  );
                  Fluttertoast.showToast(
                    msg: "Restocked ${product.name} by $orderQty units!",
                    backgroundColor: AppColor.success,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.primary),
            child: Text("Confirm", style: GoogleFonts.manrope(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Import CSV Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _importUnifiedCSV(context),
              icon: const Icon(Icons.upload_file, color: Colors.white),
              label: Text(
                "Import CSV",
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Products Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductListScreen()),
                );
              },
              icon: const Icon(Icons.list_alt, color: AppColor.primary),
              label: Text(
                "Products",
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.bold,
                  color: AppColor.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColor.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    return "${now.day}/${now.month}/${now.year}";
  }
}

class TopProduct {
  final String name;
  final int quantity;
  final int rank;
  TopProduct({required this.name, required this.quantity, required this.rank});
}

class CriticalProduct {
  final String name;
  final int stock;
  final int threshold;
  final String productId;
  CriticalProduct({required this.name, required this.stock, required this.threshold, required this.productId});
}