// File: lib/view/sales_history_screen.dart
// ignore_for_file: spell_check_ignore_names
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';
import '../viewmodel/sale_viewmodel.dart';
import '../model/sale_model.dart';
import '../viewmodel/product_viewmodel.dart';
import '../model/product_model.dart';
import '../dialogs/confirmation_dialog.dart';
import '../dialogs/edit_sale_dialog.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleViewModel>().getAllSales();
      context.read<ProductViewModel>().getAllProduct();
    });
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)), // Allows filtering up to tomorrow
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColor.primary,
              onPrimary: Colors.white,
              onSurface: AppColor.neutral,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      Fluttertoast.showToast(msg: "Filtered logs by custom range");
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateRange = null;
    });
  }

  Future<void> _exportSalesHistoryToCSV(List<SaleModel> salesList) async {
    if (salesList.isEmpty) {
      Fluttertoast.showToast(msg: "No sales records available to export!");
      return;
    }

    StringBuffer csvBuilder = StringBuffer();
    csvBuilder.writeln("Sale ID,Product Name,Quantity,Unit Price,Total Price,Timestamp");

    for (var sale in salesList) {
      csvBuilder.writeln(
          "${sale.id},${sale.productName},${sale.quantity},${sale.unitPrice},${sale.totalPrice},${sale.timestamp.toIso8601String()}"
      );
    }

    try {
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/sales_history_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);

      await file.writeAsString(csvBuilder.toString());

      // CORRECT WAY to share a file using the share_plus package:
      await Share.shareXFiles(
        [XFile(path)],
        subject: "SmartShelf Business Analytics - Complete Sales History Export",
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Export failed: ${e.toString()}");
    }
  }

  Future<void> _handleDeleteAndRestock(BuildContext context, SaleModel sale, SaleViewModel saleVm) async {
    final productVm = context.read<ProductViewModel>();
    final ProductModel? restoredProduct = await saleVm.deleteSale(sale.id);

    if (!context.mounted) return;

    if (restoredProduct != null) {
      productVm.syncProductStockInMemory(restoredProduct);
      Fluttertoast.showToast(
        msg: "Sale removed. ${sale.quantity}x ${sale.productName} returned to stock!",
        backgroundColor: AppColor.success,
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: saleVm.error ?? "Failed to erase historical sale entry",
        backgroundColor: AppColor.error,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _handleEditSaleStock(
      BuildContext context,
      SaleModel sale,
      int newQuantity,
      SaleViewModel saleVm
      ) async {
    final productVm = context.read<ProductViewModel>();

    final targetProduct = productVm.allProducts?.firstWhere(
          (p) => p.id == sale.productId,
      orElse: () => ProductModel(
        id: sale.productId,
        name: sale.productName,
        price: sale.unitPrice.toDouble(),
        stock: 0,
        threshold: 0,
        category: '',
      ),
    );

    if (targetProduct != null && targetProduct.category.isNotEmpty) {
      final int quantityDelta = sale.quantity - newQuantity;
      final int updatedStock = targetProduct.stock + quantityDelta;

      if (updatedStock < 0) {
        Fluttertoast.showToast(
          msg: "Insufficient Stock! Only ${targetProduct.stock} items left on shelves.",
          backgroundColor: AppColor.error,
          textColor: Colors.white,
        );
        return;
      }

      final updatedProduct = targetProduct.copyWith(stock: updatedStock);
      await productVm.updateProduct(updatedProduct);
    }

    await saleVm.updateSale(sale.id, newQuantity);

    Fluttertoast.showToast(
      msg: "Sale updated. Inventory stock adjusted seamlessly!",
      backgroundColor: AppColor.success,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SaleViewModel>();
    final allSales = vm.sales ?? [];

    final filteredSales = allSales.where((sale) {
      if (_selectedDateRange == null) return true;
      final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
      final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
      return sale.timestamp.isAfter(start) && sale.timestamp.isBefore(end);
    }).toList();

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "Sales History",
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
            // FIXED: Swapped out legacy/hallucinated icon name for valid standard properties
            icon: Icon(
              _selectedDateRange == null ? Icons.date_range : Icons.date_range_outlined,
              color: Colors.white,
            ),
            tooltip: "Filter by Date Range",
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: "Export Sales to CSV",
            onPressed: () => _exportSalesHistoryToCSV(filteredSales),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => vm.getAllSales(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedDateRange != null)
            Container(
              color: AppColor.primary.withValues(alpha: 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.filter_alt, size: 16, color: AppColor.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Filtering: ${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} to ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}",
                      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppColor.primary),
                    ),
                  ),
                  GestureDetector(
                    onTap: _clearDateFilter,
                    child: const Icon(Icons.cancel, size: 18, color: AppColor.error),
                  ),
                ],
              ),
            ),

          _buildFinancialMetricsHeader(context, filteredSales),

          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
                : filteredSales.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: AppColor.secondary),
                  const SizedBox(height: 16),
                  Text(
                    _selectedDateRange == null ? "No Sales Yet" : "No Sales Found",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColor.neutral,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedDateRange == null
                        ? "Log your first sale from the Sale tab"
                        : "Try selecting a broader date search frame",
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColor.secondary,
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: () => vm.getAllSales(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredSales.length,
                itemBuilder: (context, index) {
                  final sale = filteredSales[index];
                  return _buildSaleCard(context, sale, vm);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetricsHeader(BuildContext context, List<SaleModel> displays) {
    final int localizedRevenue = displays.fold(0, (sum, item) => sum + item.totalPrice);
    final int localizedItemsSold = displays.fold(0, (sum, item) => sum + item.quantity);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColor.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColor.success.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // FIXED: Removed the stray duplicate broken line here
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_outlined, size: 16, color: AppColor.success),
                      const SizedBox(width: 6),
                      Text(
                        "Total Revenue",
                        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColor.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatCurrency(localizedRevenue),
                    style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: AppColor.neutral),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColor.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 16, color: AppColor.primary),
                      const SizedBox(width: 6),
                      Text(
                        "Items Sold",
                        style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AppColor.secondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$localizedItemsSold Pcs",
                    style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: AppColor.neutral),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, SaleModel sale, SaleViewModel vm) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  sale.productName,
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
                  color: AppColor.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${sale.quantity} units",
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.attach_money, size: 14, color: AppColor.success),
              const SizedBox(width: 4),
              Text(
                formatCurrency(sale.totalPrice),
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColor.success,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today, size: 14, color: AppColor.secondary),
              const SizedBox(width: 4),
              Text(
                _formatDate(sale.timestamp),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColor.secondary,
                ),
              ),
            ],
          ),
          if (sale.notes != null && sale.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Note: ${sale.notes}",
              style: GoogleFonts.manrope(fontSize: 11, fontStyle: FontStyle.italic, color: AppColor.secondary),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showEditDialog(context, sale, vm),
                icon: const Icon(Icons.edit, size: 16, color: AppColor.primary),
                label: Text(
                  "Edit",
                  style: GoogleFonts.manrope(color: AppColor.primary),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showDeleteConfirmation(context, sale, vm),
                icon: const Icon(Icons.delete, size: 16, color: AppColor.error),
                label: Text(
                  "Delete",
                  style: GoogleFonts.manrope(color: AppColor.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, SaleModel sale, SaleViewModel vm) {
    showDialog(
      context: context,
      builder: (dialogContext) => EditSaleDialog(
        productName: sale.productName,
        currentQuantity: sale.quantity,
        currentTotalPrice: sale.totalPrice,
        unitPrice: sale.unitPrice,
        onSave: (newQuantity) async {
          await _handleEditSaleStock(context, sale, newQuantity, vm);
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, SaleModel sale, SaleViewModel vm) {
    showDialog(
      context: context,
      builder: (dialogContext) => ConfirmationDialog(
        title: "Delete Sale",
        message: "Are you sure you want to delete this sale? Stock will be restored.",
        confirmText: "Delete",
        confirmColor: AppColor.error,
        onConfirm: () => _handleDeleteAndRestock(context, sale, vm),
      ),
    );
  }
}