import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';
import '../viewmodel/sale_viewmodel.dart';
import '../viewmodel/product_viewmodel.dart';
import '../model/sale_model.dart';
import '../model/product_model.dart';

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
      context.read<SaleViewModel>().getAllSales();
      context.read<ProductViewModel>().getAllProduct();
    });
  }

  @override
  Widget build(BuildContext context) {
    final saleVm = context.watch<SaleViewModel>();
    final productVm = context.watch<ProductViewModel>();

    final sales = saleVm.sales ?? [];
    final products = productVm.allProducts ?? [];
    final isLoading = saleVm.loading || productVm.loading;

    // Calculate analytics based on selected period
    final now = DateTime.now();
    DateTime startDate;
    DateTime previousStartDate;

    switch (selectedPeriod) {
      case "This Week":
        startDate = DateTime(now.year, now.month, now.day - now.weekday + 1);
        previousStartDate = startDate.subtract(const Duration(days: 7));
        break;
      case "This Month":
        startDate = DateTime(now.year, now.month, 1);
        previousStartDate = DateTime(now.year, now.month - 1, 1);
        break;
      default:
        startDate = DateTime(now.year, 1, 1);
        previousStartDate = DateTime(now.year - 1, 1, 1);
    }

    // Calculate total sales
    final totalSales = sales        .where((s) => s.timestamp.isAfter(startDate))
        .fold(0, (sum, s) => sum + s.totalPrice);

    final previousTotal = sales
        .where((s) => s.timestamp.isAfter(previousStartDate) && s.timestamp.isBefore(startDate))
        .fold(0, (sum, s) => sum + s.totalPrice);

    int percentChange = 0;
    if (previousTotal > 0) {
      percentChange = ((totalSales - previousTotal) / previousTotal * 100).round();
    }

    // Calculate daily/weekly/monthly sales
    List<DailySales> salesData = [];
    if (selectedPeriod == "This Week") {
      for (int i = 0; i < 7; i++) {
        final day = startDate.add(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        final daySales = sales
            .where((s) => s.timestamp.isAfter(dayStart) && s.timestamp.isBefore(dayEnd))
            .fold(0, (sum, s) => sum + s.totalPrice);
        salesData.add(DailySales(_getDayName(i), daySales));
      }
    } else if (selectedPeriod == "This Month") {
      final daysInMonth = DateTime(startDate.year, startDate.month + 1, 0).day;
      final weeks = ((daysInMonth + 6) / 7).ceil();
      for (int week = 0; week < weeks; week++) {
        final weekStart = startDate.add(Duration(days: week * 7));
        final weekEnd = weekStart.add(const Duration(days: 7));
        final weekSales = sales
            .where((s) => s.timestamp.isAfter(weekStart) && s.timestamp.isBefore(weekEnd))
            .fold(0, (sum, s) => sum + s.totalPrice);
        salesData.add(DailySales("Week ${week + 1}", weekSales));
      }
    } else {
      for (int month = 0; month < 12; month++) {
        final monthStart = DateTime(startDate.year, month + 1, 1);
        final monthEnd = DateTime(startDate.year, month + 2, 1);
        final monthSales = sales
            .where((s) => s.timestamp.isAfter(monthStart) && s.timestamp.isBefore(monthEnd))
            .fold(0, (sum, s) => sum + s.totalPrice);
        salesData.add(DailySales(_getMonthName(month), monthSales));
      }
    }

    // Top and bottom products
    Map<String, int> productSalesMap = {};
    for (var sale in sales.where((s) => s.timestamp.isAfter(startDate))) {
      productSalesMap[sale.productId] = (productSalesMap[sale.productId] ?? 0) + sale.quantity;
    }

    var sortedProducts = productSalesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topProducts = <TopProduct>[];
    for (int i = 0; i < sortedProducts.length && i < 5; i++) {
      final product = products.firstWhere(
            (p) => p.id == sortedProducts[i].key,
        orElse: () => ProductModel(id: '', name: 'Unknown'),
      );
      topProducts.add(TopProduct(
        name: product.name ?? 'Unknown',
        quantity: sortedProducts[i].value,
        rank: i + 1,
      ));
    }

    var bottomSorted = sortedProducts.toList()..sort((a, b) => a.value.compareTo(b.value));
    final bottomProducts = <TopProduct>[];
    for (int i = 0; i < bottomSorted.length && i < 5; i++) {
      final product = products.firstWhere(
            (p) => p.id == bottomSorted[i].key,
        orElse: () => ProductModel(id: '', name: 'Unknown'),
      );
      if (product.name != 'Unknown') {
        bottomProducts.add(TopProduct(
          name: product.name ?? 'Unknown',
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
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
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
        onRefresh: () async {
          await saleVm.getAllSales();
          await productVm.getAllProduct();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    Text(
                      "Total Sales",
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "NPR ${_formatNumber(totalSales)}",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          percentChange >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${percentChange >= 0 ? '+' : ''}$percentChange% from previous period",
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (salesData.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColor.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedPeriod == "This Week" ? "Daily Sales (NPR)" :
                        selectedPeriod == "This Month" ? "Weekly Sales (NPR)" : "Monthly Sales (NPR)",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColor.neutral,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 250,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: salesData.map((e) => e.amount.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    int index = value.toInt();
                                    if (index >= 0 && index < salesData.length) {
                                      return Text(
                                        salesData[index].day,
                                        style: GoogleFonts.manrope(fontSize: 10),
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
                                    return Text(
                                      _formatCompactNumber(value.toInt()),
                                      style: GoogleFonts.manrope(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(salesData.length, (index) {
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: salesData[index].amount.toDouble(),
                                    color: AppColor.primary,
                                    width: selectedPeriod == "This Week" ? 30 : 20,
                                    borderRadius: BorderRadius.circular(6),
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
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.background,
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
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColor.neutral,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(
                      topProducts.isEmpty ? 1 : topProducts.length,
                          (index) {
                        final product = topProducts.isEmpty
                            ? TopProduct(name: 'No sales data', quantity: 0, rank: 1)
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
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.background,
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
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColor.neutral,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(
                      bottomProducts.isEmpty ? 1 : bottomProducts.length,
                          (index) {
                        final product = bottomProducts.isEmpty
                            ? TopProduct(name: 'No sales data', quantity: 0, rank: 1)
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
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isTop ? Colors.amber : AppColor.error,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColor.neutral,
              ),
            ),
          ),
          Text(
            "$quantity units",
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isTop ? AppColor.primary : AppColor.secondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int index) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[index];
  }

  String _getMonthName(int index) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[index];
  }

  String _formatNumber(int number) {
    if (number >= 100000) {
      return '${(number / 1000).toStringAsFixed(0)}K';
    }
    return number.toString();
  }

  String _formatCompactNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

class DailySales {
  final String day;
  final int amount;
  DailySales(this.day, this.amount);
}

class TopProduct {
  final String name;
  final int quantity;
  final int rank;
  TopProduct({required this.name, required this.quantity, required this.rank});
}