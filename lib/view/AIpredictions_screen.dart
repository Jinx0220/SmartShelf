import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../viewmodel/product_viewmodel.dart';
import '../viewmodel/sale_viewmodel.dart';
import '../viewmodel/prediction_viewmodel.dart';
import '../model/product_model.dart';
import '../model/sale_model.dart';
import '../model/prediction_model.dart';

class AIPredictionsScreen extends StatefulWidget {
  const AIPredictionsScreen({super.key});

  @override
  State<AIPredictionsScreen> createState() => _AIPredictionsScreenState();
}

class _AIPredictionsScreenState extends State<AIPredictionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final productVm = context.read<ProductViewModel>();
    final saleVm = context.read<SaleViewModel>();
    final predictionVm = context.read<PredictionViewModel>();

    await productVm.getAllProduct();
    await saleVm.getAllSales();

    final products = productVm.allProducts ?? [];
    final sales = saleVm.sales ?? [];

    if (products.isNotEmpty) {
      await predictionVm.generatePredictions(products, sales, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final predictionVm = context.watch<PredictionViewModel>();
    final productVm = context.watch<ProductViewModel>();
    final saleVm = context.watch<SaleViewModel>();

    final isLoading = predictionVm.loading || productVm.loading || saleVm.loading;
    final predictions = predictionVm.predictions ?? [];

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : predictions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_graph, size: 64, color: AppColor.secondary),
            const SizedBox(height: 16),
            Text(
              "No Predictions Yet",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add products and log sales to generate predictions",
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColor.secondary,
              ),
            ),
          ],
        ),
      )
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
                  return _buildPredictionCard(item, predictionVm);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(PredictionModel item, PredictionViewModel vm) {
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
                  item.productName,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.neutral,
                  ),
                ),
              ),
              _buildConfidenceBadge(item.confidenceLevel),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 16, color: AppColor.secondary),
              const SizedBox(width: 6),
              Text(
                "Predicted: ${item.predictedQuantity} units",
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
                      onTap: () => _showAdjustDialog(item, vm),
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
          if (item.confidenceLevel != "Insufficient")
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
          if (item.confidenceLevel == "Insufficient")
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

  void _showWhyDialog(PredictionModel item) {
    final explanation = item.explanationData;
    final weeklyAverages = explanation['weeklyAverages'] as Map<int, double>?;

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
              "Based on last 4 weeks of sales data",
              style: GoogleFonts.manrope(fontSize: 13, color: AppColor.secondary),
            ),
            const SizedBox(height: 16),
            if (weeklyAverages != null)
              ...weeklyAverages.entries.map((entry) {
                final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        days[entry.key - 1],
                        style: GoogleFonts.manrope(fontSize: 13),
                      ),
                      Text(
                        "${entry.value.toStringAsFixed(1)} units avg",
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            if (!explanation.containsKey('weeklyAverages'))
              Text(
                explanation['message'] ?? 'No data available',
                style: GoogleFonts.manrope(fontSize: 13, color: AppColor.secondary),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calculate, size: 18, color: AppColor.primary),
                  const SizedBox(width: 8),
                  Text(
                    "Method: ${explanation['method'] ?? 'Moving Average'}",
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

  void _showAdjustDialog(PredictionModel item, PredictionViewModel vm) {
    TextEditingController controller = TextEditingController(
      text: item.predictedQuantity.toString(),
    );

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
              "Change prediction for ${item.productName}",
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
              if (newValue < 0) newValue = 0;

              final success = await vm.updatePrediction(item.productId, newValue);
              if (success && mounted) {
                Navigator.pop(context);
                Fluttertoast.showToast(msg: "Prediction updated to $newValue units");
              } else if (mounted) {
                Navigator.pop(context);
                Fluttertoast.showToast(msg: "Failed to update prediction");
              }
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