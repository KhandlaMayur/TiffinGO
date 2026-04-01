import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminSellersScreen extends StatefulWidget {
  const AdminSellersScreen({super.key});

  @override
  State<AdminSellersScreen> createState() => _AdminSellersScreenState();
}

class _AdminSellersScreenState extends State<AdminSellersScreen> {
  static const _navy = Color(0xFF001F54);
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search sellers...',
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
        // Sellers list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('seller_register')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('No sellers registered.',
                        style: TextStyle(color: Colors.grey)));
              }

              var docs = snapshot.data!.docs;
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                      (data['name'] ?? '').toString().toLowerCase();
                  final email =
                      (data['email'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildSellerCard(doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSellerCard(String docId, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown';
    final email = data['email'] ?? '—';
    final phone = data['phone'] ?? '—';
    final isApproved = data['isApproved'] as bool? ?? true;
    final isDisabled = data['isDisabled'] as bool? ?? false;

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
                        : 'S',
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
                // Status badges
                Column(
                  children: [
                    _buildBadge(
                      isApproved ? 'Approved' : 'Pending',
                      isApproved ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(height: 4),
                    if (isDisabled)
                      _buildBadge('Disabled', Colors.red),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('📞 $phone',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 12),
            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!isApproved)
                  _actionButton(
                    'Approve',
                    Icons.check_circle,
                    Colors.green,
                    () => _updateSellerField(docId, 'isApproved', true),
                  ),
                if (isApproved)
                  _actionButton(
                    'Reject',
                    Icons.cancel,
                    Colors.orange,
                    () => _updateSellerField(docId, 'isApproved', false),
                  ),
                _actionButton(
                  isDisabled ? 'Enable' : 'Disable',
                  isDisabled ? Icons.check : Icons.block,
                  isDisabled ? Colors.green : Colors.red,
                  () => _updateSellerField(docId, 'isDisabled', !isDisabled),
                ),
                _actionButton(
                  'View Service',
                  Icons.visibility,
                  _navy,
                  () => _viewSellerService(docId, data),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _actionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }

  Future<void> _updateSellerField(
      String docId, String field, dynamic value) async {
    try {
      await FirebaseFirestore.instance
          .collection('seller_register')
          .doc(docId)
          .update({field: value});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Seller $field updated.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _viewSellerService(String sellerId, Map<String, dynamic> sellerData) async {
    // Try to find a service owned by this seller
    final query = await FirebaseFirestore.instance
        .collection('tiffin_services')
        .doc(sellerId)
        .get();

    if (!mounted) return;

    if (!query.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No service found for this seller.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final serviceData = query.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(serviceData['serviceName'] ?? 'Service Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Address', serviceData['address'] ?? '—'),
              _detailRow('Available Time', serviceData['availableTime'] ?? '—'),
              _detailRow('Mobile', serviceData['mobile'] ?? '—'),
              _detailRow('Jain/Veg', (serviceData['jainVeg'] == true) ? 'Yes' : 'No'),
              _detailRow('Is Closed', (serviceData['isClosed'] == true) ? 'Yes' : 'No'),
              if (serviceData['tiffinTypes'] != null)
                _detailRow('Types', (serviceData['tiffinTypes'] as List).join(', ')),
              if (serviceData['prices'] != null)
                _detailRow('Prices', serviceData['prices'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
