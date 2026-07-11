// File: lib/view/transaction_history_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';
import '../viewmodel/sale_viewmodel.dart';
import '../model/sale_model.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  void _openDateRangePicker(BuildContext context, SaleViewModel saleVm) async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      currentDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColor.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColor.neutral,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      saleVm.setDateRangeFilter(pickedRange);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saleVm = context.watch<SaleViewModel>();
    final List<SaleModel> displaysList = saleVm.filteredSales;
    final bool isFilterActive = saleVm.selectedDateRange != null;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "Transaction Logs",
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: AppColor.neutral),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.neutral),
        actions: [
          if (isFilterActive)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: AppColor.error),
              tooltip: "Clear Filter Range",
              onPressed: () => saleVm.clearDateRangeFilter(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Controller Header Pane
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _openDateRangePicker(context, saleVm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isFilterActive ? AppColor.primary.withValues(alpha: 0.08) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isFilterActive ? AppColor.primary : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: isFilterActive ? AppColor.primary : AppColor.secondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isFilterActive
                                  ? "${_formatShortDate(saleVm.selectedDateRange!.start)} -${_formatShortDate(saleVm.selectedDateRange!.end)}"
                                  : "Filter by Date Range...",
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: isFilterActive ? FontWeight.bold : FontWeight.normal,
                                color: isFilterActive ? AppColor.primary : AppColor.secondary,
                              ),
                            ),
                          ),
                          if (isFilterActive)
                            const Icon(Icons.edit, size: 14, color: AppColor.primary)
                          else
                            const Icon(Icons.arrow_drop_down, color: AppColor.secondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selection Count Panel Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isFilterActive ? "Filtered Entries" : "All Sales Log History",
                  style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700, color: AppColor.secondary),
                ),
                Text(
                  "${displaysList.length} Records Found",
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.neutral),
                ),
              ],
            ),
          ),

          // Items Core Viewport Section
          Expanded(
            child: displaysList.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    "No sales records align with your query window.",
                    style: GoogleFonts.manrope(color: AppColor.secondary, fontSize: 13),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: displaysList.length,
              itemBuilder: (context, index) {
                final sale = displaysList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: AppColor.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sale.productName,
                              style: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: AppColor.neutral, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Qty: ${sale.quantity} ×${formatCurrency(sale.unitPrice)}",
                              style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCurrency(sale.totalPrice),
                            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: AppColor.neutral),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatShortDate(_parseTimestamp(sale.timestamp)),
                            style: GoogleFonts.manrope(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[dt.month - 1]} ${dt.day},${dt.year}";
  }

  DateTime _parseTimestamp(dynamic ts) {
    if (ts is DateTime) return ts;
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.parse(ts.toString());
  }
}