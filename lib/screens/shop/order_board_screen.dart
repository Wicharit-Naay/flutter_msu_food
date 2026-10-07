import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/shop.dart';
import '../../models/food_order.dart';
import '../../services/auth_service.dart';
import '../../services/db.dart';

import 'order_history_screen.dart';
import 'shop_profile_screen.dart';
import 'menu_manage_screen.dart';

class OrderBoardScreen extends StatelessWidget {
  final User user;
  final String shopId;

  const OrderBoardScreen({
    super.key,
    required this.user,
    required this.shopId,
  });

  @override
  Widget build(BuildContext context) {
    final db = Db();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      // =========================================================
      // App Bar
      // =========================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF1D1D1F),
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ออร์เดอร์',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'จัดการรายการสั่งซื้อของร้าน',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8A8A8E),
              ),
            ),
          ],
        ),
        actions: [
          _AppBarAction(
            icon: Icons.history_rounded,
            tooltip: 'ประวัติออร์เดอร์',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderHistoryScreen(
                    shopId: shopId,
                  ),
                ),
              );
            },
          ),
          _AppBarAction(
            icon: Icons.restaurant_menu_rounded,
            tooltip: 'จัดการเมนู',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MenuManageScreen(
                    shopId: shopId,
                  ),
                ),
              );
            },
          ),
          _AppBarAction(
            icon: Icons.storefront_outlined,
            tooltip: 'โปรไฟล์ร้าน',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShopProfileScreen(
                    shopId: shopId,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: 12,
              left: 2,
            ),
            child: _AppBarAction(
              icon: Icons.logout_rounded,
              tooltip: 'ออกจากระบบ',
              iconColor: colorScheme.error,
              onPressed: () => AuthService().signOut(),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // =====================================================
          // Shop Status
          // =====================================================
          StreamBuilder<Shop>(
            stream: db.watchShop(shopId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const LinearProgressIndicator(
                  minHeight: 2,
                );
              }

              final shop = snap.data!;

              return _ShopStatusCard(
                shop: shop,
                onChanged: (value) {
                  db.setShopOpen(shopId, value);
                },
              );
            },
          ),

          // =====================================================
          // Orders
          // =====================================================
          Expanded(
            child: StreamBuilder<List<FoodOrder>>(
              stream: db.watchShopOrders(shopId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _ErrorState(
                    message: '${snap.error}',
                  );
                }

                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final orders = snap.data!;

                if (orders.isEmpty) {
                  return const _EmptyOrderState();
                }

                return Column(
                  children: [
                    _OrderSectionHeader(
                      orderCount: orders.length,
                    ),

                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          30,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          return _OrderCard(
                            order: orders[index],
                            db: db,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AppBar Action
// ============================================================================

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? iconColor;

  const _AppBarAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: 22,
        color: iconColor ?? const Color(0xFF48484A),
      ),
    );
  }
}

// ============================================================================
// Shop Status Card
// ============================================================================

class _ShopStatusCard extends StatelessWidget {
  final Shop shop;
  final ValueChanged<bool> onChanged;

  const _ShopStatusCard({
    required this.shop,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = shop.isOpen;

    final statusColor = isOpen
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        16,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withOpacity(0.18),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                isOpen
                    ? Icons.storefront_rounded
                    : Icons.storefront_outlined,
                color: statusColor,
                size: 26,
              ),
            ),

            const SizedBox(width: 14),

            // Shop information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isOpen
                              ? 'ร้านเปิดอยู่ • พร้อมรับออร์เดอร์'
                              : 'ร้านปิดอยู่ • ไม่รับออร์เดอร์',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Shop switch
            Switch.adaptive(
              value: isOpen,
              activeColor: statusColor,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Order Section Header
// ============================================================================

class _OrderSectionHeader extends StatelessWidget {
  final int orderCount;

  const _OrderSectionHeader({
    required this.orderCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        12,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'ออร์เดอร์เข้าใหม่',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2EB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$orderCount รายการ',
              style: const TextStyle(
                color: Color(0xFFFF6B35),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Order Card
// ============================================================================

class _OrderCard extends StatelessWidget {
  final FoodOrder order;
  final Db db;

  const _OrderCard({
    required this.order,
    required this.db,
  });

  Future<void> _onAction(BuildContext context) async {
    // Pending ใช้ Transaction เดิม
    // เพื่อป้องกันการรับออร์เดอร์ซ้ำ
    if (order.status == OrderStatus.pending) {
      final error = await db.acceptOrder(order.id);

      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      return;
    }

    // สถานะอื่นเลื่อนไปข้างหน้าตาม Logic เดิม
    await db.advanceStatus(
      order.id,
      order.status,
    );
  }

  Color _statusColor() {
    if (order.status == OrderStatus.pending) {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    final action = OrderStatus.actionLabel(order.status);
    final statusColor = _statusColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEAEAEC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===================================================
            // Customer
            // ===================================================
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF2EB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Color(0xFFFF6B35),
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ลูกค้า',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                _StatusBadge(
                  text: OrderStatus.labels[order.status] ?? '',
                  color: statusColor,
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ===================================================
            // Food items
            // ===================================================
            const Text(
              'รายการอาหาร',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 10),

            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${item.qty}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF48484A),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2C2C2E),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        '${item.subtotal} บาท',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===================================================
            // Note
            // ===================================================
            if (order.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFE5A3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.sticky_note_2_outlined,
                      size: 18,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.note,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: Color(0xFF7A5600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            const Divider(
              height: 1,
              color: Color(0xFFEEEEF0),
            ),

            const SizedBox(height: 16),

            // ===================================================
            // Total
            // ===================================================
            Row(
              children: [
                const Text(
                  'ยอดรวม',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const Spacer(),
                Text(
                  '${order.total}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'บาท',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF636366),
                  ),
                ),
              ],
            ),

            if (order.status == OrderStatus.pending ||
                action != null) ...[
              const SizedBox(height: 16),

              // =================================================
              // Actions
              // =================================================
              Row(
                children: [
                  if (order.status == OrderStatus.pending) ...[
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            db.cancelOrder(order.id);
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 19,
                          ),
                          label: const Text('ปฏิเสธ'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(
                              color: Color(0xFFFECACA),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  if (action != null)
                    Expanded(
                      flex: order.status == OrderStatus.pending ? 2 : 1,
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: () {
                            _onAction(context);
                          },
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 19,
                          ),
                          label: Text(
                            action,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Status Badge
// ============================================================================

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================================
// Empty State
// ============================================================================

class _EmptyOrderState extends StatelessWidget {
  const _EmptyOrderState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF2EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Color(0xFFFF6B35),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'ยังไม่มีออร์เดอร์',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'เมื่อมีลูกค้าสั่งอาหาร\nออร์เดอร์จะแสดงที่หน้านี้อัตโนมัติ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Error State
// ============================================================================

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ไม่สามารถโหลดออร์เดอร์ได้',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}