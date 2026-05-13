import '../../../../core/network/result.dart';
import '../entities/order.dart';

abstract class OrderRepository {
  Future<Result<List<Order>>> getAll();
  Future<Result<Order>> create({required String customerId, required List<OrderItem> items});
  Future<Result<void>> cancel(String publicId);
}
