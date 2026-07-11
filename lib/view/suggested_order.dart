import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../viewmodel/order_viewmodel.dart';
import '../viewmodel/product_viewmodel.dart';
import '../viewmodel/prediction_viewmodel.dart';
import '../model/order_model.dart';
import 'order_history_screen.dart';

class SuggestedOrderScreen extends StatefulWidget {
  const SuggestedOrderScreen({super.key});

  @override
  State<SuggestedOrderScreen> createState() => _SuggestedOrderScreenState();
}

class _SuggestedOrderScreenState extends State<SuggestedOrderScreen> {
  bool _isSyncingOrderPipeline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isSyncingOrderPipeline = true;
    });

    try {
      final orderVm = context.read<OrderViewModel>();
      final productVm = context.read<ProductViewModel>();
      final predictionVm = context.read<PredictionViewModel>();

      // Fetch structural arrays
      await productVm.getAllProduct();
      await predictionVm.getAllPredictions();
      await orderVm.getAllOrders();

      final products = productVm.allProducts ?? [];
      final predictions = predictionVm.predictions ?? [];

      // Generate calculation maps into currentOrder slot
      await orderVm.generateSuggestedOrder(products, predictions);
    } catch (e) {
      debugPrint("Error generating suggestions: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingOrderPipeline = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderVm = context.watch<OrderViewModel>();
    final isPageBusy = _isSyncingOrderPipeline || orderVm.loading;
    final currentOrder = orderVm.currentOrder;

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
            icon: const Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
            tooltip: 'Order History',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isPageBusy
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : currentOrder == null || currentOrder.items.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColor.success),
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
                    "${currentOrder.items.length} items to order",
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
              color: AppColor.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: currentOrder.items.length,
                itemBuilder: (context, index) {
                  final item = currentOrder.items[index];
                  return OrderItemCard(
                    item: item,
                    onChanged: () {
                      // Forces tracking layout metrics to update at base bar level
                      setState(() {});
                    },
                  );
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
                    icon: const Icon(Icons.save, color: Colors.white, size: 16),
                    label: Text(
                      "Save",
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!currentOrder.isPlaced)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _markOrderPlaced(orderVm),
                      icon: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                      label: Text(
                        "Place",
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.warning,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showExportOptions(currentOrder, orderVm),
                    icon: const Icon(Icons.share, color: Colors.white, size: 16),
                    label: Text(
                      "Export",
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

    if (success && mounted) {
      Fluttertoast.showToast(msg: "Order saved successfully ✅");
    } else if (mounted) {
      // Pull the exact error captured by the ViewModel
      final errorMessage = vm.error ?? "Unknown database error";

      // Show an alert dialog with the exact error message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Text("Database Error", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              errorMessage,
              style: GoogleFonts.manrope(fontSize: 14, color: Colors.black87),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _markOrderPlaced(OrderViewModel vm) async {
    if (vm.currentOrder == null || vm.currentOrder!.id == null) {
      Fluttertoast.showToast(msg: 'Please save order before marking placed');
      return;
    }

    final success = await vm.markOrderPlaced(vm.currentOrder!.id!);
    if (success && mounted) {
      setState(() {
        vm.currentOrder!.isPlaced = true;
        vm.currentOrder!.placedDate = DateTime.now();
      });
      Fluttertoast.showToast(msg: 'Order marked as placed! ✅');
    } else if (mounted) {
      Fluttertoast.showToast(msg: 'Failed to mark order as placed');
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
                icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
                title: "Share via WhatsApp",
                onTap: () => _shareToWhatsApp(order, vm),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                icon: const Icon(Icons.file_copy, color: AppColor.primary),
                title: "Save as CSV",
                onTap: () => _saveAsCSV(order, vm),
              ),
              const SizedBox(height: 12),
              _buildExportOption(
                icon: const Icon(Icons.copy, color: AppColor.secondary),
                title: "Copy to Clipboard",
                onTap: () => _copyToClipboard(order, vm),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.manrope(color: AppColor.secondary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportOption({
    required Widget icon,
    required String title,
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
            icon,
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
    final csvData = await vm.exportOrderToCSV(order);
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/order_${order.id ?? 'export'}.csv";
    final file = File(path);
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(path)], text: "SmartShelf Suggested Order Requirements");
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
    final csvData = await vm.exportOrderToCSV(order);
    await Clipboard.setData(ClipboardData(text: csvData));
    Fluttertoast.showToast(msg: "CSV structure copied to clipboard! 📋");
  }
}

/// Isolated Form Card Component to keep focus during input changes
class OrderItemCard extends StatefulWidget {
  final OrderItemModel item;
  final VoidCallback onChanged;

  const OrderItemCard({
    super.key,
    required this.item,
    required this.onChanged,
  });

  @override
  State<OrderItemCard> createState() => _OrderItemCardState();
}

class _OrderItemCardState extends State<OrderItemCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.finalQuantity.toString());
  }

  @override
  void didUpdateWidget(covariant OrderItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.finalQuantity != widget.item.finalQuantity &&
        _controller.text != widget.item.finalQuantity.toString()) {
      _controller.text = widget.item.finalQuantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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
                              _controller.text = item.finalQuantity.toString();
                            });
                            widget.onChanged();
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
                          controller: _controller,
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
                              item.finalQuantity = newQty;
                              widget.onChanged();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            item.finalQuantity++;
                            _controller.text = item.finalQuantity.toString();
                          });
                          widget.onChanged();
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
            style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
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
}