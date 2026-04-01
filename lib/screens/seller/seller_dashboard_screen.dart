import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'seller_menu_management_screen.dart';
import 'seller_orders_screen.dart';
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
  late final Stream<DocumentSnapshot> _serviceStream;

  @override
  void initState() {
    super.initState();
    // Use a real-time stream so approval status auto-refreshes when admin acts
    _serviceStream = FirebaseFirestore.instance
        .collection('tiffin_services')
        .doc(widget.serviceId)
        .snapshots();
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
    if (currentlyClosed) {
      // Service was closed → just reopen it (no deletion)
      try {
        await FirebaseFirestore.instance
            .collection('tiffin_services')
            .doc(widget.serviceId)
            .update({'isClosed': false});
        if (mounted) setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reopen service: $e')),
          );
        }
      }
      return;
    }

    // Service is open → seller wants to close = permanently delete everything
    await _confirmAndDeleteAccount();
  }

  /// Shows a strong confirmation dialog then deletes ALL seller data and account.
  Future<void> _confirmAndDeleteAccount() async {
    // Step 1 — first confirmation
    final step1 = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text('Close Service?', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently close your tiffin service?\n\n'
          'This will DELETE all your data including:\n'
          '• Your service details\n'
          '• Your seller account\n'
          '• Your login credentials\n\n'
          'This action CANNOT be undone.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yes, Close & Delete'),
          ),
        ],
      ),
    );

    if (step1 != true) return;

    // Step 2 — final confirmation (prevent accidental taps)
    final step2 = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Final Confirmation',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'You are about to permanently delete your account and all your data.\n\n'
          'Tap "DELETE" to confirm.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade900,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('DELETE ACCOUNT'),
          ),
        ],
      ),
    );

    if (step2 != true) return;

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Deleting your account...',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    try {
      final db = FirebaseFirestore.instance;
      final sellerId = widget.serviceId;

      // 1. Delete tiffin_services document
      await db.collection('tiffin_services').doc(sellerId).delete();

      // 2. Delete seller_register document
      await db.collection('seller_register').doc(sellerId).delete();

      // 3. Delete seller_login document
      final loginDoc = await db.collection('seller_login').doc(sellerId).get();
      if (loginDoc.exists) {
        await db.collection('seller_login').doc(sellerId).delete();
      }

      // 4. Delete Firebase Auth account (must be done while user is still signed in)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == sellerId) {
        await currentUser.delete();
      }

      // 5. Clear local auth state
      if (mounted) {
        context.read<AuthProvider>().logout();
      }

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been permanently deleted.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to login screen
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        // Close loading dialog if open
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        body: StreamBuilder<DocumentSnapshot>(
          stream: _serviceStream,
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

            // Check if service is approved by admin
            final isApproved = data['isApproved'] as bool? ?? false;
            final approvalStatus = data['approvalStatus'] as String?;
            
            if (approvalStatus == 'rejected') {
              return _buildRejectedScreen(data);
            } else if (!isApproved || approvalStatus == 'pending') {
              return _buildPendingApprovalScreen(data);
            }
            
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
                  if (approvalStatus == 'approved') ...[
                    Text(
                      'Welcome to TiffinGO, ${data['ownerName'] ?? 'Seller'}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your request is accepted.',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
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
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SellerOrdersScreen(
                            serviceId: widget.serviceId,
                            serviceName: serviceName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics),
                    label: const Text('View Orders & Subscriptions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                    label: const Text('Manage Menu (Daily Override)'),
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
                    icon: Icon(isClosed ? Icons.check_circle : Icons.delete_forever),
                    label: Text(isClosed ? 'Reopen Service' : 'Close & Delete Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isClosed ? Colors.green : Colors.red.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _showComplaintDialog,
                    icon: const Icon(Icons.report_problem),
                    label: const Text('Report Issue / Complaint'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
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

  /// Shows a pending approval screen when admin hasn't approved the service yet
  Widget _buildPendingApprovalScreen(Map<String, dynamic> data) {
    const navy = Color(0xFF001F54);
    final serviceName = data['serviceName'] as String? ?? 'Your Service';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, size: 80, color: Colors.orange[400]),
            const SizedBox(height: 24),
            const Text(
              'Pending Admin Approval',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your service "$serviceName" has been submitted for review. The admin will approve it shortly.',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You cannot edit menu, manage orders, or update service details until admin approves your service request.',
                      style: TextStyle(fontSize: 13, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'The page will update automatically when admin approves your request.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a restricted screen when admin has rejected the service
  Widget _buildRejectedScreen(Map<String, dynamic> data) {
    const navy = Color(0xFF001F54);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Request Rejected',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your request is rejected from the admin side please fill form again',
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (ctx) => SellerServiceFormScreen(
                      userId: widget.serviceId,
                      userName: data['ownerName'] ?? '',
                      userPhone: data['mobile'] as String?,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_document),
              label: const Text('Fill Form Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a dialog for seller to submit a complaint
  void _showComplaintDialog() {
    final complaintController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Issue / Complaint'),
        content: TextField(
          controller: complaintController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Describe your issue or complaint...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = complaintController.text.trim();
              if (text.isEmpty) return;
              try {
                await FirebaseFirestore.instance.collection('complaints').add({
                  'message': text,
                  'from': 'seller',
                  'sellerId': widget.serviceId,
                  'sellerName': '',
                  'createdAt': FieldValue.serverTimestamp(),
                  'status': 'pending',
                });
                // Try to get seller name
                try {
                  final doc = await FirebaseFirestore.instance
                      .collection('seller_register')
                      .doc(widget.serviceId)
                      .get();
                  if (doc.exists) {
                    await FirebaseFirestore.instance
                        .collection('complaints')
                        .where('sellerId', isEqualTo: widget.serviceId)
                        .orderBy('createdAt', descending: true)
                        .limit(1)
                        .get()
                        .then((snap) {
                      if (snap.docs.isNotEmpty) {
                        snap.docs.first.reference.update({
                          'sellerName': doc.data()?['name'] ?? 'Unknown Seller',
                        });
                      }
                    });
                  }
                } catch (_) {}

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complaint submitted successfully.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to submit: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001F54),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
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
