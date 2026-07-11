import '../model/order_model.dart';
import '../model/product_model.dart';
import '../model/prediction_model.dart';

abstract class OrderRepo {
  // Generate order suggestions
  Future<OrderModel> generateSuggestedOrder(
      List<ProductModel> products,
      List<PredictionModel> predictions,
      );

  // Manage orders
  Future<List<OrderModel>> getAllOrders();
  Future<OrderModel?> getOrderById(String id);
  Future<void> saveOrder(OrderModel order);
  Future<void> markOrderPlaced(String id);
  Future<void> deleteOrder(String id);
  Future<void> completeAndRestockOrder(OrderModel order);

  // Export
  Future<String> exportOrderToCSV(OrderModel order);
  Future<String> generateOrderText(OrderModel order);
}