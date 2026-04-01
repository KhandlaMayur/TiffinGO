import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen>
    with SingleTickerProviderStateMixin {
  static const _navy = Color(0xFF001F54);
  String _searchQuery = '';
  // Filter: 'pending', 'all', 'approved', 'rejected'
  String _filter = 'pending';

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final filters = ['pending', 'all', 'approved', 'rejected'];
        setState(() => _filter = filters[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter tabs
        TabBar(
          controller: _tabController,
          labelColor: _navy,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _navy,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'All'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search services...',
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
                .collection('tiffin_services')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('No services found.',
                        style: TextStyle(color: Colors.grey)));
              }

              var docs = snapshot.data!.docs;

              // Apply filter
              docs = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = (data['approvalStatus'] as String?) ?? 
                    ((data['isApproved'] as bool? ?? false) ? 'approved' : 'pending');
                switch (_filter) {
                  case 'pending':
                    return status == 'pending';
                  case 'approved':
                    return status == 'approved';
                  case 'rejected':
                    return status == 'rejected';
                  default:
                    return true;
                }
              }).toList();

              // Apply search
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                      (data['serviceName'] ?? '').toString().toLowerCase();
                  final address =
                      (data['address'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      address.contains(_searchQuery);
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _filter == 'pending'
                          ? 'No pending service requests.'
                          : 'No services found.',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildServiceCard(doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(String docId, Map<String, dynamic> data) {
    final name = data['serviceName'] ?? 'Unnamed Service';
    final address = data['address'] ?? '—';
    final mobile = data['mobile'] ?? '—';
    final isClosed = data['isClosed'] as bool? ?? false;
    final isDisabled = data['isDisabled'] as bool? ?? false;
    final isApproved = data['isApproved'] as bool? ?? false;
    final approvalStatus = data['approvalStatus'] as String? ?? (isApproved ? 'approved' : 'pending');
    final ownerName = data['ownerName'] ?? '—';
    final types =
        (data['tiffinTypes'] as List<dynamic>?)?.cast<String>() ?? [];
    final serviceRange = data['serviceRangeKm'];

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _navy)),
                      const SizedBox(height: 4),
                      Text('Owner: $ownerName',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    // Approval status badge
                    _buildBadge(
                      approvalStatus == 'approved'
                          ? 'Approved'
                          : approvalStatus == 'rejected'
                              ? 'Rejected'
                              : 'Pending',
                      approvalStatus == 'approved'
                          ? Colors.green
                          : approvalStatus == 'rejected'
                              ? Colors.red
                              : Colors.orange,
                    ),
                    const SizedBox(height: 4),
                    if (isClosed)
                      _buildBadge('Closed', Colors.red),
                    if (isDisabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildBadge('Disabled', Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('📍 $address',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            Text('📞 $mobile',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            if (serviceRange != null)
              Text('🚚 Delivery radius: ${serviceRange}km',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            if (types.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: types
                    .map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 11)),
                          backgroundColor: _navy.withOpacity(0.06),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Approve / Reject buttons for pending services
                if (approvalStatus != 'approved')
                  OutlinedButton.icon(
                    onPressed: () => _approveRejectService(docId, true),
                    icon: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    label: const Text('Approve',
                        style: TextStyle(color: Colors.green, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                if (approvalStatus != 'rejected')
                  OutlinedButton.icon(
                    onPressed: () => _approveRejectService(docId, false),
                    icon: const Icon(Icons.cancel, size: 16, color: Colors.orange),
                    label: const Text('Reject',
                        style: TextStyle(color: Colors.orange, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _toggleDisabled(docId, isDisabled),
                  icon: Icon(
                    isDisabled ? Icons.check_circle : Icons.block,
                    size: 16,
                    color: isDisabled ? Colors.green : Colors.red,
                  ),
                  label: Text(
                    isDisabled ? 'Enable' : 'Disable',
                    style: TextStyle(
                      color: isDisabled ? Colors.green : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: (isDisabled ? Colors.green : Colors.red)
                            .withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _removeService(docId, name),
                  icon:
                      const Icon(Icons.delete, size: 16, color: Colors.red),
                  label: const Text('Remove',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _viewMenu(docId, name),
                  icon: const Icon(Icons.restaurant_menu,
                      size: 16, color: _navy),
                  label: const Text('View Menu',
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

  Future<void> _toggleDisabled(String docId, bool currentlyDisabled) async {
    try {
      await FirebaseFirestore.instance
          .collection('tiffin_services')
          .doc(docId)
          .update({'isDisabled': !currentlyDisabled});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentlyDisabled
                ? 'Service enabled.'
                : 'Service disabled.'),
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

  /// Approve or reject a tiffin service — also syncs to seller_register
  Future<void> _approveRejectService(String docId, bool approve) async {
    try {
      final statusStr = approve ? 'approved' : 'rejected';

      // Update tiffin_services
      await FirebaseFirestore.instance
          .collection('tiffin_services')
          .doc(docId)
          .update({'isApproved': approve, 'approvalStatus': statusStr});

      // Also update seller_register
      final sellerDoc = await FirebaseFirestore.instance
          .collection('seller_register')
          .doc(docId)
          .get();
      if (sellerDoc.exists) {
        await FirebaseFirestore.instance
            .collection('seller_register')
            .doc(docId)
            .update({'isApproved': approve, 'approvalStatus': statusStr});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve
                ? 'Service approved. Seller can now proceed.'
                : 'Service rejected. Seller cannot proceed.'),
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

  Future<void> _removeService(String docId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Service?'),
        content: Text(
            'Are you sure you want to permanently remove "$name"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('tiffin_services')
          .doc(docId)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Service removed.'),
              backgroundColor: Colors.green),
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

  void _viewMenu(String serviceId, String serviceName) async {
    final doc = await FirebaseFirestore.instance
        .collection('mealPlans')
        .doc('menus')
        .get();

    if (!mounted) return;

    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No menu data found.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    final serviceMenu =
        (doc.data() ?? {})[serviceId] as Map<String, dynamic>?;
    if (serviceMenu == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No menu configured for this service.'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Menu — $serviceName'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              _formatMenu(serviceMenu),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  String _formatMenu(Map<String, dynamic> menu) {
    final buffer = StringBuffer();
    final days = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];

    // Show veg menu per plan per day
    final veg = menu['veg'] as Map<String, dynamic>?;
    if (veg != null) {
      buffer.writeln('=== VEG MENU ===');
      veg.forEach((plan, dayMap) {
        buffer.writeln('\n  [$plan]');
        if (dayMap is Map) {
          for (final day in days) {
            final items = dayMap[day];
            if (items is List && items.isNotEmpty) {
              final label = day[0].toUpperCase() + day.substring(1);
              buffer.writeln('    $label: ${items.join(", ")}');
            }
          }
        }
      });
    }

    final jain = menu['jain'] as Map<String, dynamic>?;
    if (jain != null) {
      buffer.writeln('\n=== JAIN MENU ===');
      jain.forEach((plan, dayMap) {
        buffer.writeln('\n  [$plan]');
        if (dayMap is Map) {
          for (final day in days) {
            final items = dayMap[day];
            if (items is List && items.isNotEmpty) {
              final label = day[0].toUpperCase() + day.substring(1);
              buffer.writeln('    $label: ${items.join(", ")}');
            }
          }
        }
      });
    }

    if (buffer.isEmpty) return 'No menu data available.';
    return buffer.toString();
  }
}
