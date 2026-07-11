import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:smartshelf/repo/product_repo.dart';
import 'package:smartshelf/view/MainLayoutScreen.dart';
import 'package:smartshelf/viewmodel/theme_viewmodel.dart';

import 'services/firebase_services.dart';
import 'utils/colors.dart';

// Screens
import 'view/splash_screen.dart';
import 'view/login_screen.dart';

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

  await FirebaseServices().initialize();
  await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            authRepo: AuthRepoImpl(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductViewModel(
            productRepo: ProductRepoImpl(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SaleViewModel(
            saleRepo: SaleRepoImpl(),
            productRepo: ProductRepoImpl(),
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
    return Consumer<ThemeViewModel>(
      builder: (context, themeVm, child) {
        return MaterialApp(
          title: 'SmartShelf',
          debugShowCheckedModeBanner: false,
          themeMode: themeVm.isDarkMode ? ThemeMode.dark : ThemeMode.light,

          // Light Theme configurations
          theme: ThemeData(
            brightness: Brightness.light,
            fontFamily: 'Manrope',
            primaryColor: AppColor.primary,
            scaffoldBackgroundColor: AppColor.background,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColor.primary,
              elevation: 0,
              centerTitle: true,
            ),
          ),

          // FIXED: Adding explicit matching Dark Theme properties enforces seamless system-wide color distribution
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'Manrope',
            primaryColor: AppColor.primary,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColor.primary,
              elevation: 0,
              centerTitle: true,
            ),
          ),

          home: Consumer<AuthViewModel>(
            builder: (context, auth, _) {
              if (auth.isLoading && !auth.isAuthenticated) {
                return const SplashScreen();
              }

              return auth.isAuthenticated
                  ? const MainLayoutScreen()
                  : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}