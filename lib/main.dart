import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'services/firebase_services.dart';
import 'utils/colors.dart';
import 'view/splash_screen.dart';

// Repositories
import 'repo/auth_repo_impl.dart';
import 'repo/product_repo_impl.dart';
import 'repo/sale_repo_impl.dart';
import 'repo/prediction_repo_impl.dart';
import 'repo/order_repo_impl.dart';
import 'repo/settings_repo_impl.dart';

// ViewModels
import 'viewmodel/auth_viewmodel.dart';
import 'viewmodel/product_viewmodel.dart';
import 'viewmodel/sale_viewmodel.dart';
import 'viewmodel/prediction_viewmodel.dart';
import 'viewmodel/order_viewmodel.dart';
import 'viewmodel/settings_viewmodel.dart';
import 'viewmodel/dashboard_viewmodel.dart';
import 'viewmodel/analytics_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print("STEP 1");
  await FirebaseServices().initialize();

  print("STEP 2");
  await SharedPreferences.getInstance();

  print("STEP 3");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            authRepo: AuthRepoImpl(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductViewModel(
            productRepo: ProductRepoImpl(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SaleViewModel(
            saleRepo: SaleRepoImpl(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PredictionViewModel(
            predictionRepo: PredictionRepoImpl(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => OrderViewModel(
            orderRepo: OrderRepoImpl(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsViewModel(
            settingsRepo: SettingsRepoImpl(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardViewModel(
            productRepo: ProductRepoImpl(),
            saleRepo: SaleRepoImpl(),
            authRepo: AuthRepoImpl(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AnalyticsViewModel(
            saleRepo: SaleRepoImpl(),
            productRepo: ProductRepoImpl(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartShelf',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Manrope',
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: AppColor.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColor.primary,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}