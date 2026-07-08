import 'dart:io'; // Added for file interactions
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart'; // Added for path generation
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // Added for system document sharing
import '../utils/colors.dart';
import '../utils/formatters.dart';
import '../viewmodel/sale_viewmodel.dart';
import '../model/sale_model.dart';
import '../dialogs/confirmation_dialog.dart';
import '../dialogs/edit_sale_dialog.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleViewModel>().getAllSales();
    });
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
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

      await Share.shareXFiles(
        [XFile(path)],
        text: "SmartShelf Business Analytics - Complete Sales History Export",
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Export failed: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SaleViewModel>();
    final sales = vm.sales ?? [];

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
            icon: const Icon(Icons.file_download, color: Colors.white),
            tooltip: "Export Sales to CSV",
            onPressed: () => _exportSalesHistoryToCSV(sales),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => vm.getAllSales(),
          ),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : sales.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: AppColor.secondary),
            const SizedBox(height: 16),
            Text(
              "No Sales Yet",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Log your first sale from the Sale tab",
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
          itemCount: sales.length,
          itemBuilder: (context, index) {
            final sale = sales[index];
            return _buildSaleCard(context, sale, vm);
          },
        ),
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
              Icon(Icons.attach_money, size: 14, color: AppColor.secondary),
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
              Icon(Icons.calendar_today, size: 14, color: AppColor.secondary),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showEditDialog(context, sale, vm),
                icon: Icon(Icons.edit, size: 16, color: AppColor.primary),
                label: Text(
                  "Edit",
                  style: GoogleFonts.manrope(color: AppColor.primary),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _showDeleteConfirmation(context, sale, vm),
                icon: Icon(Icons.delete, size: 16, color: AppColor.error),
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
      builder: (context) => EditSaleDialog(
        productName: sale.productName,
        currentQuantity: sale.quantity,
        currentTotalPrice: sale.totalPrice,
        unitPrice: sale.unitPrice,
        onSave: (newQuantity) async {
          await vm.updateSale(sale.id, newQuantity);
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, SaleModel sale, SaleViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: "Delete Sale",
        message: "Are you sure you want to delete this sale? Stock will be restored.",
        confirmText: "Delete",
        confirmColor: AppColor.error,
        onConfirm: () => vm.deleteSale(sale.id),
      ),
    );
  }
}