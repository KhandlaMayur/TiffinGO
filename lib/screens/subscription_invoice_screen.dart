import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/subscription_model.dart';

class SubscriptionInvoiceScreen extends StatelessWidget {
  final SubscriptionModel subscription;

  const SubscriptionInvoiceScreen({super.key, required this.subscription});

  String _buildInvoiceText() {
    final buffer = StringBuffer();
    buffer.writeln('Tiffin Service - Subscription Invoice');
    buffer.writeln('--------------------------------------');
    buffer.writeln('Invoice ID: ${subscription.id}');
    buffer.writeln('User ID: ${subscription.userId}');
    buffer.writeln('Service: ${subscription.tiffineService ?? 'N/A'}');
    buffer.writeln('Category: ${subscription.category}');
    buffer.writeln('Meal Type: ${subscription.mealType ?? 'N/A'}');
    buffer.writeln('Subscription Type: ${subscription.subscriptionType}');
    buffer.writeln(
        'Start Date: ${subscription.startDate.day}/${subscription.startDate.month}/${subscription.startDate.year}');
    buffer.writeln(
        'End Date: ${subscription.endDate.day}/${subscription.endDate.month}/${subscription.endDate.year}');
    if (subscription.pauseStart != null && subscription.pauseEnd != null) {
      buffer.writeln(
          'Pause Start: ${subscription.pauseStart!.day}/${subscription.pauseStart!.month}/${subscription.pauseStart!.year}');
      buffer.writeln(
          'Pause End: ${subscription.pauseEnd!.day}/${subscription.pauseEnd!.month}/${subscription.pauseEnd!.year}');
    }
    buffer.writeln('Quantity/day: ${subscription.quantityPerDay}');
    buffer.writeln('Meal Periods: ${subscription.mealPeriods.join(', ')}');
    buffer.writeln('Extra Orders: ${subscription.extraOrders}');
    buffer.writeln('Remaining Orders: ${subscription.remainingOrders}');
    buffer.writeln('Amount: ₹${subscription.amount.toStringAsFixed(2)}');
    buffer.writeln(
        'Pending Amount: ₹${subscription.pendingAmount.toStringAsFixed(2)}');
    buffer.writeln('Payment Method: ${subscription.paymentMethod}');
    buffer.writeln(
        'Payment Completed: ${subscription.paymentCompleted ? 'Yes' : 'No'}');
    buffer.writeln('Unique Code: ${subscription.uniqueCode ?? 'N/A'}');
    buffer.writeln('--------------------------------------');
    buffer.writeln('Thank you for your subscription!');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _buildInvoiceText();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Invoice'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  invoice,
                  style: const TextStyle(fontSize: 16, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: invoice));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Invoice copied to clipboard')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Invoice'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // For now just pop with a message; advanced sharing/PDF can be added later
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Sharing not available (add share package)')),
                        );
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                    ),
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
