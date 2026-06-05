import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartshelf/view/AIpredictions_screen.dart';
import '../utils/colors.dart';
import 'priority_dashboard_screen.dart';
import 'product_list_screen.dart';
import 'log_sale_screen.dart';
import 'settings_screen.dart';
import 'sales_history_screen.dart';  // ← ADD THIS IMPORT

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

  // OPTION 1: Replace PREDICTIONS with SALES HISTORY (if you want 5 tabs total)
  // final List<Widget> _screens = [
  //   const PriorityDashboardScreen(),
  //   const ProductListScreen(),
  //   const LogSaleScreen(),
  //   const SalesHistoryScreen(),  // ← REPLACED AI Predictions
  //   const SettingsScreen(),
  // ];

  // OPTION 2: Add as 6th tab (need to increase bottom nav items)
  // NOTE: BottomNavigationBar only supports up to 5 items by default with type: fixed
  // For 6 items, you need to use a different approach or remove type: fixed

  // OPTION 3: ADD as a new tab by replacing Settings (if Settings is less used)
  final List<Widget> _screens = [
    const PriorityDashboardScreen(),
    const ProductListScreen(),
    const LogSaleScreen(),
    const SalesHistoryScreen(),  // ← ADDED - Replaced AI Predictions
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    "SmartShelf",
    "Products",
    "Log Sale",
    "Sales History",  // ← CHANGED from "AI Predictions"
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
            icon: Icon(Icons.history),  // ← CHANGED from auto_graph
            activeIcon: Icon(Icons.history),
            label: "HISTORY",
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