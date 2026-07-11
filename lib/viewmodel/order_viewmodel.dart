//order_viewmodel
import 'package:flutter/material.dart';
import '../model/order_model.dart';
import '../model/prediction_model.dart';
import '../repo/order_repo.dart';

class OrderViewModel extends ChangeNotifier {
  final OrderRepo _orderRepo;

  OrderViewModel({required OrderRepo orderRepo}) : _orderRepo = orderRepo;

  bool _loading = false;
  String? _error;
  OrderModel? _currentOrder;
  List<OrderModel>? _orders = []; // Initialized to empty list instead of null to prevent blank screen states

  bool get loading => _loading;
  String? get error => _error;
  OrderModel? get currentOrder => _currentOrder;
  List<OrderModel>? get orders => _orders;

  void setLoading(bool value) {
    if (_loading != value) {
      _loading = value;
      notifyListeners();
    }
  }

  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> generateSuggestedOrder(List<dynamic> products, List<PredictionModel> predictions) async {
    _loading = true;
    notifyListeners();

    try {
      List<OrderItemModel> orderItems = [];
      Set<String> processedProductIds = {};
      Set<String> processedProductNames = {};

      final DateTime now = DateTime.now();
      final DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      for (var product in products) {
        String pId = '';
        String pName = 'Unknown Item';
        int pStock = 0;
        int pThreshold = 0;

        try {
          pId = product.id?.toString() ?? '';
          pName = product.name?.toString() ?? 'Unknown Item';
          pStock = (product.stock as num).toInt();
          pThreshold = (product.threshold as num).toInt();
        } catch (_) {
          if (product is Map) {
            pId = product['id']?.toString() ?? '';
            pName = product['name']?.toString() ?? 'Unknown Item';
            pStock = (product['stock'] as num?)?.toInt() ?? 0;
            pThreshold = (product['threshold'] as num?)?.toInt() ?? 0;
          }
        }

        if ((pId.isNotEmpty && processedProductIds.contains(pId)) || processedProductNames.contains(pName.toLowerCase())) {
          continue;
        }

        final prediction = predictions.firstWhere(
              (p) => (pId.isNotEmpty && p.productId == pId) || p.productName.toLowerCase() == pName.toLowerCase(),
          orElse: () => PredictionModel(
            productId: pId,
            productName: pName,
            predictedQuantity: 0,
            confidenceLevel: 'Insufficient',
            generatedDate: now,
            forWeekStarting: startOfWeek,
            explanationData: const {},
          ),
        );

        if (pStock < pThreshold) {
          int neededQty = pThreshold - pStock;
          if (prediction.predictedQuantity > neededQty) {
            neededQty = prediction.predictedQuantity;
          }

          if (neededQty > 0) {
            orderItems.add(OrderItemModel(
              productId: pId,
              productName: pName,
              currentStock: pStock,
              threshold: pThreshold,
              suggestedQuantity: neededQty,
              finalQuantity: neededQty,
            ));

            if (pId.isNotEmpty) processedProductIds.add(pId);
            processedProductNames.add(pName.toLowerCase());
          }
        }
      }

      _currentOrder = OrderModel(
        id: now.millisecondsSinceEpoch.toString(),
        generatedDate: now,
        items: orderItems,
        isPlaced: false,
      );
    } catch (e, stack) {
      debugPrint("🚨 Error creating unique sequence map: $e\n$stack");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveOrder(OrderModel order) async {
    setLoading(true);
    setError(null);
    try {
      await _orderRepo.saveOrder(order);
      // Force refresh data directly from source after a successful save
      _orders = await _orderRepo.getAllOrders();
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint("🚨 CRITICAL: saveOrder failed inside database transaction layer!");
      debugPrint("Error details: $e");
      debugPrint("Stacktrace: $stack");
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> getAllOrders() async {
    setLoading(true);
    setError(null);
    try {
      _orders = await _orderRepo.getAllOrders();
    } catch (e, stack) {
      debugPrint("🚨 Error getting order list: $e\n$stack");
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<bool> markOrderPlaced(String id) async {
    setLoading(true);
    setError(null);
    try {
      await _orderRepo.markOrderPlaced(id);
      _orders = await _orderRepo.getAllOrders();
      return true;
    } catch (e, stack) {
      debugPrint("🚨 Error marking order placed: $e\n$stack");
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<String> exportOrderToCSV(OrderModel order) async {
    setLoading(true);
    setError(null);
    try {
      return await _orderRepo.exportOrderToCSV(order);
    } catch (e, stack) {
      debugPrint("🚨 Error exporting to CSV: $e\n$stack");
      setError(e.toString());
      return '';
    } finally {
      setLoading(false);
    }
  }

  Future<bool> completeAndRestockOrder(OrderModel order) async {
    setLoading(true);
    setError(null);
    try {
      await _orderRepo.completeAndRestockOrder(order);
      // Refresh the local history array list right after updating database
      _orders = await _orderRepo.getAllOrders();
      notifyListeners();
      return true;
    } catch (e, stack) {
      debugPrint("🚨 Error running restock method: $e\n$stack");
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> deleteOrder(String id) async {
    setLoading(true);
    setError(null);
    try {
      await _orderRepo.deleteOrder(id);
      _orders = await _orderRepo.getAllOrders();
    } catch (e, stack) {
      debugPrint("🚨 Error deleting order record: $e\n$stack");
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
}