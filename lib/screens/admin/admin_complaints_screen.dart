import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  static const _navy = Color(0xFF001F54);
  String _filterStatus = 'all'; // all, open, reviewed, resolved

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All', 'all'),
                const SizedBox(width: 8),
                _filterChip('Open', 'open'),
                const SizedBox(width: 8),
                _filterChip('Reviewed', 'reviewed'),
                const SizedBox(width: 8),
                _filterChip('Resolved', 'resolved'),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('complaints')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('No complaints yet.',
                        style: TextStyle(color: Colors.grey)));
              }

              var docs = snapshot.data!.docs;
              if (_filterStatus != 'all') {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['status'] ?? 'open')
                          .toString()
                          .toLowerCase() ==
                      _filterStatus;
                }).toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildComplaintCard(doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _navy : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: isSelected ? _navy : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(String docId, Map<String, dynamic> data) {
    final subject = data['subject'] ?? 'No Subject';
    final message = data['message'] ?? '';
    final fromName = data['fromName'] ?? 'Unknown';
    final fromRole = data['fromRole'] ?? 'user';
    final fromEmail = data['fromEmail'] ?? '—';
    final status = (data['status'] ?? 'open').toString();
    final createdAt = data['createdAt'] as Timestamp?;
    final dateStr = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : '—';
    final adminNote = data['adminNote'] as String?;

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'reviewed':
        statusColor = Colors.orange;
        break;
      case 'resolved':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.blue;
    }

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
                  radius: 18,
                  backgroundColor: fromRole == 'seller'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  child: Icon(
                    fromRole == 'seller' ? Icons.store : Icons.person,
                    size: 18,
                    color: fromRole == 'seller' ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fromName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('$fromEmail • ${fromRole.toUpperCase()}',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(subject,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(message,
                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Text('Date: $dateStr',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            if (adminNote != null && adminNote.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('Admin: $adminNote',
                            style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status != 'reviewed')
                  _actionBtn('Mark Reviewed', Icons.visibility, Colors.orange,
                      () => _updateStatus(docId, 'reviewed')),
                if (status != 'resolved')
                  _actionBtn('Resolve', Icons.check_circle, Colors.green,
                      () => _updateStatus(docId, 'resolved')),
                _actionBtn('Add Note', Icons.edit_note, _navy,
                    () => _addNote(docId)),
                _actionBtn('Warn User', Icons.warning, Colors.orange,
                    () => _warnUser(data)),
                if (data['fromUid'] != null)
                  _actionBtn('Block User', Icons.block, Colors.red,
                      () => _blockUser(data)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 11)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
    );
  }

  Future<void> _updateStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(docId)
          .update({'status': status});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Complaint marked as $status.'),
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

  Future<void> _addNote(String docId) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Admin Note'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter note...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
                backgroundColor: _navy, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (note == null || note.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(docId)
          .update({'adminNote': note});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _warnUser(Map<String, dynamic> data) {
    final name = data['fromName'] ?? 'User';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Warning sent to $name.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _blockUser(Map<String, dynamic> data) async {
    final uid = data['fromUid'] as String?;
    final role = (data['fromRole'] ?? 'user').toString();
    if (uid == null) return;

    final collection =
        role == 'seller' ? 'seller_register' : 'user_register';
    final field = role == 'seller' ? 'isDisabled' : 'isBlocked';

    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(uid)
          .update({field: true});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${data['fromName'] ?? 'User'} has been blocked.'),
              backgroundColor: Colors.red),
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
}
