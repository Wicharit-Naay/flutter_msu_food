import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/food_order.dart';
import '../../services/db.dart';

enum _HistoryPeriod {
  day,
  week,
  month,
}

class OrderHistoryScreen extends StatefulWidget {
  final String shopId;

  const OrderHistoryScreen({
    super.key,
    required this.shopId,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _db = Db();

  _HistoryPeriod _period = _HistoryPeriod.day;

  // ==========================================================================
  // กำหนดช่วงเวลาประวัติ
  // ==========================================================================

  ({DateTime start, DateTime end}) _periodBounds() {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    switch (_period) {
      case _HistoryPeriod.day:
        return (
          start: today,
          end: today.add(
            const Duration(days: 1),
          ),
        );

      case _HistoryPeriod.week:
        final start = today.subtract(
          Duration(
            days: today.weekday - 1,
          ),
        );

        return (
          start: start,
          end: start.add(
            const Duration(days: 7),
          ),
        );

      case _HistoryPeriod.month:
        final start = DateTime(
          now.year,
          now.month,
        );

        return (
          start: start,
          end: DateTime(
            now.year,
            now.month + 1,
          ),
        );
    }
  }

  // ==========================================================================
  // แสดงช่วงวันที่ปัจจุบัน
  // ==========================================================================

  String _periodLabel() {
    final bounds = _periodBounds();

    switch (_period) {
      case _HistoryPeriod.day:
        return DateFormat(
          'dd/MM/yyyy',
        ).format(bounds.start);

      case _HistoryPeriod.week:
        final lastDay = bounds.end.subtract(
          const Duration(days: 1),
        );

        return '${DateFormat('dd/MM/yyyy').format(bounds.start)}'
            ' - '
            '${DateFormat('dd/MM/yyyy').format(lastDay)}';

      case _HistoryPeriod.month:
        return DateFormat(
          'MM/yyyy',
        ).format(bounds.start);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _periodBounds();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      // ======================================================================
      // App Bar
      // ======================================================================

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF1D1D1F),
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ประวัติออร์เดอร์',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'ตรวจสอบรายการขายย้อนหลัง',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ==================================================================
          // Period Selector
          // ==================================================================

          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
              16,
              10,
              16,
              18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SegmentedButton<_HistoryPeriod>(
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                      ),
                      backgroundColor:
                          WidgetStateProperty.resolveWith<Color?>(
                        (states) {
                          if (states.contains(
                            WidgetState.selected,
                          )) {
                            return Colors.white;
                          }

                          return Colors.transparent;
                        },
                      ),
                      foregroundColor:
                          WidgetStateProperty.resolveWith<Color?>(
                        (states) {
                          if (states.contains(
                            WidgetState.selected,
                          )) {
                            return const Color(0xFFFF6B35);
                          }

                          return const Color(0xFF6E6E73);
                        },
                      ),
                      side: WidgetStateProperty.all(
                        BorderSide.none,
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: _HistoryPeriod.day,
                        icon: Icon(
                          Icons.today_rounded,
                          size: 17,
                        ),
                        label: Text('รายวัน'),
                      ),
                      ButtonSegment(
                        value: _HistoryPeriod.week,
                        icon: Icon(
                          Icons.date_range_rounded,
                          size: 17,
                        ),
                        label: Text('รายสัปดาห์'),
                      ),
                      ButtonSegment(
                        value: _HistoryPeriod.month,
                        icon: Icon(
                          Icons.calendar_month_rounded,
                          size: 17,
                        ),
                        label: Text('รายเดือน'),
                      ),
                    ],
                    selected: {
                      _period,
                    },
                    onSelectionChanged: (selection) {
                      setState(
                        () {
                          _period = selection.first;
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: Color(0xFF8E8E93),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'ช่วงเวลา ${_periodLabel()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6E6E73),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ==================================================================
          // Order History
          // ==================================================================

          Expanded(
            child: StreamBuilder<List<FoodOrder>>(
              // ใช้ฐานข้อมูลเดิม
              stream: _db.watchShopOrderHistory(
                widget.shopId,
                start: bounds.start,
                end: bounds.end,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorState(
                    message: '${snapshot.error}',
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final orders = snapshot.data!;

                // คำนวณยอดรวมเดิม
                final total = orders.fold<num>(
                  0,
                  (runningTotal, order) =>
                      runningTotal + order.total,
                );

                return Column(
                  children: [
                    // ==========================================================
                    // Summary
                    // ==========================================================

                    _HistorySummary(
                      orderCount: orders.length,
                      total: total,
                    ),

                    // ==========================================================
                    // Order List
                    // ==========================================================

                    Expanded(
                      child: orders.isEmpty
                          ? const _EmptyHistoryState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                4,
                                16,
                                30,
                              ),
                              physics: const BouncingScrollPhysics(),
                              itemCount: orders.length,
                              itemBuilder: (context, index) {
                                return _HistoryOrderTile(
                                  order: orders[index],
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
// Summary
// ============================================================================

class _HistorySummary extends StatelessWidget {
  final int orderCount;
  final num total;

  const _HistorySummary({
    required this.orderCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        14,
      ),
      child: Row(
        children: [
          // ==================================================================
          // Order Count
          // ==================================================================

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFEAEAEC),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2EB),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFFFF6B35),
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$orderCount',
                          style: const TextStyle(
                            fontSize: 21,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ออร์เดอร์',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ==================================================================
          // Revenue
          // ==================================================================

          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF6B35),
                    Color(0xFFFF824F),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFFFF6B35,
                    ).withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.17),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${total.toStringAsFixed(0)} บาท',
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'ยอดรวม',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// History Order Card
// ============================================================================

class _HistoryOrderTile extends StatelessWidget {
  final FoodOrder order;

  const _HistoryOrderTile({
    required this.order,
  });

  Color _statusColor() {
    switch (order.status) {
      case OrderStatus.pending:
        return const Color(0xFFF59E0B);

      default:
        return const Color(0xFF16A34A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = order.createdAt;

    final timeLabel = createdAt == null
        ? 'ไม่ทราบเวลา'
        : DateFormat(
            'dd/MM/yyyy HH:mm',
          ).format(createdAt);

    final statusColor = _statusColor();

    return Container(
      margin: const EdgeInsets.only(
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xFFEAEAEC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================================
            // Customer + Status
            // =================================================================

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

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: Color(0xFF8E8E93),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              timeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                _StatusBadge(
                  text: OrderStatus.labels[order.status] ??
                      order.status,
                  color: statusColor,
                ),
              ],
            ),

            const SizedBox(height: 18),

            // =================================================================
            // Menu Header
            // =================================================================

            const Text(
              'รายการอาหาร',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
              ),
            ),

            const SizedBox(height: 10),

            // =================================================================
            // Menu Items
            // =================================================================

            ...order.items.map(
              (item) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 9,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.qty}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF48484A),
                          ),
                        ),
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2C2C2E),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        '${item.subtotal} บาท',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF636366),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // =================================================================
            // Note
            // =================================================================

            if (order.note.isNotEmpty) ...[
              const SizedBox(height: 4),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.sticky_note_2_outlined,
                      size: 17,
                      color: Color(0xFFF59E0B),
                    ),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        order.note,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: Color(0xFF7A5600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            const Divider(
              height: 1,
              color: Color(0xFFEEEEF0),
            ),

            const SizedBox(height: 14),

            // =================================================================
            // Total
            // =================================================================

            Row(
              children: [
                const Text(
                  'ยอดรวม',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8E8E93),
                  ),
                ),

                const Spacer(),

                Text(
                  '${order.total}',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D1D1F),
                  ),
                ),

                const SizedBox(width: 4),

                const Text(
                  'บาท',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF636366),
                  ),
                ),
              ],
            ),
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
          fontSize: 10,
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

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 105,
              height: 105,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF2EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 49,
                color: Color(0xFFFF6B35),
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'ไม่มีประวัติออร์เดอร์',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'ยังไม่มีออร์เดอร์ในช่วงเวลาที่เลือก\nลองเปลี่ยนช่วงเวลาเพื่อดูรายการย้อนหลัง',
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
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: Color(0xFFDC2626),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'ไม่สามารถโหลดประวัติได้',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }
}