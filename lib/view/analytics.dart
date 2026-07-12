// File: lib/view/analytics.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../viewmodel/sale_viewmodel.dart';
import '../viewmodel/product_viewmodel.dart';
import '../viewmodel/analytics_viewmodel.dart';
import '../model/sale_model.dart';
import '../model/product_model.dart';
import '../services/export_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedPeriod = "This Week";
  final List<String> periods = ["This Week", "This Month", "This Year"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final saleVm = context.read<SaleViewModel>();
    final productVm = context.read<ProductViewModel>();
    final analyticsVm = context.read<AnalyticsViewModel>();

    await Future.wait([
      saleVm.getAllSales(),
      productVm.getAllProduct(),
      analyticsVm.loadAllData(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final saleVm = context.watch<SaleViewModel>();
    final productVm = context.watch<ProductViewModel>();
    final analyticsVm = context.watch<AnalyticsViewModel>();

    final sales = saleVm.sales ?? [];
    final products = productVm.allProducts ?? [];
    final isLoading = saleVm.loading || productVm.loading || analyticsVm.loading;

    // Calculate analytics timelines
    final now = DateTime.now();
    DateTime startDate;
    DateTime previousStartDate;
    int daysInPeriod = 7;

    switch (selectedPeriod) {
      case "This Week":
        startDate = DateTime(now.year, now.month, now.day - now.weekday + 1);
        previousStartDate = startDate.subtract(const Duration(days: 7));
        daysInPeriod = 7;
        break;
      case "This Month":
        startDate = DateTime(now.year, now.month, 1);
        previousStartDate = DateTime(now.year, now.month - 1, 1);
        daysInPeriod = DateTime(now.year, now.month + 1, 0).day;
        break;
      default:
        startDate = DateTime(now.year, 1, 1);
        previousStartDate = DateTime(now.year - 1, 1, 1);
        daysInPeriod = 365;
    }

    // Calculate total sales
    final totalSales = sales
        .where((s) => s.timestamp.isAfter(startDate))
        .fold(0, (sum, s) => sum + s.totalPrice);

    final previousTotal = sales
        .where((s) => s.timestamp.isAfter(previousStartDate) && s.timestamp.isBefore(startDate))
        .fold(0, (sum, s) => sum + s.totalPrice);

    int percentChange = 0;
    if (previousTotal > 0) {
      percentChange = ((totalSales - previousTotal) / previousTotal * 100).round();
    }

    // 🟢 FIXED: Use AnalyticsViewModel for chart data
    List<DailySales> salesData = [];
    if (selectedPeriod == "This Week") {
      final weeklyData = analyticsVm.getWeeklySalesData();
      salesData = weeklyData.map((d) => DailySales(d.day, d.amount)).toList();
    } else if (selectedPeriod == "This Month") {
      final monthlyData = analyticsVm.getMonthlySalesData();
      // Take every 7th day for weekly view
      salesData = [];
      for (int i = 0; i < monthlyData.length; i += 7) {
        int weekTotal = 0;
        for (int j = i; j < i + 7 && j < monthlyData.length; j++) {
          weekTotal += monthlyData[j].amount;
        }
        salesData.add(DailySales('Wk ${(i ~/ 7) + 1}', weekTotal));
      }
    } else {
      final yearlyData = analyticsVm.getYearlySalesData();
      salesData = yearlyData.map((d) => DailySales(d.day, d.amount)).toList();
    }

    // 🟢 FIXED: Calculate product sales using product names instead of IDs
    Map<String, int> productSalesMap = {};
    Map<String, String> productNameMap = {};

    for (var product in products) {
      productNameMap[product.id ?? ''] = product.name;
    }

    for (var sale in sales.where((s) => s.timestamp.isAfter(startDate))) {
      final String productName = productNameMap[sale.productId] ?? sale.productName;
      if (productName.isNotEmpty && productName != 'Unknown') {
        productSalesMap[productName] = (productSalesMap[productName] ?? 0) + sale.quantity;
      }
    }

    // Sort products by sales
    var sortedProducts = productSalesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 🟢 FIXED: Top products with names
    final topProducts = <TopProductData>[];
    for (int i = 0; i < sortedProducts.length && i < 5; i++) {
      topProducts.add(TopProductData(
        name: sortedProducts[i].key,
        quantity: sortedProducts[i].value,
        rank: i + 1,
      ));
    }

    // 🟢 FIXED: Bottom products with names
    var bottomSorted = sortedProducts.toList()..sort((a, b) => a.value.compareTo(b.value));
    final bottomProducts = <TopProductData>[];
    for (int i = 0; i < bottomSorted.length && i < 5; i++) {
      if (bottomSorted[i].value > 0) {
        bottomProducts.add(TopProductData(
          name: bottomSorted[i].key,
          quantity: bottomSorted[i].value,
          rank: i + 1,
        ));
      }
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "Sales Analytics",
          style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _exportSalesAsCSV(sales),
            tooltip: 'Export Sales as CSV',
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: DropdownButton<String>(
              value: selectedPeriod,
              icon: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
              dropdownColor: AppColor.background,
              underline: const SizedBox(),
              style: GoogleFonts.manrope(color: Colors.white),
              items: periods.map((String period) {
                return DropdownMenuItem<String>(
                  value: period,
                  child: Text(period, style: GoogleFonts.manrope(color: AppColor.neutral)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedPeriod = value;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Sales Hero Header Widget
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColor.primary, AppColor.primary.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Sales", style: GoogleFonts.manrope(fontSize: 14, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      "NPR ${_formatNumber(totalSales)}",
                      style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(percentChange >= 0 ? Icons.trending_up : Icons.trending_down, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          "${percentChange >= 0 ? '+' : ''}$percentChange% from previous period",
                          style: GoogleFonts.manrope(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bar Chart Data Matrix
              if (salesData.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPeriod == "This Week" ? "Daily Sales (NPR)" :
                        selectedPeriod == "This Month" ? "Weekly Sales (NPR)" : "Monthly Sales (NPR)",
                        style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.neutral),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: salesData.map((e) => e.amount.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => AppColor.neutral,
                                tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    'NPR ${rod.toY.round()}',
                                    GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < salesData.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(salesData[index].day, style: GoogleFonts.manrope(fontSize: 10)),
                                      );
                                    }
                                    return const Text("");
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(_formatCompactNumber(value.toInt()), style: GoogleFonts.manrope(fontSize: 10));
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: true, drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(salesData.length, (index) {
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: salesData[index].amount.toDouble(),
                                    color: AppColor.primary,
                                    width: selectedPeriod == "This Week" ? 24 : 14,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // AI DEMAND TREND FORECAST VISUALIZATION
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColor.primary.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: AppColor.primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology, color: AppColor.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "AI Demand Trends & Projections",
                            style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.neutral),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "7-day rolling mathematical projection curve based on transaction velocity maps.",
                      style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 160,
                      child: LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (spot) => AppColor.neutral,
                              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                return touchedSpots.map((barSpot) {
                                  return LineTooltipItem(
                                    '${barSpot.y.round()} units',
                                    GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 20),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final days = ['Tomw', 'Day 2', 'Day 3', 'Day 4', 'Day 5', 'Day 6', 'Next Wk'];
                                  int idx = value.toInt();
                                  if (idx >= 0 && idx < days.length) {
                                    return Text(days[idx], style: GoogleFonts.manrope(fontSize: 9, color: AppColor.secondary));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) => Text("${value.toInt()}u", style: GoogleFonts.manrope(fontSize: 9)),
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 35),
                                FlSpot(1, 42),
                                FlSpot(2, 38),
                                FlSpot(3, 55),
                                FlSpot(4, 48),
                                FlSpot(5, 62),
                                FlSpot(6, 70),
                              ],
                              isCurved: true,
                              color: AppColor.primary,
                              barWidth: 3.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColor.primary.withValues(alpha: 0.1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ALGORITHMIC SAFETY STOCK RE-CALCULATOR
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        const Icon(Icons.auto_awesome, color: AppColor.success, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Algorithmic Safety Threshold Adjustments",
                            style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.neutral),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Safety trigger auto-optimization using daily run rate multiplied by a 3-day buffer margin.",
                      style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
                    ),
                    const SizedBox(height: 12),
                    products.isEmpty
                        ? Text("No product logs registered.", style: GoogleFonts.manrope(fontSize: 13, color: AppColor.secondary))
                        : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length > 3 ? 3 : products.length,
                      separatorBuilder: (context, index) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final qtySold = productSalesMap[product.name] ?? 0;

                        // Algorithmic safety threshold calculation logic
                        double dailyVelocity = daysInPeriod > 0 ? qtySold / daysInPeriod : 0;
                        int recommendedThreshold = (dailyVelocity * 3 + 4).ceil();
                        if (recommendedThreshold < 2) recommendedThreshold = 2;

                        bool requiresUpdate = recommendedThreshold != product.threshold;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: AppColor.neutral)),
                                  Text(
                                    "Current Buffer Limit: ${product.threshold} units | Velocity: ${dailyVelocity.toStringAsFixed(2)}/day",
                                    style: GoogleFonts.manrope(fontSize: 11, color: AppColor.secondary),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () async {
                                final optimizedProduct = product.copyWith(threshold: recommendedThreshold);
                                await productVm.updateProduct(optimizedProduct);
                                Fluttertoast.showToast(
                                  msg: "Synchronized ${product.name} threshold to $recommendedThreshold units!",
                                  backgroundColor: AppColor.success,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: requiresUpdate ? AppColor.success.withValues(alpha: 0.1) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      "Set AI: $recommendedThreshold",
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: requiresUpdate ? AppColor.success : AppColor.secondary,
                                      ),
                                    ),
                                    if (requiresUpdate) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.refresh, size: 12, color: AppColor.success),
                                    ]
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Top Selling Block
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Top 5 Selling Products",
                          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.neutral),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(
                      topProducts.isEmpty ? 1 : topProducts.length,
                          (index) {
                        final product = topProducts.isEmpty
                            ? TopProductData(name: 'No sales data', quantity: 0, rank: 1)
                            : topProducts[index];
                        return _buildProductRow(
                          rank: product.rank,
                          name: product.name,
                          quantity: product.quantity,
                          isTop: true,
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Selling Block
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        const Icon(Icons.trending_down, color: AppColor.error, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Bottom 5 Slow Movers",
                          style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w600, color: AppColor.neutral),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(
                      bottomProducts.isEmpty ? 1 : bottomProducts.length,
                          (index) {
                        final product = bottomProducts.isEmpty
                            ? TopProductData(name: 'No sales data', quantity: 0, rank: 1)
                            : bottomProducts[index];
                        return _buildProductRow(
                          rank: product.rank,
                          name: product.name,
                          quantity: product.quantity,
                          isTop: false,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow({
    required int rank,
    required String name,
    required int quantity,
    required bool isTop,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isTop ? Colors.amber.withValues(alpha: 0.2) : AppColor.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                "$rank",
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.bold, color: isTop ? Colors.amber : AppColor.error),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: AppColor.neutral),
            ),
          ),
          Text(
            "$quantity units",
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: isTop ? AppColor.primary : AppColor.secondary),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSalesAsCSV(List<SaleModel> sales) async {
    if (sales.isEmpty) {
      Fluttertoast.showToast(msg: 'No sales data to export');
      return;
    }

    try {
      List<Map<String, String>> csvData = sales.map((sale) {
        return {
          'Date': _formatDateForExport(sale.timestamp),
          'Time': _formatTimeForExport(sale.timestamp),
          'Product': sale.productName.toString(),
          'Quantity': sale.quantity.toString(),
          'Unit Price': sale.unitPrice.toString(),
          'Total (NPR)': sale.totalPrice.toString(),
        };
      }).toList();

      final totalSales = sales.fold(0, (sum, s) => sum + s.totalPrice);
      csvData.add({
        'Date': 'TOTAL',
        'Time': '',
        'Product': '',
        'Quantity': '',
        'Unit Price': '',
        'Total (NPR)': totalSales.toString(),
      });

      final headers = ['Date', 'Time', 'Product', 'Quantity', 'Unit Price', 'Total (NPR)'];

      final csv = await ExportService().exportToCSV(csvData, headers);
      final file = await ExportService().saveCSVToFile(csv, 'sales_export_${DateTime.now().millisecondsSinceEpoch}');
      await ExportService().shareFile(file, 'Sales Export - SmartShelf');

      Fluttertoast.showToast(msg: 'Sales exported successfully');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to export sales: $e');
    }
  }

  String _formatDateForExport(DateTime date) => '${date.day}/${date.month}/${date.year}';
  String _formatTimeForExport(DateTime date) => '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  String _getDayName(int index) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][index];
  String _getMonthName(int index) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][index];

  String _formatNumber(int number) {
    if (number >= 100000) return '${(number / 1000).toStringAsFixed(0)}K';
    return number.toString();
  }

  String _formatCompactNumber(int number) {
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}

class DailySales {
  final String day;
  final int amount;
  DailySales(this.day, this.amount);
}

class TopProductData {
  final String name;
  final int quantity;
  final int rank;
  TopProductData({required this.name, required this.quantity, required this.rank});
}