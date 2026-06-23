import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';

class EditSaleDialog extends StatelessWidget {
  final String productName;
  final int currentQuantity;
  final int currentTotalPrice;
  final int unitPrice;
  final Function(int newQuantity) onSave;

  const EditSaleDialog({
    super.key,
    required this.productName,
    required this.currentQuantity,
    required this.currentTotalPrice,
    required this.unitPrice,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController quantityController = TextEditingController(
      text: currentQuantity.toString(),
    );
    int newQuantity = currentQuantity;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Edit Sale",
        style: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColor.primary,
        ),
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
          Text(
            "Original Quantity: $currentQuantity units",
            style: GoogleFonts.manrope(fontSize: 13, color: AppColor.secondary),
          ),
          Text(
            "Original Total: ${formatCurrency(currentTotalPrice)}",
            style: GoogleFonts.manrope(fontSize: 13, color: AppColor.secondary),
          ),
          const SizedBox(height: 16),
          Text(
            "New Quantity",
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColor.neutral,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (newQuantity > 1) {
                    newQuantity--;
                    quantityController.text = newQuantity.toString();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.remove, size: 20, color: AppColor.secondary),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: quantityController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    final qty = int.tryParse(value);
                    if (qty != null && qty > 0) {
                      newQuantity = qty;
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  newQuantity++;
                  quantityController.text = newQuantity.toString();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, size: 20, color: AppColor.secondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColor.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "New Total:",
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColor.neutral,
                  ),
                ),
                Text(
                  formatCurrency(unitPrice * newQuantity),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary,
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
            "Cancel",
            style: GoogleFonts.manrope(color: AppColor.secondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onSave(newQuantity);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            "Save Changes",
            style: GoogleFonts.manrope(color: Colors.white),
          ),
        ),
      ],
    );
  }
}