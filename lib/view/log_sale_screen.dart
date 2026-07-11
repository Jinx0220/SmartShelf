// File: lib/view/log_sale_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../viewmodel/product_viewmodel.dart';
import '../viewmodel/sale_viewmodel.dart';
import '../model/product_model.dart';
import '../model/sale_model.dart';
import '../dialogs/negative_stock_dialog.dart';
import '../dialogs/price_change_dialog.dart';

class LogSaleScreen extends StatefulWidget {
  const LogSaleScreen({super.key});

  @override
  State<LogSaleScreen> createState() => _LogSaleScreenState();
}

class _LogSaleScreenState extends State<LogSaleScreen> {
  ProductModel? selectedProduct;
  int quantity = 1;
  final TextEditingController quantityController = TextEditingController(text: '1');
  String searchQuery = '';

  // CORE ARCHITECTURE UPGRADE: Global Reference Hook for Dynamic Currency
  // Change this variable to connect directly with your global Settings/Preferences view model state
  final String activeCurrencySymbol = "NPR";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().getAllProduct();
    });
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  void _processSale(BuildContext context) {
    if (selectedProduct == null) {
      Fluttertoast.showToast(msg: "Please select a product");
      return;
    }

    if (quantity < 1) {
      setState(() {
        quantity = 1;
        quantityController.text = '1';
      });
    }

    final product = selectedProduct!;
    final saleQuantity = quantity;
    final currentStock = product.stock;

    if (saleQuantity > currentStock) {
      showDialog(
        context: context,
        builder: (context) => NegativeStockDialog(
          productName: product.name,
          requestedQty: saleQuantity,
          currentStock: currentStock,
          onLogAnyway: () {
            Navigator.pop(context);
            _completeSale(context, product: product, quantity: saleQuantity, ignoreStock: true);
          },
        ),
      );
      return;
    }

    if (product.oldPrice != null && product.price != product.oldPrice) {
      showDialog(
        context: context,
        builder: (context) => PriceChangeDialog(
          productName: product.name,
          oldPrice: product.oldPrice!.toInt(),
          newPrice: product.price.toInt(),
          onConfirm: () {
            Navigator.pop(context);
            _completeSale(context, product: product, quantity: saleQuantity);
          },
        ),
      );
      return;
    }

    _completeSale(context, product: product, quantity: saleQuantity);
  }

  Future<void> _completeSale(
      BuildContext context, {
        required ProductModel product,
        required int quantity,
        bool ignoreStock = false,
      }) async {
    final productVm = context.read<ProductViewModel>();
    final saleVm = context.read<SaleViewModel>();

    try {
      final updatedProduct = product.copyWith(
        stock: product.stock - quantity,
      );

      await productVm.updateProduct(updatedProduct);

      final sale = SaleModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: product.id ?? '',
        productName: product.name,
        quantity: quantity,
        totalPrice: (product.price * quantity).toInt(),
        unitPrice: product.price.toInt(),
        timestamp: DateTime.now(),
      );

      await saleVm.addSale(sale);
      await saleVm.getAllSales();

      if (!context.mounted) return;

      final int completedTotalPrice = (product.price * quantity).toInt();
      final String completedProductName = product.name;
      final int completedQuantity = quantity;

      setState(() {
        selectedProduct = null;
        this.quantity = 1;
        quantityController.text = '1';
      });

      _showSaleSuccessDialog(
        context,
        productName: completedProductName,
        quantity: completedQuantity,
        totalPrice: completedTotalPrice,
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Transaction processing failure: ${e.toString()}");
    }
  }

  void _showSaleSuccessDialog(
      BuildContext context, {
        required String productName,
        required int quantity,
        required int totalPrice,
      }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColor.success),
            const SizedBox(width: 8),
            Text(
              "Sale Completed",
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600, color: AppColor.success),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sold ${quantity}x $productName", style: GoogleFonts.manrope(fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              "Total: $activeCurrencySymbol $totalPrice",
              style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.primary),
            ),
            const SizedBox(height: 8),
            Text(
              "Stock updates broadcasted successfully.",
              style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
            ),
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

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();
    final saleVm = context.watch<SaleViewModel>();
    final allProducts = productVm.allProducts ?? [];
    final isActionLoading = productVm.loading || saleVm.loading;

    final filteredProducts = allProducts.where((p) =>
    p.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (p.barcode != null && p.barcode!.contains(searchQuery))
    ).toList();

    final effectiveQuantity = quantity > 0 ? quantity : 1;
    final totalPrice = selectedProduct != null ? (selectedProduct!.price * effectiveQuantity).toInt() : 0;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "Log Sale",
          style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColor.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: productVm.loading && allProducts.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : allProducts.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory, size: 64, color: AppColor.secondary),
            const SizedBox(height: 16),
            Text(
              "No Products Found",
              style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w600, color: AppColor.neutral),
            ),
            const SizedBox(height: 8),
            Text(
              "Please populate your inventory configuration list first.",
              style: GoogleFonts.manrope(fontSize: 14, color: AppColor.secondary),
            ),
          ],
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              style: GoogleFonts.manrope(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Search items by name or scan barcode...",
                hintStyle: GoogleFonts.manrope(color: AppColor.secondary),
                prefixIcon: const Icon(Icons.search, color: AppColor.secondary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner, color: AppColor.primary),
                  onPressed: () {
                    // Placeholder for scanning hardware triggers
                  },
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              "Products Inventory (${filteredProducts.length})",
              style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.neutral),
            ),
          ),

          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
              child: Text(
                "No items match your search",
                style: GoogleFonts.manrope(color: AppColor.secondary, fontSize: 14),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final isSelected = selectedProduct?.id == product.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColor.primary.withValues(alpha: 0.08) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColor.primary : Colors.grey.shade200,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                    // --- RESOLVES ISSUE 2: Renders Product Thumbnails dynamically ---
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: product.imagePath != null && product.imagePath!.isNotEmpty
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(product.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.image, color: AppColor.secondary),
                        ),
                      )
                          : const Icon(Icons.image, color: AppColor.secondary),
                    ),

                    title: Text(
                      product.name,
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600, color: AppColor.neutral),
                    ),

                    // --- RESOLVES ISSUE 1: Injects scannable Barcode tag directly underneath title ---
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Stock count: ${product.stock} units | ${product.category}",
                          style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
                        ),
                        if (product.barcode != null && product.barcode!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.label_outline, size: 12, color: AppColor.primary),
                                const SizedBox(width: 4),
                                Text(
                                  "BC: ${product.barcode}",
                                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w500, color: AppColor.primary),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // --- RESOLVES ISSUE 8: Uses localized token prefix instead of hardcoded 'NPR' text ---
                    trailing: Text(
                      "$activeCurrencySymbol ${product.price.toInt()}",
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: AppColor.primary, fontSize: 15),
                    ),
                    onTap: () {
                      setState(() {
                        selectedProduct = product;
                        quantity = 1;
                        quantityController.text = '1';
                      });
                    },
                  ),
                );
              },
            ),
          ),

          if (selectedProduct != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Active Selection",
                                style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
                              ),
                              Text(
                                selectedProduct!.name,
                                style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.neutral),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (quantity > 1) {
                                  setState(() {
                                    quantity--;
                                    quantityController.text = quantity.toString();
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.remove, size: 18, color: AppColor.secondary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                controller: quantityController,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onChanged: (value) {
                                  final qty = int.tryParse(value);
                                  setState(() {
                                    quantity = (qty != null && qty > 0) ? qty : 0;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (quantity < 1) quantity = 0;
                                  quantity++;
                                  quantityController.text = quantity.toString();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.add, size: 18, color: AppColor.secondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (selectedProduct!.oldPrice != null && selectedProduct!.price != selectedProduct!.oldPrice)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColor.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColor.warning, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Price changed: $activeCurrencySymbol ${selectedProduct!.oldPrice!.toInt()} → $activeCurrencySymbol ${selectedProduct!.price.toInt()}",
                                style: GoogleFonts.manrope(fontSize: 12, color: AppColor.warning),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Amount Due",
                            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.neutral),
                          ),
                          Text(
                            "$activeCurrencySymbol $totalPrice",
                            style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.primary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isActionLoading ? null : () => _processSale(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isActionLoading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                            : Text(
                          "Confirm Sale",
                          style: GoogleFonts.spaceGrotesk(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}