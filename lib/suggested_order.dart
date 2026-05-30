import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'utils/colors.dart';

class SuggestedOrderScreen extends StatefulWidget {
  const SuggestedOrderScreen({super.key});

  @override
  State<SuggestedOrderScreen> createState() => _SuggestedOrderScreenState();
}

class _SuggestedOrderScreenState extends State<SuggestedOrderScreen> {
  List<OrderItem> orderItems = [
    OrderItem(
      id: '1',
      name: 'Milk 1L',
      currentStock: 8,
      threshold: 15,
      aiPrediction: 12,
      suggestedQty: 19,
      unit: 'units',
    ),
    OrderItem(
      id: '2',
      name: 'Coke 500ml',
      currentStock: 2,
      threshold: 10,
      aiPrediction: 15,
      suggestedQty: 23,
      unit: 'bottles',
    ),
    OrderItem(
      id: '3',
      name: 'Wai Wai Noodles',
      currentStock: 5,
      threshold: 20,
      aiPrediction: 18,
      suggestedQty: 33,
      unit: 'packs',
    ),
    OrderItem(
      id: '4',
      name: 'Cooking Oil 1L',
      currentStock: 0,
      threshold: 8,
      aiPrediction: 10,
      suggestedQty: 18,
      unit: 'bottles',
    ),
    OrderItem(
      id: '5',
      name: 'Salt 1kg',
      currentStock: 15,
      threshold: 10,
      aiPrediction: 5,
      suggestedQty: 0,
      unit: 'packs',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    List<OrderItem> visibleItems = orderItems.where((item) => item.suggestedQty > 0).toList();

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "Suggested Order",
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
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getWeekRange(),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColor.secondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${visibleItems.length} items to order",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppColor.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: visibleItems.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: AppColor.primary),
                  const SizedBox(height: 16),
                  Text(
                    "All stocked up!",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColor.neutral,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No items need reordering this week",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColor.secondary,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                return _buildOrderCard(item, index);
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColor.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => _showExportOptions(visibleItems),
                icon: const Icon(Icons.share, color: Colors.white),
                label: Text(
                  "Export Order",
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderItem item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.currentStock < item.threshold
                        ? AppColor.primary.withOpacity(0.1)
                        : AppColor.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Stock: ${item.currentStock} ${item.unit}",
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: item.currentStock < item.threshold
                          ? AppColor.primary
                          : AppColor.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildStatChip("Threshold", "${item.threshold} ${item.unit}", AppColor.secondary),
                const SizedBox(width: 8),
                _buildStatChip("AI Prediction", "${item.aiPrediction} ${item.unit}", AppColor.tertiary),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Suggested Quantity:",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColor.neutral,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (item.suggestedQty > 0) {
                              item.suggestedQty--;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Icon(Icons.remove, size: 18, color: AppColor.secondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: TextEditingController(text: item.suggestedQty.toString()),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColor.primary,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppColor.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (value) {
                            int? newQty = int.tryParse(value);
                            if (newQty != null && newQty >= 0) {
                              setState(() {
                                item.suggestedQty = newQty;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            item.suggestedQty++;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColor.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Icon(Icons.add, size: 18, color: AppColor.secondary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (item.currentStock >= item.threshold && item.aiPrediction < item.currentStock)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppColor.success),
                    const SizedBox(width: 4),
                    Text(
                      "Stock sufficient. No need to order.",
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColor.success,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColor.secondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(List<OrderItem> items) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColor.background,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Export Order List",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColor.neutral,
                ),
              ),
              const SizedBox(height: 20),
              _buildExportOption(
                icon: FontAwesomeIcons.whatsapp,
                title: "Share via WhatsApp",
                color: const Color(0xFF25D366),
                onTap: () => _shareToWhatsApp(items),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                icon: Icons.file_copy,
                title: "Save as CSV",
                color: AppColor.primary,
                onTap: () => _saveAsCSV(items),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                icon: Icons.copy,
                title: "Copy to Clipboard",
                color: AppColor.secondary,
                onTap: () => _copyToClipboard(items),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.manrope(
                    color: AppColor.secondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColor.neutral,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekRange() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    return "Week of ${_formatDate(startOfWeek)} - ${_formatDate(endOfWeek)}";
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _generateOrderText(List<OrderItem> items) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("*SmartShelf Order List*");
    buffer.writeln(_getWeekRange());
    buffer.writeln("");
    for (var item in items) {
      buffer.writeln("${item.name}: ${item.suggestedQty} ${item.unit}");
    }
    buffer.writeln("");
    buffer.writeln("Generated by SmartShelf App");
    return buffer.toString();
  }

  void _shareToWhatsApp(List<OrderItem> items) async {
    String orderText = _generateOrderText(items);
    await Share.share(orderText);
    Fluttertoast.showToast(msg: "Order list ready to share");
  }

  void _saveAsCSV(List<OrderItem> items) async {
    List<List<String>> csvData = [
      ["Product Name", "Current Stock", "Threshold", "AI Prediction", "Suggested Quantity", "Unit"],
    ];

    for (var item in items) {
      csvData.add([
        item.name,
        item.currentStock.toString(),
        item.threshold.toString(),
        item.aiPrediction.toString(),
        item.suggestedQty.toString(),
        item.unit,
      ]);
    }

    String csv = const ListToCsvConverter().convert(csvData);
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/suggested_order.csv";
    File file = File(path);
    await file.writeAsString(csv);

    Fluttertoast.showToast(msg: "CSV saved");
    await Share.shareXFiles([XFile(path)], text: "SmartShelf Order List");
  }

  void _copyToClipboard(List<OrderItem> items) async {
    String orderText = _generateOrderText(items);
    await Share.share(orderText);
    Fluttertoast.showToast(msg: "Order list copied");
  }
}

class OrderItem {
  String id;
  String name;
  int currentStock;
  int threshold;
  int aiPrediction;
  int suggestedQty;
  String unit;

  OrderItem({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.threshold,
    required this.aiPrediction,
    required this.suggestedQty,
    required this.unit,
  });
}