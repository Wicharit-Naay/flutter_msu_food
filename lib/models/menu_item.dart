import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String shopId;
  final String name;
  final num price;
  final bool available;
  MenuItem({
    required this.id,
    required this.shopId,
    required this.name,
    required this.price,
    required this.available,
  });
  factory MenuItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return MenuItem(
      id: d.id,
      shopId: m['shopId'] as String? ?? '',
      name: m['name'] as String? ?? '',
      price: m['price'] as num? ?? 0,
      available: m['available'] as bool? ?? true,
    );
  }
}
