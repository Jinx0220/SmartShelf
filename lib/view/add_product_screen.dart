import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../viewmodel/product_viewmodel.dart';
import '../model/product_model.dart';

class AddProductScreen extends StatefulWidget {
  final String? productId;

  const AddProductScreen({super.key, this.productId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController thresholdController = TextEditingController();
  String selectedCategory = 'Grocery';
  File? _selectedImage;
  String? _imageUrl;

  final List<String> categories = ['Grocery', 'Dairy', 'Beverages', 'Snacks', 'Electronics', 'Clothing'];
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProduct();
      });
    }
  }

  Future<void> _loadProduct() async {
    final vm = context.read<ProductViewModel>();
    await vm.getProductById(widget.productId!);
    final product = vm.product;
    if (product != null) {
      nameController.text = product.name;
      priceController.text = product.price.toString();
      stockController.text = product.stock.toString();
      thresholdController.text = product.threshold.toString();
      selectedCategory = product.category;
      _imageUrl = product.imageUrl;
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _imageUrl = picked.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewModel>();
    final isEditing = widget.productId != null;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Product' : 'Add Product',
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
      body: _isLoading || vm.loading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Picker - US-08
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    image: _selectedImage != null
                        ? DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    )
                        : null,
                  ),
                  child: _selectedImage == null && _imageUrl == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 40, color: AppColor.secondary),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add photo',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColor.secondary,
                        ),
                      ),
                    ],
                  )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Name
            Text(
              'Product Name',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Enter product name',
                hintStyle: GoogleFonts.manrope(color: AppColor.secondary),
                filled: true,
                fillColor: Colors.grey.shade100,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColor.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Price
            Text(
              'Price (NPR)',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter price',
                hintStyle: GoogleFonts.manrope(color: AppColor.secondary),
                prefixIcon: Icon(Icons.attach_money, color: AppColor.secondary),
                filled: true,
                fillColor: Colors.grey.shade100,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColor.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Stock
            Text(
              'Current Stock',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter stock quantity',
                hintStyle: GoogleFonts.manrope(color: AppColor.secondary),
                filled: true,
                fillColor: Colors.grey.shade100,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColor.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Threshold
            Text(
              'Low Stock Threshold',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: thresholdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter threshold',
                hintStyle: GoogleFonts.manrope(color: AppColor.secondary),
                filled: true,
                fillColor: Colors.grey.shade100,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColor.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            Text(
              'Category',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColor.neutral,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedCategory,
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(
                        category,
                        style: GoogleFonts.manrope(color: AppColor.neutral),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _saveProduct(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  isEditing ? 'Update Product' : 'Add Product',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProduct(BuildContext context) async {
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text);
    final stock = int.tryParse(stockController.text);
    final threshold = int.tryParse(thresholdController.text);

    if (name.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter product name');
      return;
    }
    if (price == null || price <= 0) {
      Fluttertoast.showToast(msg: 'Please enter valid price');
      return;
    }
    if (stock == null || stock < 0) {
      Fluttertoast.showToast(msg: 'Please enter valid stock');
      return;
    }
    if (threshold == null || threshold < 0) {
      Fluttertoast.showToast(msg: 'Please enter valid threshold');
      return;
    }

    setState(() => _isLoading = true);

    final vm = context.read<ProductViewModel>();
    final isEditing = widget.productId != null;

    String? imageUrl = _imageUrl;
    if (_selectedImage != null) {
      imageUrl = _selectedImage!.path;
    }

    final product = ProductModel(
      id: isEditing ? widget.productId : DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      price: price,
      stock: stock,
      threshold: threshold,
      category: selectedCategory,
      imageUrl: imageUrl,
    );

    bool success;
    if (isEditing) {
      success = await vm.updateProduct(product);
    } else {
      success = await vm.addProduct(product);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      Fluttertoast.showToast(msg: isEditing ? 'Product updated' : 'Product added');
      Navigator.pop(context);
    } else if (mounted) {
      Fluttertoast.showToast(msg: vm.error ?? 'Failed to save product');
    }
  }
}