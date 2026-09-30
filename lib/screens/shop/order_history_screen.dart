import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/food_order.dart';
import '../../services/db.dart';

enum _HistoryPeriod { day, week, month }

class OrderHistoryScreen extends StatefulWidget {
  final String shopId;
  const OrderHistoryScreen({super.key, required this.shopId});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _db = Db();
  _HistoryPeriod _period = _HistoryPeriod.day;

  ({DateTime start, DateTime end}) _periodBounds() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case _HistoryPeriod.day:
        return (start: today, end: today.add(const Duration(days: 1)));
      case _HistoryPeriod.week:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return (start: start, end: start.add(const Duration(days: 7)));
      case _HistoryPeriod.month:
        final start = DateTime(now.year, now.month);
        return (start: start, end: DateTime(now.year, now.month + 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bounds = _periodBounds();
    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติออร์เดอร์')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_HistoryPeriod>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _HistoryPeriod.day,
                    label: Text('รายวัน'),
                  ),
                  ButtonSegment(
                    value: _HistoryPeriod.week,
                    label: Text('รายสัปดาห์'),
                  ),
                  ButtonSegment(
                    value: _HistoryPeriod.month,
                    label: Text('รายเดือน'),
                  ),
                ],
                selected: {_period},
                onSelectionChanged: (selection) {
                  setState(() => _period = selection.first);
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FoodOrder>>(
              stream: _db.watchShopOrderHistory(
                widget.shopId,
                start: bounds.start,
                end: bounds.end,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('ผิดพลาด: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!;
                final total = orders.fold<num>(
                  0,
                  (runningTotal, order) => runningTotal + order.total,
                );
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ออร์เดอร์ ${orders.length} รายการ'),
                          Text(
                            'รวม ${total.toStringAsFixed(0)} บาท',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: orders.isEmpty
                          ? const Center(
                              child: Text('ไม่มีออร์เดอร์ในช่วงเวลานี้'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: orders.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) =>
                                  _HistoryOrderTile(order: orders[index]),
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

class _HistoryOrderTile extends StatelessWidget {
  final FoodOrder order;
  const _HistoryOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final createdAt = order.createdAt;
    final timeLabel = createdAt == null
        ? 'ไม่ทราบเวลา'
        : DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
    final itemSummary = order.items
        .map((item) => '${item.name} x${item.qty}')
        .join(', ');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text(OrderStatus.labels[order.status] ?? order.status),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Text(timeLabel),
            if (itemSummary.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(itemSummary),
            ],
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'รวม ${order.total} บาท',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
