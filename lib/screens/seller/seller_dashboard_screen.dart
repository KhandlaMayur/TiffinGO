import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'seller_menu_management_screen.dart';
import 'seller_service_form_screen.dart';
import 'seller_weekly_menu_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  final String serviceId;

  const SellerDashboardScreen({
    super.key,
    required this.serviceId,
  });

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  late final CollectionReference _servicesRef;

  @override
  void initState() {
    super.initState();
    _servicesRef = FirebaseFirestore.instance.collection('tiffin_services');
  }

  Future<DocumentSnapshot> _fetchService() async {
    return _servicesRef.doc(widget.serviceId).get();
  }

  void _goToEdit(Map<String, dynamic> data) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SellerServiceFormScreen(
          userId: widget.serviceId,
          userName: data['ownerName'] as String? ?? '',
          userPhone: data['mobile'] as String?,
        ),
      ),
    );
  }

  Future<void> _toggleServiceStatus(bool currentlyClosed) async {
    if (!currentlyClosed) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Close Service?'),
          content: const Text(
              'Are you sure you want to close your tiffin service? It will no longer be visible to users.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close Service'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('tiffin_services')
          .doc(widget.serviceId)
          .update({'isClosed': !currentlyClosed});

      if (!mounted) return;

      if (!currentlyClosed) {
        // Log them out when closing
        context.read<AuthProvider>().logout();
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        // Service reopened, reload the UI
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update service status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF001F54);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seller Dashboard'),
          backgroundColor: navy,
          foregroundColor: Colors.white,
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: _fetchService(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text('Service not found. Please set up your service.'),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final serviceName = data['serviceName'] as String? ?? 'My Service';
            final address = data['address'] as String? ?? '';
            final availableTime = data['availableTime'] as String? ?? '';
            final mobile = data['mobile'] as String? ?? '';
            final jainVeg = data['jainVeg'] as bool? ?? false;
            final types = (data['tiffinTypes'] as List<dynamic>?)
                    ?.cast<String>()
                    .toList() ??
                [];
            final isClosed = data['isClosed'] as bool? ?? false;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: navy,
                            ),
                          ),
                          if (isClosed) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red),
                              ),
                              child: const Text(
                                'SERVICE CLOSED',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          const Divider(height: 24, thickness: 1),
                          _buildDetailRow(
                              Icons.location_on, 'Address', address),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                              Icons.access_time, 'Available', availableTime),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.phone, 'Mobile', mobile),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            Icons.eco,
                            'Jain/Veg options',
                            jainVeg ? 'Available' : 'Not Available',
                          ),
                          if (types.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Tiffin Types:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: types
                                  .map((type) => Chip(
                                        label: Text(type),
                                        backgroundColor: navy.withOpacity(0.1),
                                        labelStyle:
                                            const TextStyle(color: navy),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _goToEdit(data),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Service Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SellerWeeklyMenuScreen(
                            serviceId: widget.serviceId,
                            serviceName: serviceName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: const Text('Weekly Meal Menu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SellerMenuManagementScreen(
                            serviceId: widget.serviceId,
                            serviceName: serviceName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Manage Standard Menu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: navy,
                      side: const BorderSide(color: navy),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/home',
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.remove_red_eye),
                    label: const Text('View as User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _toggleServiceStatus(isClosed),
                    icon: Icon(isClosed ? Icons.check_circle : Icons.cancel),
                    label: Text(isClosed ? 'Reopen Service' : 'Close Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isClosed ? Colors.green : Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
