import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';
import '../utils/formatters.dart';

class EditSaleDialog extends StatefulWidget {
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
  State<EditSaleDialog> createState() => _EditSaleDialogState();
}

class _EditSaleDialogState extends State<EditSaleDialog> {
  late TextEditingController _quantityController;
  late int _newQuantity;

  @override
  void initState() {
    super.initState();
    _newQuantity = widget.currentQuantity;
    _quantityController = TextEditingController(text: _newQuantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      content: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.productName,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.neutral,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Original Quantity: ${widget.currentQuantity} units",
                style: GoogleFonts.manrope(fontSize: 13, color: AppColor.secondary),
              ),
              Text(
                "Original Total: ${formatCurrency(widget.currentTotalPrice)}",
                style: GoogleFonts.manrope(fontSize: 13, color: AppColor.secondary),
              ),
              const SizedBox(height: 16),
              Text(
                "New Quantity",
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.neutral),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_newQuantity > 1) {
                        setDialogState(() {
                          _newQuantity--;
                          _quantityController.text = _newQuantity.toString();
                        });
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
                      controller: _quantityController,
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
                          setDialogState(() {
                            _newQuantity = qty;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      setDialogState(() {
                        _newQuantity++;
                        _quantityController.text = _newQuantity.toString();
                      });
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
                  color: AppColor.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "New Total:",
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.neutral),
                    ),
                    Text(
                      formatCurrency(widget.unitPrice * _newQuantity),
                      style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.primary),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: GoogleFonts.manrope(color: AppColor.secondary)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onSave(_newQuantity);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text("Save Changes", style: GoogleFonts.manrope(color: Colors.white)),
        ),
      ],
    );
  }
}