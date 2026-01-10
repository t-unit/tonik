import 'package:defs_api/defs_api.dart';
import 'package:test/test.dart';

void main() {
  group(r'Order model (with $defs)', () {
    test('serializes to JSON', () {
      const order = Order(
        id: '550e8400-e29b-41d4-a716-446655440000',
        status: OrderStatus.pending,
        items: [
          LineItem(
            productId: 'prod-1',
            quantity: 2,
            unitPrice: Money(amount: 10.99, currency: 'USD'),
          ),
        ],
        totals: OrderTotals(
          subtotal: Money(amount: 21.98, currency: 'USD'),
          tax: Money(amount: 2.20, currency: 'USD'),
          total: Money(amount: 24.18, currency: 'USD'),
        ),
      );

      final json = order.toJson()! as Map<String, Object?>;
      expect(json['id'], '550e8400-e29b-41d4-a716-446655440000');
      expect(json['status'], 'pending');
      expect(json['items'], isA<List<Object?>>());
      final items = json['items']! as List<Object?>;
      final firstItem = items.first! as Map<String, Object?>;
      expect(firstItem['product_id'], 'prod-1');
      expect(firstItem['quantity'], 2);
      final unitPrice = firstItem['unit_price']! as Map<String, Object?>;
      expect(unitPrice['amount'], 10.99);
      expect(unitPrice['currency'], 'USD');
    });

    test('deserializes from JSON', () {
      final json = {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'status': 'confirmed',
        'items': [
          {
            'product_id': 'prod-abc',
            'quantity': 3,
            'unit_price': {'amount': 5.50, 'currency': 'EUR'},
          },
        ],
        'totals': {
          'subtotal': {'amount': 16.50, 'currency': 'EUR'},
          'tax': {'amount': 3.14, 'currency': 'EUR'},
          'total': {'amount': 19.64, 'currency': 'EUR'},
        },
      };

      final order = Order.fromJson(json);
      expect(order.id, '550e8400-e29b-41d4-a716-446655440000');
      expect(order.status, OrderStatus.confirmed);
      expect(order.items, hasLength(1));
      expect(order.items.first.productId, 'prod-abc');
      expect(order.items.first.quantity, 3);
      expect(order.items.first.unitPrice.amount, 5.50);
      expect(order.items.first.unitPrice.currency, 'EUR');
      expect(order.totals?.subtotal?.amount, 16.50);
    });
  });

  group(r'OrderStatus enum (from Order/$defs/OrderStatus)', () {
    test('has expected values', () {
      expect(OrderStatus.values, hasLength(5));
      expect(OrderStatus.pending.toJson(), 'pending');
      expect(OrderStatus.confirmed.toJson(), 'confirmed');
      expect(OrderStatus.shipped.toJson(), 'shipped');
      expect(OrderStatus.delivered.toJson(), 'delivered');
      expect(OrderStatus.cancelled.toJson(), 'cancelled');
    });

    test('fromJson parses correctly', () {
      expect(OrderStatus.fromJson('pending'), OrderStatus.pending);
      expect(OrderStatus.fromJson('confirmed'), OrderStatus.confirmed);
      expect(OrderStatus.fromJson('shipped'), OrderStatus.shipped);
      expect(OrderStatus.fromJson('delivered'), OrderStatus.delivered);
      expect(OrderStatus.fromJson('cancelled'), OrderStatus.cancelled);
    });
  });

  group(r'LineItem model (from Order/$defs/LineItem)', () {
    test('serializes to JSON', () {
      const lineItem = LineItem(
        productId: 'prod-xyz',
        quantity: 5,
        unitPrice: Money(amount: 99.99, currency: 'GBP'),
      );

      final json = lineItem.toJson()! as Map<String, Object?>;
      expect(json['product_id'], 'prod-xyz');
      expect(json['quantity'], 5);
      final unitPrice = json['unit_price']! as Map<String, Object?>;
      expect(unitPrice['amount'], 99.99);
      expect(unitPrice['currency'], 'GBP');
    });

    test('deserializes from JSON', () {
      final json = {
        'product_id': 'prod-123',
        'quantity': 10,
        'unit_price': {'amount': 25.00, 'currency': 'USD'},
      };

      final lineItem = LineItem.fromJson(json);
      expect(lineItem.productId, 'prod-123');
      expect(lineItem.quantity, 10);
      expect(lineItem.unitPrice.amount, 25.00);
      expect(lineItem.unitPrice.currency, 'USD');
    });
  });

  group(r'Money model (from Order/$defs/Money)', () {
    test('serializes to JSON', () {
      const money = Money(amount: 123.45, currency: 'JPY');

      final json = money.toJson()! as Map<String, Object?>;
      expect(json['amount'], 123.45);
      expect(json['currency'], 'JPY');
    });

    test('deserializes from JSON', () {
      final json = {'amount': 999.99, 'currency': 'CAD'};

      final money = Money.fromJson(json);
      expect(money.amount, 999.99);
      expect(money.currency, 'CAD');
    });
  });

  group(r'OrderTotals model (from Order/$defs/OrderTotals)', () {
    test('serializes to JSON', () {
      const totals = OrderTotals(
        subtotal: Money(amount: 100.00, currency: 'USD'),
        tax: Money(amount: 10.00, currency: 'USD'),
        total: Money(amount: 110.00, currency: 'USD'),
      );

      final json = totals.toJson()! as Map<String, Object?>;
      final subtotal = json['subtotal']! as Map<String, Object?>;
      final tax = json['tax']! as Map<String, Object?>;
      final total = json['total']! as Map<String, Object?>;
      expect(subtotal['amount'], 100.00);
      expect(tax['amount'], 10.00);
      expect(total['amount'], 110.00);
    });

    test('deserializes from JSON', () {
      final json = {
        'subtotal': {'amount': 50.00, 'currency': 'EUR'},
        'tax': {'amount': 9.50, 'currency': 'EUR'},
        'total': {'amount': 59.50, 'currency': 'EUR'},
      };

      final totals = OrderTotals.fromJson(json);
      expect(totals.subtotal?.amount, 50.00);
      expect(totals.tax?.amount, 9.50);
      expect(totals.total?.amount, 59.50);
    });
  });
}
