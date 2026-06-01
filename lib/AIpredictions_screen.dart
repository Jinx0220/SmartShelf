import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/colors.dart';

class AIPredictionsScreen extends StatefulWidget {
  const AIPredictionsScreen({super.key});

  @override
  State<AIPredictionsScreen> createState() => _AIPredictionsScreenState();
}

class _AIPredictionsScreenState extends State<AIPredictionsScreen> {
  List<Map<String, dynamic>> predictions = [
    {
      "name": "Milk 1L",
      "currentStock": 8,
      "prediction": 12,
      "confidence": "High",
      "history": [5, 7, 6, 8],
    },
    {
      "name": "Coke 500ml",
      "currentStock": 2,
      "prediction": 15,
      "confidence": "High",
      "history": [12, 14, 13, 15],
    },
    {
      "name": "Wai Wai Noodles",
      "currentStock": 5,
      "prediction": 18,
      "confidence": "Medium",
      "history": [15, 20, 16, 18],
    },
    {
      "name": "Cooking Oil 1L",
      "currentStock": 0,
      "prediction": 10,
      "confidence": "Low",
      "history": [8, 12, 9, 10],
    },
    {
      "name": "New Product X",
      "currentStock": 10,
      "prediction": 0,
      "confidence": "Insufficient",
      "history": [],
    },
  ];

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
      body: Column(
        children: [
          // Info header
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
          // Predictions list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: predictions.length,
              itemBuilder: (context, index) {
                final item = predictions[index];
                return _buildPredictionCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(Map<String, dynamic> item) {
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
          // Product name and confidence badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item["name"],
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.neutral,
                  ),
                ),
              ),
              _buildConfidenceBadge(item["confidence"]),
            ],
          ),
          const SizedBox(height: 14),

          // Current stock
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 16, color: AppColor.secondary),
              const SizedBox(width: 6),
              Text(
                "Current Stock: ${item["currentStock"]} units",
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  color: AppColor.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // AI Prediction Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColor.primary.withOpacity(0.08), AppColor.primary.withOpacity(0.02)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.primary.withOpacity(0.1)),
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
                      "${item["prediction"]} units",
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
                          color: AppColor.primary.withOpacity(0.1),
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

          // "Why?" button
          if (item["confidence"] != "Insufficient")
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
          if (item["confidence"] == "Insufficient")
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
        color = AppColor.error;
        text = "Low Confidence";
        break;
      default:
        color = AppColor.secondary;
        text = "Insufficient Data";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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

  void _showWhyDialog(Map<String, dynamic> item) {
    List<int> history = List<int>.from(item["history"]);
    String productName = item["name"];
    int prediction = item["prediction"];
    int average = history.isEmpty ? 0 : history.reduce((a, b) => a + b) ~/ history.length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Why $prediction units?",
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
              "Last 4 weeks of sales for $productName:",
              style: GoogleFonts.manrope(fontSize: 13, color: AppColor.secondary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: history.asMap().entries.map((entry) {
                return Column(
                  children: [
                    Text(
                      "Week ${entry.key + 1}",
                      style: GoogleFonts.manrope(fontSize: 11, color: AppColor.secondary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${entry.value} units",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ],
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

  void _showAdjustDialog(Map<String, dynamic> item) {
    TextEditingController controller = TextEditingController(text: item["prediction"].toString());

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
              "Change prediction for ${item["name"]}",
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
            onPressed: () {
              int newValue = int.tryParse(controller.text) ?? item["prediction"];
              setState(() {
                item["prediction"] = newValue;
              });
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