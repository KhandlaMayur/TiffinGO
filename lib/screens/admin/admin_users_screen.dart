import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const _navy = Color(0xFF001F54);
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search, color: _navy),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _navy),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('user_register')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('No users registered.',
                        style: TextStyle(color: Colors.grey)));
              }

              var docs = snapshot.data!.docs;
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final phone = (data['phone'] ?? '').toString();
                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      phone.contains(_searchQuery);
                }).toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildUserCard(doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(String docId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? '—';
    final phone = data['phone'] ?? '—';
    final isBlocked = data['isBlocked'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _navy.withOpacity(0.1),
                  child: Text(
                    name.toString().isNotEmpty
                        ? name.toString()[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                        color: _navy, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(email,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                if (isBlocked)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: const Text(
                      'Blocked',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Tappable phone number → opens phone dialer
            GestureDetector(
              onTap: () {
                final phoneNum = phone.toString().replaceAll(RegExp(r'[^\d+]'), '');
                if (phoneNum.isNotEmpty) {
                  launchUrl(Uri.parse('tel:$phoneNum'));
                }
              },
              child: Text(
                '📞 $phone',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _toggleBlock(docId, isBlocked),
                  icon: Icon(
                    isBlocked ? Icons.check_circle : Icons.block,
                    size: 16,
                    color: isBlocked ? Colors.green : Colors.red,
                  ),
                  label: Text(
                    isBlocked ? 'Unblock' : 'Block',
                    style: TextStyle(
                      color: isBlocked ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: (isBlocked ? Colors.green : Colors.red)
                          .withOpacity(0.5),
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _viewOrderHistory(docId, data),
                  icon: const Icon(Icons.history, size: 16, color: _navy),
                  label: const Text('Order History',
                      style: TextStyle(color: _navy, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _navy.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBlock(String docId, bool currentlyBlocked) async {
    try {
      await FirebaseFirestore.instance
          .collection('user_register')
          .doc(docId)
          .update({'isBlocked': !currentlyBlocked});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                currentlyBlocked ? 'User unblocked successfully.' : 'User blocked successfully. User cannot login until unblocked.'),
            backgroundColor: Colors.green,
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

  void _viewOrderHistory(String userId, Map<String, dynamic> userData) {
    final userName = userData['name'] ?? 'User';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Order History — $userName',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('orders')
                        .where('userId', isEqualTo: userId)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('No orders found.'));
                      }
                      return _buildOrderList(
                          snapshot.data!.docs, scrollController);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildOrderList(
      List<QueryDocumentSnapshot> docs, ScrollController controller) {
    return ListView.builder(
      controller: controller,
      itemCount: docs.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, i) {
        final data = docs[i].data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pending';
        // Use correct amount fields
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final originalAmount = (data['originalAmount'] as num?)?.toDouble();
        final displayPrice = (amount > 0) ? amount : (originalAmount ?? 0);
        final serviceName = data['serviceName'] ?? '—';
        final mealPlan = data['mealPlan'] ?? '';
        final paymentMethod = data['paymentMethod'] ?? '';

        Color statusColor;
        switch (status.toString().toLowerCase()) {
          case 'delivered':
          case 'completed':
            statusColor = Colors.green;
            break;
          case 'cancelled':
            statusColor = Colors.red;
            break;
          default:
            statusColor = Colors.orange;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order #${docs[i].id.substring(0, 8)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toString().toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Service: $serviceName',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                if (mealPlan.toString().isNotEmpty)
                  Text('Meal Plan: $mealPlan',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                if (paymentMethod.toString().isNotEmpty)
                  Text('Payment: $paymentMethod',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '₹${(displayPrice is num) ? (displayPrice as num).toStringAsFixed(0) : displayPrice}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _navy),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
