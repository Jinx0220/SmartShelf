import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'utils/colors.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String selectedPeriod = "This Week";
  final List<String> periods = ["This Week", "This Month", "This Year"];

  final List<DailySales> weeklySales = [
    DailySales("Mon", 1250),
    DailySales("Tue", 890),
    DailySales("Wed", 2100),
    DailySales("Thu", 1560),
    DailySales("Fri", 2430),
    DailySales("Sat", 1870),
    DailySales("Sun", 0),
  ];

  final List<TopProduct> topProducts = [
    TopProduct("Milk 1L", 45, 1),
    TopProduct("Wai Wai Noodles", 38, 2),
    TopProduct("Coke 500ml", 32, 3),
    TopProduct("Cooking Oil 1L", 22, 4),
    TopProduct("Salt 1kg", 18, 5),
  ];

  final List<TopProduct> bottomProducts = [
    TopProduct("Imported Olive Oil", 1, 1),
    TopProduct("Saffron Threads", 2, 2),
    TopProduct("Canned Artichokes", 2, 3),
    TopProduct("Exotic Spice Mix", 3, 4),
    TopProduct("Organic Honey", 4, 5),
  ];

  @override
  Widget build(BuildContext context) {
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
                setState(() {
                  selectedPeriod = value!;
                });
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  colors: [AppColor.primary, AppColor.primary.withOpacity(0.7)],
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
                    "NPR 42,500",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.trending_up, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        "+12% from last week",
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
                    "Daily Sales (NPR)",
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
                        maxY: 3000,
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index >= 0 && index < weeklySales.length) {
                                  return Text(
                                    weeklySales[index].day,
                                    style: GoogleFonts.manrope(fontSize: 12),
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
                                  "₹${value.toInt()}",
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
                        barGroups: List.generate(weeklySales.length, (index) {
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: weeklySales[index].amount.toDouble(),
                                color: AppColor.primary,
                                width: 30,
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
                  ...List.generate(topProducts.length, (index) {
                    final product = topProducts[index];
                    return _buildProductRow(
                      rank: product.rank,
                      name: product.name,
                      quantity: product.quantity,
                      isTop: true,
                    );
                  }),
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
                  ...List.generate(bottomProducts.length, (index) {
                    final product = bottomProducts[index];
                    return _buildProductRow(
                      rank: product.rank,
                      name: product.name,
                      quantity: product.quantity,
                      isTop: false,
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
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
              color: isTop ? Colors.amber.withOpacity(0.2) : AppColor.error.withOpacity(0.1),
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
  TopProduct(this.name, this.quantity, this.rank);
}