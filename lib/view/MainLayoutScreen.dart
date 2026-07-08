// view/MainLayoutScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartshelf/view/AIpredictions_screen.dart';

import '../utils/colors.dart';
import 'analytics.dart';
import 'order_history_screen.dart';
import 'priority_dashboard_screen.dart';
import 'product_list_screen.dart';
import 'sales_history_screen.dart';
import 'settings_screen.dart';
import 'suggested_order.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  // The 4 Core Primary Screens
  final List<Widget> _primaryScreens = [
    const PriorityDashboardScreen(),
    const ProductListScreen(),
    const SalesHistoryScreen(),
    const AIPredictionsScreen(), // Fixed to match your filename case
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      // If index is 4, show the More Hub Page, otherwise render the core tab screens
      body: _currentIndex == 4 ? _buildMoreHubMenu() : _primaryScreens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColor.primary,
        unselectedItemColor: AppColor.secondary,
        selectedLabelStyle: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: GoogleFonts.manrope(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: "Stock",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: "Sales",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph_outlined),
            activeIcon: Icon(Icons.auto_graph),
            label: "AI",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view),
            label: "More",
          ),
        ],
      ),
    );
  }

  // Beautiful Pop-up/Hub panel mapping all remaining views from image_2c6cbe.png
  Widget _buildMoreHubMenu() {
    final List<Map<String, dynamic>> extendedScreens = [
      {
        "title": "Suggested Orders",
        "subtitle": "Restock optimization sheet",
        "icon": Icons.shopping_cart_outlined,
        "color": Colors.blue,
        "target": const SuggestedOrderScreen(),
      },
      {
        "title": "Order History",
        "subtitle": "Review previous warehouse supply logs",
        "icon": Icons.history,
        "color": Colors.orange,
        "target": const OrderHistoryScreen(),
      },
      {
        "title": "Deep Analytics",
        "subtitle": "Advanced metric visualization charts",
        "icon": Icons.analytics_outlined,
        "color": Colors.purple,
        "target": const AnalyticsScreen(), // Maps to analytics.dart
      },
      {
        "title": "Settings",
        "subtitle": "Store config, profiling & security options",
        "icon": Icons.settings_outlined,
        "color": Colors.teal,
        "target": const SettingsScreen(),
      },
    ];

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        elevation: 0,
        title: Text(
          "Management Hub",
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColor.primary.withOpacity(0.05), Colors.transparent],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              "Additional Services",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: extendedScreens.length,
              itemBuilder: (context, index) {
                final item = extendedScreens[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => item["target"]),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item["color"].withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item["icon"], color: item["color"], size: 24),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item["title"],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColor.neutral,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item["subtitle"],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: AppColor.secondary,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}