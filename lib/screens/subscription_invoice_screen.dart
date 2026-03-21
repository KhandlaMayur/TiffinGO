import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/subscription_model.dart';

class SubscriptionInvoiceScreen extends StatefulWidget {
  final SubscriptionModel subscription;

  const SubscriptionInvoiceScreen({super.key, required this.subscription});

  @override
  State<SubscriptionInvoiceScreen> createState() => _SubscriptionInvoiceScreenState();
}

class _SubscriptionInvoiceScreenState extends State<SubscriptionInvoiceScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _captureAndShare(bool isDownload) async {
    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        delay: const Duration(milliseconds: 10),
      );

      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/invoice_${widget.subscription.id}.png').create();
        await imagePath.writeAsBytes(imageBytes);

        if (isDownload && Platform.isAndroid) {
          // Ideally use Image Gallery Saver, but Share covers saving to Google Drive/Photos
          await Share.shareXFiles(
            [XFile(imagePath.path)], 
            text: 'Save your TiffinGO Invoice',
            subject: 'Invoice ${widget.subscription.id}'
          );
        } else {
          await Share.shareXFiles(
            [XFile(imagePath.path)],
            text: 'Here is my TiffinGO Subscription Invoice!',
            subject: 'Invoice ${widget.subscription.id}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildInvoiceUI() {
    final sub = widget.subscription;
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
          border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(Icons.receipt_long, size: 48, color: Color(0xFF1E3A8A)),
                  const SizedBox(height: 8),
                  const Text(
                    'TiffinGO Invoice',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${sub.id}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 30, thickness: 1.5),
            _buildInvoiceRow('Service Provider', sub.tiffineService ?? 'N/A', isBold: true),
            _buildInvoiceRow('Plan Type', sub.subscriptionType.toUpperCase()),
            _buildInvoiceRow('Category', sub.category),
            _buildInvoiceRow('Meal Type', sub.mealType?.toUpperCase() ?? 'N/A'),
            const SizedBox(height: 10),
            _buildInvoiceRow('Start Date', '${sub.startDate.day}/${sub.startDate.month}/${sub.startDate.year}'),
            _buildInvoiceRow('End Date', '${sub.endDate.day}/${sub.endDate.month}/${sub.endDate.year}'),
            const Divider(height: 25),
            _buildInvoiceRow('Tiffins per Day', '${sub.quantityPerDay}'),
            if (sub.extraOrders > 0)
              _buildInvoiceRow('Extra Orders', '${sub.extraOrders} selected'),
            _buildInvoiceRow('Total Allowed Uses', '${sub.remainingOrders} remaining'),
            _buildInvoiceRow('Meal Periods', sub.mealPeriods.join(', ')),
            const Divider(height: 25),
            _buildInvoiceRow('Payment Method', sub.paymentMethod),
            _buildInvoiceRow('Status', sub.paymentCompleted ? 'Paid' : 'Pending', isPaid: true),
            const SizedBox(height: 15),
            if (sub.uniqueCode != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1E3A8A), style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    const Text('YOUR UNIQUE CODE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    const SizedBox(height: 4),
                    Text(
                      sub.uniqueCode!,
                      style: const TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${sub.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {bool isBold = false, bool isPaid = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: isPaid ? (value == 'Paid' ? Colors.green : Colors.red) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Invoice Details'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Screenshot(
                  controller: _screenshotController,
                  child: _buildInvoiceUI(),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _captureAndShare(true),
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                        foregroundColor: const Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _captureAndShare(false),
                      icon: const Icon(Icons.share),
                      label: const Text('Share Invoice'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
