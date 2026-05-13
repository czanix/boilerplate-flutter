class OrderItem {
  final String productId;
  final int quantity;
  final double unitPrice;

  const OrderItem({required this.productId, required this.quantity, required this.unitPrice});

  double get subtotal => quantity * unitPrice;
}

class Order {
  final String publicId;
  final String customerId;
  final List<OrderItem> items;
  final String status;
  final DateTime createdAt;

  const Order({
    required this.publicId,
    required this.customerId,
    required this.items,
    required this.status,
    required this.createdAt,
  });

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
}
