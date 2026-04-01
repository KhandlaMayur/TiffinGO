import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_sellers_screen.dart';
import 'admin_users_screen.dart';
import 'admin_services_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_complaints_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const _navy = Color(0xFF001F54);

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.dashboard, 'Dashboard'),
    _NavItem(Icons.store, 'Sellers'),
    _NavItem(Icons.people, 'Users'),
    _NavItem(Icons.room_service, 'Services'),
    _NavItem(Icons.receipt_long, 'Orders'),
    _NavItem(Icons.report_problem, 'Complaints'),
  ];

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const AdminSellersScreen();
      case 2:
        return const AdminUsersScreen();
      case 3:
        return const AdminServicesScreen();
      case 4:
        return const AdminOrdersScreen();
      case 5:
        return const AdminComplaintsScreen();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome back, Admin',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Stats grid — use LayoutBuilder for responsive aspect ratio
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = 2),
                      child: _buildStatCard('Total Users', Icons.people,
                          Colors.blue, _streamCount('user_register')),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = 1),
                      child: _buildStatCard('Total Sellers', Icons.store,
                          Colors.green, _streamCount('seller_register')),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = 3),
                      child: _buildStatCard('Active Services', Icons.room_service,
                          Colors.orange, _streamCount('tiffin_services')),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = 4),
                      child: _buildStatCard('Total Orders', Icons.receipt_long,
                          Colors.purple, _streamCount('orders')),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = 4),
                      child: _buildStatCard('Subscriptions', Icons.card_membership,
                          Colors.teal, _streamCount('subscriptions')),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedIndex = 5),
                      child: _buildStatCard('Complaints', Icons.report_problem,
                          Colors.red, _streamCount('complaints')),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Pending Service Requests
          const Text(
            'Pending Service Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 10),
          _buildPendingRequests(),

          const SizedBox(height: 24),

          // Recent orders
          const Text(
            'Recent Orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 10),
          _buildRecentOrders(),
        ],
      ),
    );
  }

  Widget _buildPendingRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tiffin_services')
          .where('approvalStatus', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Text('No pending service requests.',
              style: TextStyle(color: Colors.grey));
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['serviceName'] ?? 'Unnamed Service';
            final ownerName = data['ownerName'] ?? 'Unknown Seller';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: const Icon(Icons.pending_actions, color: Colors.orange),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('by $ownerName'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Approve quickly from dashboard
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      tooltip: 'Approve',
                      onPressed: () => _quickApprove(doc.id, true),
                    ),
                    // Reject quickly from dashboard
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      tooltip: 'Reject',
                      onPressed: () => _quickApprove(doc.id, false),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to Services tab for full review
                        setState(() => _selectedIndex = 3);
                      },
                      child: const Text('Review', style: TextStyle(color: _navy)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Quick approve/reject a tiffin service from the dashboard
  Future<void> _quickApprove(String docId, bool approve) async {
    final statusStr = approve ? 'approved' : 'rejected';
    try {
      await FirebaseFirestore.instance
          .collection('tiffin_services')
          .doc(docId)
          .update({'isApproved': approve, 'approvalStatus': statusStr});

      // Also sync to seller_register if document exists
      final sellerDoc = await FirebaseFirestore.instance
          .collection('seller_register')
          .doc(docId)
          .get();
      if (sellerDoc.exists) {
        await sellerDoc.reference
            .update({'isApproved': approve, 'approvalStatus': statusStr});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? 'Service approved! Seller can now proceed.'
                : 'Service rejected.'),
            backgroundColor: approve ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Stream<int> _streamCount(String collection) {
    return FirebaseFirestore.instance
        .collection(collection)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Widget _buildStatCard(
      String title, IconData icon, Color color, Stream<int> countStream) {
    return StreamBuilder<int>(
      stream: countStream,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const Spacer(),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentOrders() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No orders yet.',
              style: TextStyle(color: Colors.grey));
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            // Use amount/originalAmount (actual order fields)
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            final originalAmount = (data['originalAmount'] as num?)?.toDouble();
            final displayPrice = (amount > 0) ? amount : (originalAmount ?? 0);
            final userName = data['userName'] as String?;
            final userId = data['userId'] as String?;

            Color statusColor;
            switch (status.toString().toLowerCase()) {
              case 'completed':
              case 'delivered':
                statusColor = Colors.green;
                break;
              case 'cancelled':
                statusColor = Colors.red;
                break;
              default:
                statusColor = Colors.orange;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: statusColor.withOpacity(0.1),
                      child: Icon(Icons.receipt, color: statusColor, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${doc.id.substring(0, 8)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          // Show user name (fetched from order or from user_register)
                          (userName != null && userName.isNotEmpty)
                              ? Text(
                                  'User: $userName',
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                )
                              : _buildUserNameWidget(userId),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${(displayPrice is num) ? (displayPrice as num).toStringAsFixed(0) : displayPrice}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status.toString().toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Fetches user name from user_register for display
  Widget _buildUserNameWidget(String? userId) {
    if (userId == null || userId.isEmpty || userId == 'anonymous') {
      return Text('User: Unknown',
          style: TextStyle(color: Colors.grey[600], fontSize: 12));
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('user_register')
          .doc(userId)
          .get(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return Text('User: $userId',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              overflow: TextOverflow.ellipsis);
        }
        final data = snap.data!.data() as Map<String, dynamic>?;
        final name = data?['name'] ?? data?['fullName'] ?? userId;
        return Text('User: $name',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            overflow: TextOverflow.ellipsis);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          // Go back to dashboard tab first
          setState(() => _selectedIndex = 0);
        } else {
          // On dashboard tab: go to login
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: _navy,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'TiffinGO Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Control Panel',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = _selectedIndex == index;
                return ListTile(
                  leading: Icon(
                    item.icon,
                    color: isSelected ? _navy : Colors.grey[600],
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? _navy : Colors.black87,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: _navy.withOpacity(0.06),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    Navigator.pop(context); // close drawer
                  },
                );
              }),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (route) => false);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
