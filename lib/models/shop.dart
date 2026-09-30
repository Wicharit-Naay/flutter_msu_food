import 'package:cloud_firestore/cloud_firestore.dart';

class Shop {
  final String id;
  final String name;
  final String ownerId;
  final bool isOpen;
  Shop({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.isOpen,
  });
  factory Shop.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return Shop(
      id: d.id,
      name: m['name'] as String? ?? '',
      ownerId: m['ownerId'] as String? ?? '',
      // ?? false กันกรณีฟิลด์หายไป จะได้ไม่ทำำให้แอปพัง
      isOpen: m['isOpen'] as bool? ?? false,
    );
  }
}
