import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop.dart';
import '../models/menu_item.dart';
import '../models/food_order.dart';

class Db {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _shops =>
      _db.collection('shops');
  CollectionReference<Map<String, dynamic>> get _menu =>
      _db.collection('menuItems');
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection('orders');
  // ---------- โปรไฟล์และบทบาท ----------
  // เฝ้าฟังเอกสารผู้ใช้ ใช้ตัดสินว่าจะพาไปหน้าจอของบทบาทใด
  // นี่คือตัวอย่างการฟัง "เอกสารเดียว" ไม่ใช่ทั้งคอลเลกชัน
  Stream<Map<String, dynamic>?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((d) => d.exists ? d.data() : null);
  }

  // เลือกบทบาทลูกค้า
  Future<void> becomeCustomer(String uid, String name) async {
    await _users.doc(uid).set({
      'displayName': name,
      'role': 'customer',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // เลือกบทบาทร้านค้า พร้อมสร้างเอกสารร้านให้ในคราวเดียว
  // ใช้ batch เพื่อให้ทั้งสองเอกสารถูกเขียนสำำเร็จพร้อมกัน
  // ถ้าเขียนทีละคำำสั่งแล้วคำำสั่งที่สองล้มเหลว
  // จะได้ผู้ใช้ที่มีบทบาทร้านค้าแต่ไม่มีร้าน ซึ่งเป็นข้อมูลที่ผิด
  Future<void> becomeShop(String uid, String name, String shopName) async {
    final batch = _db.batch();
    final shopRef = _shops.doc(); // สร้างรหัสร้านล่วงหน้า
    batch.set(shopRef, {
      'name': shopName,
      'ownerId': uid,
      'isOpen': false,
      'orderCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_users.doc(uid), {
      'displayName': name,
      'role': 'shop',
      'shopId': shopRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit(); // เขียนทั้งสองเอกสารพร้อมกัน
  }

  // ---------- ร้านค้า ----------
  // เฝ้าฟังเอกสารร้านเดียว ทั้งสองฝั่งใช้เมธอดนี้ร่วมกัน
  // ร้านใช้ดูสถานะของตน ลูกค้าใช้ดูว่าร้านยังเปิดอยู่หรือไม่
  Stream<Shop> watchShop(String shopId) =>
      _shops.doc(shopId).snapshots().map(Shop.fromDoc);
  Stream<List<Map<String, dynamic>>> watchShopMembers(String shopId) => _shops
      .doc(shopId)
      .collection('members')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => {...doc.data(), 'memberId': doc.id})
            .toList(),
      );

  Future<void> ensureDefaultShopMembers(
    String shopId,
    List<Map<String, String>> defaultMembers,
  ) async {
    final shopRef = _shops.doc(shopId);
    final membersRef = shopRef.collection('members');
    await _db.runTransaction((transaction) async {
      final shopSnapshot = await transaction.get(shopRef);
      if (!shopSnapshot.exists) {
        throw StateError('ไม่พบข้อมูลร้าน');
      }
      if (shopSnapshot.data()?['membersInitialized'] == true) return;

      final memberSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final member in defaultMembers) {
        memberSnapshots.add(
          await transaction.get(membersRef.doc(member['studentId']!)),
        );
      }

      for (var index = 0; index < defaultMembers.length; index++) {
        if (memberSnapshots[index].exists) continue;
        final member = defaultMembers[index];
        transaction.set(membersRef.doc(member['studentId']!), {
          'name': member['name'],
          'studentId': member['studentId'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.update(shopRef, {'membersInitialized': true});
    });
  }

  Future<void> addShopMember(
    String shopId, {
    required String name,
    required String studentId,
  }) async {
    final memberRef = _shops.doc(shopId).collection('members').doc(studentId);
    await _db.runTransaction((transaction) async {
      final existingMember = await transaction.get(memberRef);
      if (existingMember.exists) {
        throw StateError('รหัสประจำตัวนี้มีอยู่ในรายชื่อแล้ว');
      }
      transaction.set(memberRef, {
        'name': name.trim(),
        'studentId': studentId.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteShopMember(String shopId, String studentId) async {
    await _shops.doc(shopId).collection('members').doc(studentId).delete();
  }

  // สลับสถานะเปิดปิดร้าน จุดสาธิตเรียลไทม์ข้อที่ 1
  Future<void> setShopOpen(String shopId, bool isOpen) async {
    await _shops.doc(shopId).update({
      'isOpen': isOpen,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // รายชื่อร้านทั้งหมด ลูกค้าเห็นทุกร้านแต่กดสั่งได้เฉพาะร้านที่เปิด
  Stream<List<Shop>> watchShops() => _shops
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Shop.fromDoc).toList());
  // ---------- เมนู (CRUD ครบ) ----------
  Stream<List<MenuItem>> watchMenu(String shopId) => _menu
      .where('shopId', isEqualTo: shopId)
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(MenuItem.fromDoc).toList());
  Future<void> addMenuItem(String shopId, String name, num price) async {
    await _menu.add({
      'shopId': shopId,
      'name': name.trim(),
      'price': price,
      'available': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMenuItem(String id, String name, num price) async {
    await _menu.doc(id).update({'name': name.trim(), 'price': price});
  }

  // สลับสถานะมีของหรือของหมด จุดสาธิตเรียลไทม์ข้อที่ 2
  Future<void> setAvailable(String id, bool value) async {
    await _menu.doc(id).update({'available': value});
  }

  Future<void> deleteMenuItem(String id) async {
    await _menu.doc(id).delete();
  }

  // ---------- ลูกค้าสั่งซื้อ ----------
  // ใช้ batch เพราะต้องเขียนสองเอกสารให้สำำเร็จพร้อมกัน
  // คือสร้างออร์เดอร์ใหม่ และเพิ่มตัวนับออร์เดอร์ของร้าน
  Future<String> placeOrder({
    required Shop shop,
    required String customerId,
    required String customerName,
    required List<OrderItem> items,
    required String note,
  }) async {
    final total = items.fold<num>(
      0,
      (runningTotal, item) => runningTotal + item.subtotal,
    );
    final batch = _db.batch();
    final orderRef = _orders.doc();
    batch.set(orderRef, {
      'shopId': shop.id,
      'shopName': shop.name, // เก็บซ้ำ้ำ ไว้ ไม่ต้องอ่านร้านอีก
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((e) => e.toMap()).toList(),
      'total': total,
      'status': OrderStatus.pending,
      'note': note.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // increment ปลอดภัยกว่าอ่านค่าเดิมมาบวกเอง
    // เพราะถ้าลูกค้าหลายคนสั่งพร้อมกัน ค่าจะไม่หายไป
    batch.update(_shops.doc(shop.id), {'orderCount': FieldValue.increment(1)});
    await batch.commit();
    return orderRef.id;
  }

  // ---------- การเฝ้าฟังออร์เดอร์ ----------
  // ฝั่งร้าน: ออร์เดอร์ที่ยังทำำงานอยู่ของร้านนี้
  // เรียงจากเก่าไปใหม่ เพราะออร์เดอร์ที่มาก่อนควรทำำก่อน
  Stream<List<FoodOrder>> watchShopOrders(String shopId) => _orders
      .where('shopId', isEqualTo: shopId)
      .where('status', whereIn: OrderStatus.active)
      .orderBy('createdAt')
      .snapshots()
      .map((s) => s.docs.map(FoodOrder.fromDoc).toList());

  Stream<List<FoodOrder>> watchShopOrderHistory(
    String shopId, {
    required DateTime start,
    required DateTime end,
  }) => _orders
      .where('shopId', isEqualTo: shopId)
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('createdAt', isLessThan: Timestamp.fromDate(end))
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(FoodOrder.fromDoc).toList());

  // ฝั่งลูกค้า: ออร์เดอร์ทั้งหมดของตนเอง ใหม่สุดอยู่บน
  Stream<List<FoodOrder>> watchMyOrders(String customerId) => _orders
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(FoodOrder.fromDoc).toList());
  // ฝั่งลูกค้า: ติดตามออร์เดอร์เดียวแบบละเอียด
  // นี่คือการฟังเอกสารเดียว ประหยัดกว่าฟังทั้งคอลเลกชันมาก
  Stream<FoodOrder> watchOrder(String orderId) =>
      _orders.doc(orderId).snapshots().map(FoodOrder.fromDoc);
  // ---------- การเปลี่ยนสถานะ ----------
  // ร้านกดรับออร์เดอร์ ใช้ธุรกรรมเพื่อกันการกดซ้ำ้ำ
  // สมมติว่าร้านเปิดแอปไว้สองเครื่องแล้วกดรับพร้อมกัน
  // ถ้าใช้ update() ธรรมดา คำำสั่งหลังจะเขียนทับโดยไม่รู้ตัว
  // แต่ธุรกรรมจะอ่านค่าล่าสุดก่อนเขียน และยกเลิกถ้าเงื่อนไขไม่ตรง
  Future<String?> acceptOrder(String orderId) async {
    try {
      await _db.runTransaction((tx) async {
        final ref = _orders.doc(orderId);
        final snap = await tx.get(ref);
        if (!snap.exists) {
          throw Exception('ไม่พบออร์เดอร์นี้');
        }
        if (snap.data()!['status'] != OrderStatus.pending) {
          throw Exception('ออร์เดอร์นี้ถูกจัดการไปแล้ว');
        }
        tx.update(ref, {
          'status': OrderStatus.accepted,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  // เลื่อนไปยังสถานะถัดไปตามลำำดับใน OrderStatus.flow
  Future<void> advanceStatus(String orderId, String current) async {
    final next = OrderStatus.next(current);
    if (next == null) return; // ไม่มีสถานะถัดไปแล้ว
    await _orders.doc(orderId).update({
      'status': next,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelOrder(String orderId) async {
    await _orders.doc(orderId).update({
      'status': OrderStatus.cancelled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
