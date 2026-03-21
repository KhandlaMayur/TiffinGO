import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerOrdersScreen extends StatefulWidget {
  final String serviceId;
  final String serviceName;

  const SellerOrdersScreen({
    super.key,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const navy = Color(0xFF001F54);
  static const accent = Color(0xFF1E3A8A);

  String _ordersFilter = 'Total Orders'; // Total Orders, Revenue, Subscribed, Non-Subscribed, COD Orders, Online Orders
  String _subsFilter = 'Total Subs'; // Total Subs, Sub Revenue, Active, Expired

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ──────────────────── QUERIES ────────────────────

  /// Orders whose serviceId matches this seller
  Stream<QuerySnapshot> _ordersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('serviceId', isEqualTo: widget.serviceId)
        .snapshots();
  }

  /// Also query orders by serviceName (older orders may lack serviceId)
  Stream<QuerySnapshot> _ordersByNameStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('serviceName', isEqualTo: widget.serviceName)
        .snapshots();
  }

  /// Subscriptions for this service
  Stream<QuerySnapshot> _subscriptionsStream() {
    return FirebaseFirestore.instance
        .collection('subscriptions')
        .where('tiffineService', isEqualTo: widget.serviceId)
        .snapshots();
  }

  Stream<QuerySnapshot> _subscriptionsByNameStream() {
    return FirebaseFirestore.instance
        .collection('subscriptions')
        .where('tiffineService', isEqualTo: widget.serviceName)
        .snapshots();
  }

  // ──────────────────── BUILD ────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${widget.serviceName} – Dashboard'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long), text: 'Orders'),
            Tab(icon: Icon(Icons.card_membership), text: 'Subscriptions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersTab(),
          _buildSubscriptionsTab(),
        ],
      ),
    );
  }

  // ──────────────────── ORDERS TAB ────────────────────

  Widget _buildOrdersTab() {
    // Merge both streams (by serviceId and by serviceName)
    return StreamBuilder<QuerySnapshot>(
      stream: _ordersStream(),
      builder: (ctx, snapById) {
        return StreamBuilder<QuerySnapshot>(
          stream: _ordersByNameStream(),
          builder: (ctx, snapByName) {
            // Merge & deduplicate
            final Map<String, Map<String, dynamic>> orderMap = {};
            for (final snap in [snapById, snapByName]) {
              if (snap.hasData) {
                for (final doc in snap.data!.docs) {
                  orderMap[doc.id] =
                      {...doc.data() as Map<String, dynamic>, '_docId': doc.id};
                }
              }
            }

            final orders = orderMap.values.toList();

            // Sort by createdAt descending
            orders.sort((a, b) {
              final tA = a['createdAt'] as Timestamp?;
              final tB = b['createdAt'] as Timestamp?;
              if (tA == null && tB == null) return 0;
              if (tA == null) return 1;
              if (tB == null) return -1;
              return tB.compareTo(tA);
            });

            // Stats
            final totalOrders = orders.length;
            final subscribedOrders = orders
                .where((o) =>
                    (o['subscription'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains('subscri') ||
                    (o['appliedUniqueCode'] != null &&
                        o['appliedUniqueCode'].toString().isNotEmpty))
                .length;
            final nonSubscribedOrders = totalOrders - subscribedOrders;
            double orderRevenue = 0;
            for (final o in orders) {
              orderRevenue += (o['amount'] as num?)?.toDouble() ?? 0;
            }
            final codOrders = orders
                .where((o) =>
                    (o['paymentMethod'] ?? '')
                        .toString()
                        .toLowerCase()
                        .contains('cash'))
                .length;
            final onlineOrders = totalOrders - codOrders;

            // Apply filter
            var filteredOrders = orders;
            if (_ordersFilter == 'Revenue') {
              filteredOrders = orders.where((o) => ((o['amount'] as num?) ?? 0) > 0).toList();
            } else if (_ordersFilter == 'Subscribed') {
              filteredOrders = orders.where((o) =>
                  (o['subscription'] ?? '').toString().toLowerCase().contains('subscri') ||
                  (o['appliedUniqueCode'] != null && o['appliedUniqueCode'].toString().isNotEmpty)).toList();
            } else if (_ordersFilter == 'Non-Subscribed') {
              filteredOrders = orders.where((o) =>
                  !((o['subscription'] ?? '').toString().toLowerCase().contains('subscri')) &&
                  !(o['appliedUniqueCode'] != null && o['appliedUniqueCode'].toString().isNotEmpty)).toList();
            } else if (_ordersFilter == 'COD Orders') {
              filteredOrders = orders.where((o) => (o['paymentMethod'] ?? '').toString().toLowerCase().contains('cash')).toList();
            } else if (_ordersFilter == 'Online Orders') {
              filteredOrders = orders.where((o) => !(o['paymentMethod'] ?? '').toString().toLowerCase().contains('cash')).toList();
            }

            return StreamBuilder<QuerySnapshot>(
              stream: _subscriptionsStream(),
              builder: (ctx, subSnapById) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _subscriptionsByNameStream(),
                  builder: (ctx, subSnapByName) {
                    
                    double subRevenue = 0;
                    final Map<String, dynamic> mergedSubs = {};
                    if (subSnapById.hasData) {
                      for (final doc in subSnapById.data!.docs) {
                        mergedSubs[doc.id] = (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
                      }
                    }
                    if (subSnapByName.hasData) {
                      for (final doc in subSnapByName.data!.docs) {
                        mergedSubs[doc.id] = (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
                      }
                    }
                    for (final val in mergedSubs.values) {
                      subRevenue += (val as num?)?.toDouble() ?? 0;
                    }

                    final double grandTotalRevenue = orderRevenue + subRevenue;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSummaryCards(
                          totalOrders: totalOrders,
                          subscribedOrders: subscribedOrders,
                          nonSubscribedOrders: nonSubscribedOrders,
                          totalRevenue: grandTotalRevenue, // Global Revenue across orders & subs
                          codOrders: codOrders,
                          onlineOrders: onlineOrders,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '$_ordersFilter (${filteredOrders.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: navy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (filteredOrders.isEmpty)
                          _emptyState('No orders match this filter', Icons.receipt_long)
                        else
                          ...filteredOrders.map((o) => _buildOrderCard(o)),
                      ],
                    );
                  }
                );
              }
            );

          },
        );
      },
    );
  }

  // ──────────────────── SUBSCRIPTIONS TAB ────────────────────

  Widget _buildSubscriptionsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _subscriptionsStream(),
      builder: (ctx, snapById) {
        return StreamBuilder<QuerySnapshot>(
          stream: _subscriptionsByNameStream(),
          builder: (ctx, snapByName) {
            final Map<String, Map<String, dynamic>> subMap = {};
            for (final snap in [snapById, snapByName]) {
              if (snap.hasData) {
                for (final doc in snap.data!.docs) {
                  subMap[doc.id] =
                      {...doc.data() as Map<String, dynamic>, '_docId': doc.id};
                }
              }
            }

            final subs = subMap.values.toList();
            subs.sort((a, b) {
              final tA = a['createdAt'] as Timestamp?;
              final tB = b['createdAt'] as Timestamp?;
              if (tA == null && tB == null) return 0;
              if (tA == null) return 1;
              if (tB == null) return -1;
              return tB.compareTo(tA);
            });

            final activeSubs =
                subs.where((s) => s['isActive'] == true).toList();
            final expiredSubs =
                subs.where((s) => s['isActive'] != true).toList();

            double totalSubRevenue = 0;
            for (final s in subs) {
              totalSubRevenue += (s['amount'] as num?)?.toDouble() ?? 0;
            }

            // Apply filters
            var filteredSubs = subs;
            if (_subsFilter == 'Active') {
              filteredSubs = activeSubs;
            } else if (_subsFilter == 'Expired') {
              filteredSubs = expiredSubs;
            } else if (_subsFilter == 'Sub Revenue') {
              filteredSubs = subs.where((s) => ((s['amount'] as num?) ?? 0) > 0).toList();
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSubSummaryCards(
                  total: subs.length,
                  active: activeSubs.length,
                  expired: expiredSubs.length,
                  totalRevenue: totalSubRevenue,
                ),
                const SizedBox(height: 20),
                Text(
                  '$_subsFilter (${filteredSubs.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                const SizedBox(height: 12),
                if (filteredSubs.isEmpty)
                  _emptyState('No subscriptions match this filter', Icons.card_membership)
                else
                  ...filteredSubs.map((s) => _buildSubscriptionCard(s, s['isActive'] == true)),
              ],
            );
          },
        );
      },
    );
  }

  // ──────────────────── SUMMARY CARDS ────────────────────

  Widget _buildSummaryCards({
    required int totalOrders,
    required int subscribedOrders,
    required int nonSubscribedOrders,
    required double totalRevenue,
    required int codOrders,
    required int onlineOrders,
  }) {
    return Column(
      children: [
        Row(
          children: [
            _summaryTile(
              Icons.shopping_bag,
              'Total Orders',
              '$totalOrders',
              accent,
              isOrderFilter: true,
            ),
            const SizedBox(width: 12),
            _summaryTile(
              Icons.currency_rupee,
              'Revenue',
              '₹${totalRevenue.toStringAsFixed(0)}',
              Colors.green.shade700,
              isOrderFilter: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _summaryTile(
              Icons.card_membership,
              'Subscribed',
              '$subscribedOrders',
              Colors.purple.shade600,
              isOrderFilter: true,
            ),
            const SizedBox(width: 12),
            _summaryTile(
              Icons.shopping_cart,
              'Non-Subscribed',
              '$nonSubscribedOrders',
              Colors.orange.shade700,
              isOrderFilter: true,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _summaryTile(
              Icons.money,
              'COD Orders',
              '$codOrders',
              Colors.teal.shade600,
              isOrderFilter: true,
            ),
            const SizedBox(width: 12),
            _summaryTile(
              Icons.qr_code,
              'Online Orders',
              '$onlineOrders',
              Colors.indigo.shade600,
              isOrderFilter: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubSummaryCards({
    required int total,
    required int active,
    required int expired,
    required double totalRevenue,
  }) {
    return Column(
      children: [
        Row(
          children: [
            _summaryTile(
                Icons.card_membership, 'Total Subs', '$total', accent, isOrderFilter: false),
            const SizedBox(width: 12),
            _summaryTile(
              Icons.currency_rupee,
              'Sub Revenue',
              '₹${totalRevenue.toStringAsFixed(0)}',
              Colors.green.shade700,
              isOrderFilter: false,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _summaryTile(
              Icons.check_circle,
              'Active',
              '$active',
              Colors.green.shade600,
              isOrderFilter: false,
            ),
            const SizedBox(width: 12),
            _summaryTile(
              Icons.cancel,
              'Expired',
              '$expired',
              Colors.red.shade400,
              isOrderFilter: false,
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryTile(
      IconData icon, String label, String value, Color color,
      {required bool isOrderFilter}) {
    
    final isSelected = isOrderFilter ? _ordersFilter == label : _subsFilter == label;
    final displayColor = isSelected ? color : color.withOpacity(0.5);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isOrderFilter) {
              _ordersFilter = label;
            } else {
              _subsFilter = label;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [displayColor.withOpacity(0.85), displayColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
            boxShadow: isSelected ? [
              BoxShadow(
                color: displayColor.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ] : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicUserInfo(String uid, String? cachedName, String? cachedPhone) {
    if (cachedName != null || cachedPhone != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🧑 ${cachedName ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
            if (cachedPhone != null)
              GestureDetector(
                onTap: () => launchUrl(Uri.parse('tel:$cachedPhone')),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('📱 $cachedPhone', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
              )
          ],
        ),
      );
    }
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('user_register').doc(uid).get(),
      builder: (context, snap) {
        if (!snap.hasData) return const Padding(padding: EdgeInsets.only(top:6), child: SizedBox(height:12, width: 12, child: CircularProgressIndicator(strokeWidth: 2)));
        final data = snap.data?.data() as Map<String, dynamic>?;
        final name = data?['name'] as String? ?? 'Unknown Customer';
        final phone = data?['phone'] as String?;
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🧑 $name', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
              if (phone != null)
                GestureDetector(
                  onTap: () => launchUrl(Uri.parse('tel:$phone')),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('📱 $phone', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          ),
        );
      }
    );
  }

  // ──────────────────── ORDER CARD ────────────────────

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final paymentMethod = order['paymentMethod'] ?? 'Cash on Delivery';
    final isCOD = paymentMethod.toString().toLowerCase().contains('cash');
    final mealType = order['mealType'] ?? 'veg';
    final mealPlan = order['mealPlan'] ?? '';
    final subscription = order['subscription'] ?? '';
    final amount = (order['amount'] as num?)?.toDouble() ?? 0;
    final originalAmount = (order['originalAmount'] as num?)?.toDouble();
    final displayAmount = (amount == 0.0 && originalAmount != null) ? originalAmount : amount;
    final deliveryCharge = (order['deliveryCharge'] as num?)?.toDouble() ?? 0;
    final distanceKm = (order['distanceInKm'] as num?)?.toDouble() ?? 0;
    final date = order['date'] ?? '';
    final status = order['status'] ?? 'Pending';
    final rating = (order['rating'] as num?)?.toDouble() ?? 0;
    final uid = order['userId'] ?? 'anonymous';
    final userName = order['userName'] as String?;
    final userMobile = order['userMobile'] as String?;
    final locationMap = order['location'] as Map<String, dynamic>?;
    final address = locationMap?['address'] as String?;
    
    final extraFood =
        (order['extraFood'] as List<dynamic>?)?.cast<String>() ?? [];
    final uniqueCode = order['appliedUniqueCode'] ?? '';
    final paymentCompleted = order['paymentCompleted'] ?? false;
    final docId = order['_docId'] ?? '';

    final createdAt = order['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate())
        : date;

    final Color statusColor;
    switch (status.toString().toLowerCase()) {
      case 'delivered':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'preparing':
        statusColor = Colors.orange;
        break;
      case 'on the way':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = accent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.15),
            child: Icon(
              paymentCompleted ? Icons.check_circle : Icons.timer,
              color: statusColor,
              size: 24,
            ),
          ),
          title: Text(
            (amount == 0.0 && originalAmount != null) ? '₹${displayAmount.toStringAsFixed(2)} (Prepaid)' : '₹${displayAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: navy,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Row(
                children: [
                  _statusBadge(status, statusColor),
                  const SizedBox(width: 8),
                  _paymentBadge(isCOD),
                ],
              ),
              _buildDynamicUserInfo(uid, userName, userMobile),
            ],
          ),
          children: [
            const Divider(),
            if (address != null && address.isNotEmpty)
               Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 130,
                        child: Text(
                          'Address',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            _detailRow('User ID', uid),
            _detailRow('Meal Type', mealType.toUpperCase()),
            _detailRow('Meal Plan', mealPlan),
            _detailRow('Subscription', subscription),
            _detailRow('Payment', paymentMethod),
            _detailRow(
                'Delivery Charge',
                deliveryCharge > 0
                    ? '₹${deliveryCharge.toStringAsFixed(2)} (${distanceKm.toStringAsFixed(1)} km)'
                    : 'FREE'),
            if (extraFood.isNotEmpty) _detailRow('Extra Items', extraFood.join(', ')),
            if (uniqueCode.toString().isNotEmpty)
              _detailRow('Unique Code', uniqueCode.toString()),
            if (rating > 0)
              _detailRow(
                'Rating',
                '⭐ ${rating.toStringAsFixed(1)}',
              ),
            if (docId.isNotEmpty)
              _buildOrderActionButtons(docId, status.toString()),
          ],
        ),
      ),
    );
  }

  // ──────────────────── SUBSCRIPTION CARD ────────────────────

  Widget _buildSubscriptionCard(Map<String, dynamic> sub, bool isActive) {
    final amount = (sub['amount'] as num?)?.toDouble() ?? 0;
    final type = sub['subscriptionType'] ?? '';
    final category = sub['category'] ?? '';
    final mealType = sub['mealType'] ?? 'veg';
    final uid = sub['userId'] ?? 'anonymous';
    final userName = sub['userName'] as String?;
    final userMobile = sub['userMobile'] as String?;
    final pm = sub['paymentMethod'] ?? 'Cash on Delivery';
    final uniqueCode = sub['uniqueCode'] ?? '';
    final mealPeriods =
        (sub['mealPeriods'] as List<dynamic>?)?.cast<String>() ?? [];

    final createdAt = sub['createdAt'] as Timestamp?;
    String startStr = '';
    String endStr = '';
    try {
      startStr = sub['startDate'] != null
          ? DateFormat('dd MMM yyyy')
              .format(DateTime.parse(sub['startDate']))
          : '';
      endStr = sub['endDate'] != null
          ? DateFormat('dd MMM yyyy')
              .format(DateTime.parse(sub['endDate']))
          : '';
    } catch (_) {}

    final dateStr = createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toDate())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isActive
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: CircleAvatar(
            backgroundColor: isActive
                ? Colors.green.withOpacity(0.15)
                : Colors.grey.withOpacity(0.15),
            child: Icon(
              isActive ? Icons.check_circle : Icons.cancel,
              color: isActive ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          title: Text(
            '₹${amount.toStringAsFixed(2)} — ${type.toUpperCase()}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: navy,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(dateStr,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Row(
                children: [
                  _statusBadge(
                      isActive ? 'Active' : 'Expired',
                      isActive ? Colors.green : Colors.grey),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
              _buildDynamicUserInfo(uid, userName, userMobile),
            ],
          ),
          children: [
            const Divider(),
            _detailRow('User ID', uid),
            _detailRow('Meal Type', mealType.toUpperCase()),
            _detailRow('Category', category),
            _detailRow('Payment', pm),
            if (mealPeriods.isNotEmpty)
              _detailRow('Meal Periods', mealPeriods.join(', ')),
            if (startStr.isNotEmpty) _detailRow('Start Date', startStr),
            if (endStr.isNotEmpty) _detailRow('End Date', endStr),
            if (uniqueCode.toString().isNotEmpty)
              _detailRow('Unique Code', uniqueCode.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActionButtons(String orderId, String currentStatus) {
    if (currentStatus.toLowerCase() == 'pending') {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(orderId, 'Preparing'),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Accept & Prepare'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else if (currentStatus.toLowerCase() == 'preparing') {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
             ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(orderId, 'On the Way'),
              icon: const Icon(Icons.directions_bike, size: 18),
              label: const Text('Out for Delivery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else if (currentStatus.toLowerCase() == 'on the way') {
      return Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
             ElevatedButton.icon(
              onPressed: () => _updateOrderStatus(orderId, 'Delivered'),
              icon: const Icon(Icons.where_to_vote, size: 18),
              label: const Text('Mark Delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'status': status});
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
       }
    }
  }

  // ──────────────────── HELPER WIDGETS ────────────────────

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _paymentBadge(bool isCOD) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isCOD
            ? Colors.teal.withOpacity(0.1)
            : Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isCOD ? 'COD' : 'Online',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isCOD ? Colors.teal : Colors.indigo,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
