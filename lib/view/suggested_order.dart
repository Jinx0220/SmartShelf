import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../viewmodel/order_viewmodel.dart';
import '../viewmodel/prediction_viewmodel.dart';

class SuggestedOrderScreen extends StatefulWidget {
  const SuggestedOrderScreen({super.key});

  @override
  State<SuggestedOrderScreen> createState() => _SuggestedOrderScreenState();
}

class _SuggestedOrderScreenState extends State<SuggestedOrderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final orderVm = context.read<OrderViewModel>();
    final predictionVm = context.read<PredictionViewModel>();

    // This will be implemented when other ViewModels are ready
    // For now, show loading state
  }

  @override
  Widget build(BuildContext context) {
    final orderVm = context.watch<OrderViewModel>();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: orderVm.loading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : orderVm.currentOrder == null || orderVm.currentOrder!.items.isEmpty
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
          : Column(
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
                    color: AppColor.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${orderVm.currentOrder!.items.length} items to order",
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
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orderVm.currentOrder!.items.length,
                itemBuilder: (context, index) {
                  final item = orderVm.currentOrder!.items[index];
                  return _buildOrderCard(item, index, orderVm);
                },
              ),
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
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _saveOrder(orderVm),
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      "Save Order",
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showExportOptions(orderVm.currentOrder!, orderVm),
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: Text(
                      "Export",
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderItemModel item, int index, OrderViewModel vm) {
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
                    item.productName,
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
                        ? AppColor.primary.withValues(alpha: 0.1)
                        : AppColor.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Stock: ${item.currentStock} units",
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
                _buildStatChip("Threshold", "${item.threshold} units", AppColor.secondary),
                const SizedBox(width: 8),
                _buildStatChip("Prediction", "${item.suggestedQuantity} units", AppColor.tertiary),
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
                          if (item.finalQuantity > 0) {
                            setState(() {
                              item.finalQuantity--;
                            });
                          }
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
                          controller: TextEditingController(
                            text: item.finalQuantity.toString(),
                          ),
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
                                item.finalQuantity = newQty;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            item.finalQuantity++;
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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

  String _getWeekRange() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));
    return "Week of ${_formatDate(startOfWeek)} - ${_formatDate(endOfWeek)}";
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _saveOrder(OrderViewModel vm) async {
    if (vm.currentOrder == null) return;

    final success = await vm.saveOrder(vm.currentOrder!);
    if (success && context.mounted) {
      Fluttertoast.showToast(msg: "Order saved successfully");
    } else if (context.mounted) {
      Fluttertoast.showToast(msg: "Failed to save order");
    }
  }

  void _showExportOptions(OrderModel order, OrderViewModel vm) {
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
                onTap: () => _shareToWhatsApp(order, vm),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                icon: Icons.file_copy,
                title: "Save as CSV",
                color: AppColor.primary,
                onTap: () => _saveAsCSV(order, vm),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                icon: Icons.copy,
                title: "Copy to Clipboard",
                color: AppColor.secondary,
                onTap: () => _copyToClipboard(order, vm),
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

  Future<void> _shareToWhatsApp(OrderModel order, OrderViewModel vm) async {
    final text = await vm.exportOrderToCSV(order);
    await Share.share(text);
    Fluttertoast.showToast(msg: "Order list ready to share");
  }

  Future<void> _saveAsCSV(OrderModel order, OrderViewModel vm) async {
    final csv = await vm.exportOrderToCSV(order);
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/suggested_order.csv";
    File file = File(path);
    await file.writeAsString(csv);
    Fluttertoast.showToast(msg: "CSV saved");
    await Share.shareXFiles([XFile(path)], text: "SmartShelf Order List");
  }

  Future<void> _copyToClipboard(OrderModel order, OrderViewModel vm) async {
    final text = await vm.exportOrderToCSV(order);
    await Share.share(text);
    Fluttertoast.showToast(msg: "Order list copied");
  }
}