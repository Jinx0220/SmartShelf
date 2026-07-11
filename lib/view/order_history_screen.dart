import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/colors.dart';
import '../viewmodel/order_viewmodel.dart';
import '../model/order_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<OrderViewModel>().getAllOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderViewModel>();
    final orders = vm.orders ?? [];

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          "Order History",
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
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => vm.getAllOrders(),
          ),
        ],
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator(color: AppColor.primary))
          : RefreshIndicator(
        color: AppColor.primary,
        onRefresh: () => vm.getAllOrders(),
        child: orders.isEmpty
            ? ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: AppColor.secondary),
                  const SizedBox(height: 16),
                  Text(
                    "No Orders Yet",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColor.neutral,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Generate and save orders from the Suggested Order screen",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColor.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildDismissibleOrderCard(order, vm);
          },
        ),
      ),
    );
  }

  Widget _buildDismissibleOrderCard(OrderModel order, OrderViewModel vm) {
    final orderId = order.id ?? '';

    return Dismissible(
      key: Key(orderId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Delete Order Record", style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
            content: Text("Are you sure you want to permanently delete this order record?", style: GoogleFonts.manrope()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel", style: GoogleFonts.manrope(color: AppColor.secondary)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
                child: Text("Delete", style: GoogleFonts.manrope(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        if (orderId.isNotEmpty) {
          await vm.deleteOrder(orderId);
          Fluttertoast.showToast(msg: "Order history log deleted");
        }
      },
      child: _buildOrderCard(order),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    order.isPlaced ? Icons.check_circle : Icons.pending,
                    color: order.isPlaced ? AppColor.success : AppColor.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.isPlaced ? 'Placed' : 'Pending',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: order.isPlaced ? AppColor.success : AppColor.warning,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDate(order.generatedDate),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColor.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 14, color: AppColor.secondary),
              const SizedBox(width: 4),
              Text(
                '${order.totalItems} items (${order.totalQuantity} units)',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColor.neutral,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: order.items.take(5).map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.productName} x${item.finalQuantity}',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColor.secondary,
                  ),
                ),
              );
            }).toList(),
          ),
          if (order.items.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${order.items.length - 5} more items',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppColor.secondary,
                ),
              ),
            ),
          if (order.isPlaced && order.placedDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColor.secondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Placed on: ${_formatDateTime(order.placedDate!)}',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppColor.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 🟢 ADDED WORKFLOW ACTION BUTTON HERE:
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1, color: Colors.black12),
          ),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_business_rounded, size: 16, color: Colors.white),
              label: Text(
                "Mark Received & Restock",
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade500,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final orderVm = context.read<OrderViewModel>();
                final success = await orderVm.completeAndRestockOrder(order);

                if (success) {
                  Fluttertoast.showToast(msg: "Inventory restocked cleanly! 📈");
                } else {
                  Fluttertoast.showToast(msg: "Restock transaction failed.");
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $amPm';
  }
}