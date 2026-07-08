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

    // Update product stock
    final updatedProduct = ProductModel(
      id: product.id,
      name: product.name,
      price: product.price,
      stock: product.stock - quantity,
      threshold: product.threshold,
      category: product.category,
      oldPrice: product.oldPrice,
    );
    await productVm.updateProduct(updatedProduct);

    // Save sale
    final sale = SaleModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id ?? '',
      productName: product.name ?? 'Unknown Product',
      quantity: quantity,
      totalPrice: (product.price * quantity).toInt(),
      unitPrice: product.price.toInt(),
      timestamp: DateTime.now(),
    );
    await saleVm.addSale(sale);

    // CRITICAL FIX: Must check mounted before calling setState after an await
    if (!mounted) return;

    // Reset form
    setState(() {
      selectedProduct = null;
      this.quantity = 1;
      quantityController.text = '1';
    });

    // Show success
    _showSaleSuccessDialog(
      context,
      productName: product.name ?? 'Product',
      quantity: quantity,
      totalPrice: (product.price * quantity).toInt(),
    );
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
            Icon(Icons.check_circle, color: AppColor.success),
            const SizedBox(width: 8),
            Text(
              "Sale Completed",
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
                color: AppColor.success,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sold ${quantity}x $productName",
              style: GoogleFonts.manrope(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              "Total: NPR $totalPrice",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColor.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Stock has been updated",
              style: GoogleFonts.manrope(fontSize: 12, color: AppColor.secondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: GoogleFonts.manrope(color: AppColor.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productVm = context.watch<ProductViewModel>();
    final products = productVm.allProducts ?? [];
    final totalPrice = selectedProduct != null
        ? (selectedProduct!.price * quantity).toInt()
        : 0;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "Log Sale",
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
      body: productVm.loading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : products.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 64, color: AppColor.secondary),
            const SizedBox(height: 16),
            Text(
              "No Products Found",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please add products from the Products tab",
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppColor.secondary,
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Product",
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ProductModel>(
                  isExpanded: true,
                  hint: Text(
                    "Choose a product",
                    style: GoogleFonts.manrope(color: AppColor.secondary),
                  ),
                  value: selectedProduct,
                  items: products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(
                        "${product.name} - NPR ${product.price.toInt()} (Stock: ${product.stock})",
                        style: GoogleFonts.manrope(color: AppColor.neutral),
                      ),
                    );
                  }).toList(),
                  onChanged: (product) {
                    setState(() {
                      selectedProduct = product;
                      quantity = 1;
                      quantityController.text = '1';
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (selectedProduct != null) ...[
              Text(
                "Quantity",
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.neutral,
                ),
              ),
              const SizedBox(height: 10),
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
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColor.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        final qty = int.tryParse(value);
                        if (qty != null && qty > 0) {
                          setState(() => quantity = qty);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        quantity++;
                        quantityController.text = quantity.toString();
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
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColor.primary.withValues(alpha: 0.1), AppColor.primary.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Amount",
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.neutral,
                      ),
                    ),
                    Text(
                      "NPR $totalPrice",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColor.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              if (selectedProduct!.oldPrice != null &&
                  selectedProduct!.price != selectedProduct!.oldPrice)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColor.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColor.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Price changed from NPR ${selectedProduct!.oldPrice!.toInt()} to NPR ${selectedProduct!.price.toInt()}",
                          style: GoogleFonts.manrope(fontSize: 12, color: AppColor.warning),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _processSale(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    "Confirm Sale",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}