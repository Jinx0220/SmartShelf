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
import 'package:smartshelf/viewmodel/dashboard_viewmodel.dart';
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

  Future<void> _refreshDashboardData() async {
    if (!mounted) return;
    final productVm = context.read<ProductViewModel>();
    final saleVm = context.read<SaleViewModel>();
    final authVm = context.read<AuthViewModel>();

    try {
      await Future.wait([
        productVm.getAllProduct(),
        saleVm.getAllSales(),
        authVm.loadCurrentUser(),
      ]);
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

  Future<void> _importUnifiedCSV(BuildContext context) async {
    final saleVm = context.read<SaleViewModel>();
    final productVm = context.read<ProductViewModel>();

    debugPrint("=== CSV IMPORT STARTED ===");

    try {
      debugPrint("Opening File Picker...");
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null) {
        debugPrint("File picker was cancelled by user.");
        Fluttertoast.showToast(msg: "File picking cancelled.");
        return;
      }

      debugPrint("File selected successfully: ${result.files.single.name}");
      String csvString = "";

      if (result.files.single.bytes != null) {
        debugPrint("Reading file content via memory bytes...");
        csvString = utf8.decode(result.files.single.bytes!);
      } else if (result.files.single.path != null) {
        debugPrint("Reading file content via local system path...");
        final file = File(result.files.single.path!);
        csvString = await file.readAsString();
      }

      debugPrint("CSV Total String Length: ${csvString.length}");
      if (csvString.trim().isEmpty) {
        debugPrint("Warning: CSV text payload is completely empty.");
        Fluttertoast.showToast(msg: "Selected CSV file is empty.");
        return;
      }

      List<String> lines = csvString.split('\n');
      debugPrint("Total lines discovered in CSV payload: ${lines.length}");
      int progressCount = 0;

      for (int i = 1; i < lines.length; i++) {
        String currentLine = lines[i].trim();
        if (currentLine.isEmpty) continue;

        List<String> columns = currentLine.split(',');
        debugPrint("Processing Row #$i -> Row Raw Text: '$currentLine' -> Discovered Columns Count: ${columns.length}");

        if (columns.length < 4) {
          debugPrint("❌ SKIPPING ROW #$i: Columns count (${columns.length}) is less than 4 required data fields.");
          continue;
        }

        // 🆕 ADDED FOR DEMO: Force dates to Today's date (July 2026) so they show up
        // instantly on your dashboard's "TODAY'S SALES" and "WEEKLY SALES" cards!
        DateTime saleDate = DateTime.now();

        String pName = columns[1].trim();
        int qty = int.tryParse(columns[2].trim()) ?? 0;
        double customPrice = double.tryParse(columns[3].trim()) ?? 100.0;
        String categoryName = columns.length > 4 ? columns[4].trim() : 'General';

        debugPrint("Pushing row records to Firestore -> Item: $pName, Qty: $qty...");

        await saleVm.addHistoricalSaleWithProfile(
          productName: pName,
          quantity: qty,
          date: saleDate,
          fallbackPrice: customPrice,
          category: categoryName,
        );

        progressCount++;
      }

      debugPrint("=== LOOP COMPLETED. Total successfully written: $progressCount ===");

      Fluttertoast.showToast(
        msg: "Successfully imported $progressCount transaction history logs!",
        backgroundColor: AppColor.success,
        textColor: Colors.white,
      );

      if (context.mounted) {
        // Refresh individual view models
        await productVm.getAllProduct();
        await saleVm.getAllSales();

        // 🆕 ADDED FOR REFRESH: Force your DashboardViewModel to update all screens right now!
        try {
          final dashboardVm = context.read<DashboardViewModel>();
          await dashboardVm.loadDashboardData();
          debugPrint("🔄 DashboardViewModel refreshed successfully!");
        } catch (e) {
          debugPrint("⚠️ DashboardViewModel reload skipped: $e");
        }
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
      final ProductModel target = totalCatalog.firstWhere(
            (element) => element.name.trim().toLowerCase() == productName.trim().toLowerCase(),
        orElse: () => ProductModel(
          id: 'stub_${productName.replaceAll(' ', '_').toLowerCase()}',
          name: productName,
          price: 150.0,
          stock: 10,
          threshold: 2,
          category: 'Fast-Moving',
        ),
      );

      if (target.stock <= 0 && target.id != null && !target.id!.startsWith('stub_')) {
        Fluttertoast.showToast(
          msg: "Cannot log sale: $productName is completely out of stock!",
          backgroundColor: AppColor.error,
          textColor: Colors.white,
        );
        return;
      }

      final int productUnitPrice = target.price.toInt();
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

      final bool status = await saleVm.addSale(instantSaleRecord);

      if (status && target.id != null && !target.id!.startsWith('stub_')) {
        await productVm.updateProduct(target.copyWith(stock: target.stock - 1));
        Fluttertoast.showToast(
          msg: "⚡ Quick Added: 1x $productName!",
          backgroundColor: AppColor.success,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_SHORT,
        );
      } else if (status) {
        Fluttertoast.showToast(
          msg: "⚡ Quick Added: 1x $productName (Demo Mode)!",
          backgroundColor: AppColor.primary,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Quick sale error: $e",
        backgroundColor: AppColor.error,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();
    final saleVm = context.watch<SaleViewModel>();
    final authVm = context.watch<AuthViewModel>();

    final products = productVm.allProducts ?? [];
    final sales = saleVm.sales ?? [];
    final user = authVm.user;

    final int todaySalesAmount = saleVm.todaySales;
    final int weeklySalesAmount = saleVm.weeklySales;
    final int lowStockCount = products.where((p) => p.isLowStock).length;

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

                  _buildQuickAddShortcutShelf(context, saleVm.topProducts, products, saleVm, productVm),
                  const SizedBox(height: 16),

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

  Widget _buildQuickAddShortcutShelf(
      BuildContext context,
      Map<String, int>? topFrequentData,
      List<ProductModel> catalog,
      SaleViewModel saleVm,
      ProductViewModel productVm,
      ) {
    final List<String> shortListItems = (topFrequentData != null && topFrequentData.isNotEmpty)
        ? topFrequentData.keys.take(8).toList()
        : ['Milk', 'Bread', 'Eggs', 'Sugar', 'Rice'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "Frequent Sales Quick-Add (1-Tap)",
              style: GoogleFonts.spaceGrotesk(fontSize: 13, fontWeight: FontWeight.bold, color: AppColor.neutral, letterSpacing: 0.3),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: shortListItems.length,
              itemBuilder: (context, idx) {
                final String itemName = shortListItems[idx];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _executeInstantQuickSale(itemName, catalog, saleVm, productVm),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColor.primary.withValues(alpha: 0.2)),
                        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 1))],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_circle_outline, size: 16, color: AppColor.primary),
                          const SizedBox(width: 6),
                          Text(
                            itemName,
                            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.neutral),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
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

  // 🟢 FIXED: Completed the restock closure routine pipeline safely to prevent the layout crash
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

  // 🟢 ADDED: Action buttons with Import CSV and Products button
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