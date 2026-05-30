import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartshelf/AIpredictions_screen.dart';
import 'package:smartshelf/dashboard_screen.dart';
import 'package:smartshelf/productlist_screen.dart';
import 'package:smartshelf/logsale.dart';

import 'package:smartshelf/settings.dart';
import 'package:smartshelf/utils/colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductListScreen(),
    const LogSaleScreen(),
    const AIPredictionsScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    "SmartShelf",
    "Products",
    "Log Sale",
    "AI Predictions",
    "Settings",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (int index) {
          setState(() {
            currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColor.background,
        selectedItemColor: AppColor.primary,
        unselectedItemColor: AppColor.secondary,
        selectedLabelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "HOME",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: "PRODUCTS",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sell_outlined),
            activeIcon: Icon(Icons.sell),
            label: "SALE",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_graph_outlined),
            activeIcon: Icon(Icons.auto_graph),
            label: "PREDICTIONS",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: "SETTINGS",
          ),
        ],
        onTap: (int index) {
          setState(() {
            currentIndex = index;
            _pageController.jumpToPage(index);
          });
        },
      ),
    );
  }
}