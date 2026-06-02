import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "Bulk Import Products",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColor.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColor.primary),
                      const SizedBox(width: 8),
                      Text(
                        "How to import products",
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColor.neutral,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "1. Download the CSV template\n"
                        "2. Fill in your product details in Excel/Google Sheets\n"
                        "3. Save as CSV file\n"
                        "4. Import the CSV file",
                    style: GoogleFonts.manrope(fontSize: 13, color: AppColor.secondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Download Template Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _downloadTemplate,
                icon: const Icon(Icons.download),
                label: Text(
                  "Download CSV Template",
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Import Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isImporting ? null : _importCSV,
                icon: _isImporting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_file),
                label: Text(
                  _isImporting ? "Importing..." : "Import CSV File",
                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Example Format
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CSV Format Example:",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColor.neutral,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      "name,category,price,stock,threshold\n"
                          "Basmati Rice,Grocery,300,10,5\n"
                          "Milk 1L,Dairy,90,15,10\n"
                          "Coke 500ml,Beverages,60,20,8\n"
                          "Wai Wai Noodles,Snacks,25,30,15",
                      style: GoogleFonts.manrope(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColor.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.note, size: 20, color: AppColor.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Note: Products with the same name will not be duplicated",
                      style: GoogleFonts.manrope(fontSize: 12, color: AppColor.warning),
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

  Future<void> _downloadTemplate() async {
    // Create CSV content
    String csvContent = "name,category,price,stock,threshold\n";
    csvContent += "Basmati Rice,Grocery,300,10,5\n";
    csvContent += "Milk 1L,Dairy,90,15,10\n";
    csvContent += "Coke 500ml,Beverages,60,20,8\n";
    csvContent += "Wai Wai Noodles,Snacks,25,30,15\n";
    csvContent += "Cooking Oil 1L,Grocery,180,5,8\n";
    csvContent += "Sugar 1kg,Grocery,85,25,5\n";

    // Save and share
    final directory = await getTemporaryDirectory();
    final path = "${directory.path}/product_template.csv";
    File file = File(path);
    await file.writeAsString(csvContent);

    await Share.shareXFiles([XFile(path)], text: "Product Import Template");
    Fluttertoast.showToast(msg: "Template saved and shared");
  }

  Future<void> _importCSV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null) return;

      setState(() => _isImporting = true);

      // Read CSV file
      String filePath = result.files.single.path!;
      String fileContent = await File(filePath).readAsString();

      // Parse CSV
      List<List<dynamic>> csvData = const CsvToListConverter().convert(fileContent);

      if (csvData.length < 2) {
        Fluttertoast.showToast(msg: "CSV file is empty");
        setState(() => _isImporting = false);
        return;
      }

      // Get headers
      List<String> headers = csvData[0].map((e) => e.toString().toLowerCase().trim()).toList();

      // Check required columns
      bool hasName = headers.contains('name');
      bool hasPrice = headers.contains('price');

      if (!hasName || !hasPrice) {
        Fluttertoast.showToast(msg: "CSV must have 'name' and 'price' columns");
        setState(() => _isImporting = false);
        return;
      }

      // Get column indexes
      int nameIndex = headers.indexOf('name');
      int priceIndex = headers.indexOf('price');
      int stockIndex = headers.contains('stock') ? headers.indexOf('stock') : -1;
      int thresholdIndex = headers.contains('threshold') ? headers.indexOf('threshold') : -1;
      int categoryIndex = headers.contains('category') ? headers.indexOf('category') : -1;

      // Parse products
      List<Product> newProducts = [];
      List<String> errors = [];

      for (int i = 1; i < csvData.length; i++) {
        try {
          String name = csvData[i][nameIndex].toString().trim();
          if (name.isEmpty) continue;

          int price = int.tryParse(csvData[i][priceIndex].toString()) ?? 0;
          if (price <= 0) {
            errors.add("Row $i: Invalid price for '$name'");
            continue;
          }

          int stock = stockIndex != -1 ? int.tryParse(csvData[i][stockIndex].toString()) ?? 0 : 0;
          int threshold = thresholdIndex != -1 ? int.tryParse(csvData[i][thresholdIndex].toString()) ?? 5 : 5;
          String category = categoryIndex != -1 ? csvData[i][categoryIndex].toString() : 'General';

          newProducts.add(Product(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            name: name,
            stock: stock < 0 ? 0 : stock,
            threshold: threshold < 1 ? 1 : threshold,
            price: price,
            category: category.isNotEmpty ? category : 'General',
            oldPrice: price,
          ));
        } catch (e) {
          errors.add("Row $i: Failed to parse");
        }
      }

      if (newProducts.isEmpty) {
        Fluttertoast.showToast(msg: "No valid products found in CSV");
        setState(() => _isImporting = false);
        return;
      }

      // Load existing products
      final prefs = await SharedPreferences.getInstance();
      final String? existingJson = prefs.getString('products');
      List<Product> existingProducts = [];

      if (existingJson != null && existingJson.isNotEmpty) {
        List<dynamic> decoded = json.decode(existingJson);
        existingProducts = decoded.map((e) => Product.fromJson(e)).toList();
      }

      // Merge products (avoid duplicates by name - case insensitive)
      int addedCount = 0;
      int duplicateCount = 0;

      for (var newProduct in newProducts) {
        bool exists = existingProducts.any((p) =>
        p.name.toLowerCase() == newProduct.name.toLowerCase()
        );
        if (!exists) {
          existingProducts.add(newProduct);
          addedCount++;
        } else {
          duplicateCount++;
        }
      }

      // Save back
      final String updatedJson = json.encode(existingProducts.map((e) => e.toJson()).toList());
      await prefs.setString('products', updatedJson);

      // Show result dialog
      _showImportResult(addedCount, duplicateCount, errors);

      setState(() => _isImporting = false);

    } catch (e) {
      Fluttertoast.showToast(msg: "Error importing: $e");
      setState(() => _isImporting = false);
    }
  }

  void _showImportResult(int added, int duplicates, List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(added > 0 ? Icons.check_circle : Icons.warning,
                color: added > 0 ? AppColor.success : AppColor.warning),
            const SizedBox(width: 8),
            Text(
              "Import Complete",
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
                color: AppColor.neutral,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$added products added successfully",
              style: GoogleFonts.manrope(fontSize: 14, color: AppColor.success),
            ),
            if (duplicates > 0)
              Text(
                "$duplicates duplicates skipped",
                style: GoogleFonts.manrope(fontSize: 14, color: AppColor.warning),
              ),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                "Errors (${errors.length}):",
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold, color: AppColor.error),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                width: double.maxFinite,
                child: ListView.builder(
                  itemCount: errors.length > 3 ? 3 : errors.length,
                  itemBuilder: (context, index) => Text(
                    "• ${errors[index]}",
                    style: GoogleFonts.manrope(fontSize: 11, color: AppColor.error),
                  ),
                ),
              ),
              if (errors.length > 3)
                Text(
                  "... and ${errors.length - 3} more",
                  style: GoogleFonts.manrope(fontSize: 11, color: AppColor.secondary),
                ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: GoogleFonts.manrope(color: AppColor.primary)),
          ),
        ],
      ),
    );
  }
}

// Product Model for this screen
class Product {
  final String id;
  final String name;
  final int stock;
  final int threshold;
  final int price;
  final String category;
  final int? oldPrice;

  Product({
    required this.id,
    required this.name,
    required this.stock,
    required this.threshold,
    required this.price,
    required this.category,
    this.oldPrice,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'stock': stock,
    'threshold': threshold,
    'price': price,
    'category': category,
    'oldPrice': oldPrice,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    stock: json['stock'] ?? 0,
    threshold: json['threshold'] ?? 0,
    price: json['price'] ?? 0,
    category: json['category'] ?? 'General',
    oldPrice: json['oldPrice'] ?? json['price'],
  );
}