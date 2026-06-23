import 'package:flutter/material.dart';
import '../model/order_model.dart';
import '../model/product_model.dart';
import '../model/prediction_model.dart';
import '../repo/order_repo.dart';

class OrderViewModel extends ChangeNotifier {
  final OrderRepo _orderRepo;

  OrderViewModel({required OrderRepo orderRepo})
      : _orderRepo = orderRepo;

  bool _loading = false;
  String? _error;
  OrderModel? _currentOrder;
  List<OrderModel>? _orders;

  bool get loading => _loading;
  String? get error => _error;
  OrderModel? get currentOrder => _currentOrder;
  List<OrderModel>? get orders => _orders;

  setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  setError(String? value) {
    _error = value;
    notifyListeners();
  }

  setCurrentOrder(OrderModel? order) {
    _currentOrder = order;
    notifyListeners();
  }

  Future<bool> generateSuggestedOrder(
      List<ProductModel> products,
      List<PredictionModel> predictions,
      ) async {
    setLoading(true);
    setError(null);
    try {
      final order = await _orderRepo.generateSuggestedOrder(products, predictions);
      setCurrentOrder(order);
      return true;
    } on Exception catch (e) {
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
      notifyListeners();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<bool> saveOrder(OrderModel order) async {
    setLoading(true);
    setError(null);
    try {
      await _orderRepo.saveOrder(order);
      await getAllOrders();
      return true;
    } on Exception catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> markOrderPlaced(String id) async {
    setLoading(true);
    setError(null);
    try {
      await _orderRepo.markOrderPlaced(id);
      await getAllOrders();
      return true;
    } on Exception catch (e) {
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
    } on Exception catch (e) {
      setError(e.toString());
      return '';
    } finally {
      setLoading(false);
    }
  }

  Future<void> deleteOrder(String id) async {
    setLoading(true);
    setError(null);
    try {
      await _orderRepo.deleteOrder(id);
      await getAllOrders();
    } on Exception catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }
}