import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';

class AIPredictionsScreen extends StatefulWidget {
  const AIPredictionsScreen({super.key});

  @override
  State<AIPredictionsScreen> createState() => _AIPredictionsScreenState();
}

class _AIPredictionsScreenState extends State<AIPredictionsScreen> {
  List<PredictionItem> predictions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    // Load products
    final String? productsJson = prefs.getString('products');
    // Load sales
    final String? salesJson = prefs.getString('sales');

    List<Product> products = [];
    List<Sale> sales = [];

    if (productsJson != null) {
      List<dynamic> decoded = json.decode(productsJson);
      products = decoded.map((e) => Product.fromJson(e)).toList();
    }

    if (salesJson != null) {
      List<dynamic> decoded = json.decode(salesJson);
      sales = decoded.map((e) => Sale.fromJson(e)).toList();
    }

    // Generate predictions for each product
    predictions = [];
    for (var product in products) {
      final productSales = sales.where((s) => s.productId == product.id).toList();
      final prediction = _calculatePrediction(product, productSales);
      predictions.add(prediction);
    }

    // Load saved manual adjustments
    final String? savedPredictionsJson = prefs.getString('manual_predictions');
    if (savedPredictionsJson != null) {
      Map<String, dynamic> saved = json.decode(savedPredictionsJson);
      for (var pred in predictions) {
        if (saved.containsKey(pred.productId)) {
          pred.predictedQuantity = saved[pred.productId];
        }
      }
    }

