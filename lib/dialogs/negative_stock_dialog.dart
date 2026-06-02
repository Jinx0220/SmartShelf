import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

class NegativeStockDialog extends StatelessWidget {
  final String productName;
  final int requestedQty;
  final int currentStock;
  final VoidCallback onLogAnyway;

  const NegativeStockDialog({
    super.key,
    required this.productName,
    required this.requestedQty,
    required this.currentStock,
    required this.onLogAnyway,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColor.error),
          const SizedBox(width: 8),
          Text(
            "Cannot Complete Sale",
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w600,
              color: AppColor.error,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "You are trying to sell $requestedQty units of '$productName' but only $currentStock units are in stock.",
            style: GoogleFonts.manrope(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Text(
            "This would make stock negative (-${requestedQty - currentStock} units)",
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColor.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Negative stock will cause incorrect inventory records.",
            style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel Sale",
            style: GoogleFonts.manrope(color: AppColor.secondary),
          ),
        ),
        ElevatedButton(
          onPressed: onLogAnyway,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.error,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            "Log Anyway",
            style: GoogleFonts.manrope(color: Colors.white),
          ),
        ),
      ],
    );
  }
}