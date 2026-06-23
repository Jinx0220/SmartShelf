import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

class PriceChangeDialog extends StatelessWidget {
  final String productName;
  final int oldPrice;
  final int newPrice;
  final VoidCallback onConfirm;

  const PriceChangeDialog({
    super.key,
    required this.productName,
    required this.oldPrice,
    required this.newPrice,
    required this.onConfirm,
  });

  int get priceDifference => newPrice - oldPrice;
  int get percentageChange => ((newPrice - oldPrice) / oldPrice * 100).round();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.attach_money, color: AppColor.warning),
          const SizedBox(width: 8),
          Text(
            "Price Change Alert",
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600,
              color: AppColor.warning,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            productName,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColor.neutral,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriceRow("Old Price", "NPR $oldPrice"),
          _buildPriceRow("New Price", "NPR $newPrice"),
          const Divider(),
          _buildPriceRow(
            "Change",
            "${priceDifference >= 0 ? '+' : ''}$priceDifference (${percentageChange >= 0 ? '+' : ''}$percentageChange%)",
            priceDifference >= 0 ? AppColor.error : AppColor.success,
          ),
          const SizedBox(height: 12),
          Text(
            "Price change will apply to future sales only",
            style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
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
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            "Confirm Change",
            style: GoogleFonts.manrope(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(fontSize: 14, color: AppColor.secondary),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColor.neutral,
            ),
          ),
        ],
      ),
    );
  }
}