    setState(() => _isLoading = false);
  }

  PredictionItem _calculatePrediction(Product product, List<Sale> sales) {
    if (sales.length < 7) {
      return PredictionItem(
        productId: product.id,
        name: product.name,
        currentStock: product.stock,
        predictedQuantity: 0,
        confidence: "Insufficient",
        history: sales.map((s) => s.quantity).toList(),
      );
    }

    // Group sales by day of week
    Map<int, List<int>> salesByWeekday = {};
    for (var sale in sales) {
      int weekday = sale.timestamp.weekday;
      salesByWeekday[weekday] ??= [];
      salesByWeekday[weekday]!.add(sale.quantity);
    }

    // Calculate average for each weekday
    Map<int, double> avgByWeekday = {};
    for (var entry in salesByWeekday.entries) {
      if (entry.value.length >= 4) {
        avgByWeekday[entry.key] = entry.value.take(4).reduce((a, b) => a + b) / 4;
      } else if (entry.value.isNotEmpty) {
        avgByWeekday[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }

    // Sum for next 7 days
    double totalPrediction = 0;
    for (int day = 1; day <= 7; day++) {
      totalPrediction += avgByWeekday[day] ?? 0;
    }

    int predictedQty = totalPrediction.round();

    // Determine confidence
    String confidence;
    if (sales.length >= 28) {
      confidence = "High";
    } else if (sales.length >= 14) {
      confidence = "Medium";
    } else {
      confidence = "Low";
    }

    return PredictionItem(
      productId: product.id,
      name: product.name,
      currentStock: product.stock,
      predictedQuantity: predictedQty > 0 ? predictedQty : 0,
      confidence: confidence,
      history: sales.map((s) => s.quantity).toList(),
    );
  }

  Future<void> _saveManualPrediction(String productId, int newValue) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedJson = prefs.getString('manual_predictions');
    Map<String, dynamic> saved = {};

    if (savedJson != null) {
      saved = json.decode(savedJson);
    }

    saved[productId] = newValue;
    await prefs.setString('manual_predictions', json.encode(saved));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "AI Predictions",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                Icon(Icons.auto_graph, size: 18, color: AppColor.primary),
                const SizedBox(width: 8),
                Text(
                  "Based on your last 4 weeks of sales",
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppColor.secondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  final item = predictions[index];
                  return _buildPredictionCard(item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(PredictionItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.neutral,
                  ),
                ),
              ),
              _buildConfidenceBadge(item.confidence),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 16, color: AppColor.secondary),
              const SizedBox(width: 6),
              Text(
                "Current Stock: ${item.currentStock} units",
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColor.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColor.primary.withValues(alpha: 0.08), AppColor.primary.withValues(alpha: 0.02)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.primary.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "AI Prediction:",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColor.neutral,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      "${item.predictedQuantity} units",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _showAdjustDialog(item),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit, size: 16, color: AppColor.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (item.confidence != "Insufficient" && item.history.isNotEmpty)
            TextButton.icon(
              onPressed: () => _showWhyDialog(item),
              icon: Icon(Icons.help_outline, size: 16, color: AppColor.tertiary),
              label: Text(
                "Why this prediction?",
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColor.tertiary,
                ),
              ),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          if (item.confidence == "Insufficient")
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColor.secondary),
                  const SizedBox(width: 6),
                  Text(
                    "Not enough sales history (need 7+ days)",
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppColor.secondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge(String confidence) {
    Color color;
    String text;

    switch (confidence) {
      case "High":
        color = AppColor.success;
        text = "High Confidence";
        break;
      case "Medium":
        color = AppColor.tertiary;
        text = "Medium Confidence";
        break;
      case "Low":
        color = AppColor.warning;
        text = "Low Confidence";
        break;
      default:
        color = AppColor.secondary;
        text = "Insufficient Data";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showWhyDialog(PredictionItem item) {
    List<int> history = item.history.length > 4
        ? item.history.reversed.take(4).toList().reversed.toList()
        : item.history;

    int average = history.isEmpty ? 0 : history.reduce((a, b) => a + b) ~/ history.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Why ${item.predictedQuantity} units?",
          style: GoogleFonts.spaceGrotesk(
            color: AppColor.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Last ${history.length} weeks of sales for ${item.name}:",
              style: GoogleFonts.manrope(fontSize: 13, color: AppColor.secondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: history.asMap().entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Week ${entry.key + 1}",
                        style: GoogleFonts.manrope(fontSize: 11, color: AppColor.secondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${entry.value} units",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.calculate, size: 18, color: AppColor.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Average: $average units/week",
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColor.neutral,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: GoogleFonts.manrope(color: AppColor.secondary),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(PredictionItem item) {
    TextEditingController controller = TextEditingController(text: item.predictedQuantity.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Adjust Prediction",
          style: GoogleFonts.spaceGrotesk(
            color: AppColor.neutral,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Change prediction for ${item.name}",
              style: GoogleFonts.manrope(fontSize: 14, color: AppColor.secondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.manrope(fontSize: 16),
              decoration: InputDecoration(
                labelText: "New prediction (units)",
                labelStyle: GoogleFonts.manrope(color: AppColor.secondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColor.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.manrope(color: AppColor.secondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              int newValue = int.tryParse(controller.text) ?? item.predictedQuantity;
              setState(() {
                item.predictedQuantity = newValue;
              });
              await _saveManualPrediction(item.productId, newValue);
              Navigator.pop(context);
              Fluttertoast.showToast(msg: "Prediction updated to $newValue units");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              "Save",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Temporary models
class PredictionItem {
  final String productId;
  final String name;
  final int currentStock;
  int predictedQuantity;
  final String confidence;
  final List<int> history;

  PredictionItem({
    required this.productId,
    required this.name,
    required this.currentStock,
    required this.predictedQuantity,
    required this.confidence,
    required this.history,
  });
}

class Product {
  final String id;
  final String name;
  final int stock;
  final int threshold;
  final int price;
  final String category;
  final int? oldPrice;

  Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.threshold,
    required this.price,
    required this.category,
    this.oldPrice,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'stock': stock,
    'threshold': threshold,
    'price': price,
    'category': category,
    'oldPrice': oldPrice,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    stock: json['stock'],
    threshold: json['threshold'],
    price: json['price'],
    category: json['category'],
    oldPrice: json['oldPrice'],
  );
}

class Sale {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final int totalPrice;
  final DateTime timestamp;

  Sale({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'totalPrice': totalPrice,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
    id: json['id'],
    productId: json['productId'],
    productName: json['productName'],
    quantity: json['quantity'],
    totalPrice: json['totalPrice'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}