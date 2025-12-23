import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddressSection extends StatefulWidget {
  const AddressSection({super.key});

  @override
  State<AddressSection> createState() => _AddressSectionState();
}

class _AddressSectionState extends State<AddressSection> {
  String _savedAddress = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedAddress = prefs.getString('user_address') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_address', address);
    setState(() {
      _savedAddress = address;
    });
  }

  void _showAddAddressDialog() {
    final TextEditingController addressController = TextEditingController();
    addressController.text = _savedAddress;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Add Address',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: addressController,
          decoration: InputDecoration(
            labelText: 'Enter your address',
            hintText: 'House number, street, area, city...',
            prefixIcon: const Icon(Icons.location_on, color: Color(0xFF1E3A8A)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (addressController.text.trim().isNotEmpty) {
                _saveAddress(addressController.text.trim());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Address saved successfully'),
                    backgroundColor: Color(0xFF1E3A8A),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Color(0xFF1E3A8A),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _showAddAddressDialog,
                icon: const Icon(
                  Icons.add,
                  color: Color(0xFF1E3A8A),
                  size: 18,
                ),
                label: const Text(
                  'Add',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
              ),
            )
          else if (_savedAddress.isEmpty)
            const Text(
              'No address added yet. Tap "Add" to add your address.',
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.home,
                    color: Color(0xFF1E3A8A),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _savedAddress,
                      style: const TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showAddAddressDialog,
                    icon: const Icon(
                      Icons.edit,
                      color: Color(0xFF1E3A8A),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
