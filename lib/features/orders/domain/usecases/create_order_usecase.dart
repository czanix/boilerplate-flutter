import '../../../../core/network/result.dart';
import '../entities/order.dart';
import '../repositories/order_repository.dart';

class CreateOrderUseCase {
  final OrderRepository _repository;

  CreateOrderUseCase(this._repository);

  Future<Result<Order>> call({required String customerId, required List<OrderItem> items}) async {
    if (items.isEmpty) {
      return const Failure('Pedido deve ter pelo menos um item');
    }
    if (customerId.isEmpty) {
      return const Failure('Cliente obrigatório');
    }
    return _repository.create(customerId: customerId, items: items);
  }
}
