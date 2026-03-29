import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _busController = TextEditingController();
  String _role = 'driver';
  bool _isLoading = false;
  String? _message;

  Future<void> _addUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _message = null; });
    try {
      await FirebaseFirestore.instance.collection('users').doc(_phoneController.text.trim()).set({
        'role': _role,
        if (_role == 'driver') 'bus_id': _busController.text.trim(),
      });
      setState(() { _message = 'User added successfully!'; });
      _phoneController.clear();
      _busController.clear();
    } catch (e) {
      setState(() { _message = 'Error: $e'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Widget _buildUserForm() {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add User', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Enter phone number' : null,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'driver', child: Text('Driver')),
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                ],
                onChanged: (val) => setState(() => _role = val ?? 'driver'),
              ),
              if (_role == 'driver') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _busController,
                  decoration: const InputDecoration(
                    labelText: 'Bus ID',
                    prefixIcon: Icon(Icons.directions_bus),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => _role == 'driver' && (v == null || v.isEmpty) ? 'Enter bus ID' : null,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                label: const Text('Save User'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: _isLoading ? null : _addUser,
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(_message!, style: TextStyle(color: _message!.startsWith('Error') ? Colors.red : Colors.green)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Add Driver'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () => setState(() { _role = 'driver'; }),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add Student'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => setState(() { _role = 'student'; }),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.directions_bus),
            label: const Text('Assign Bus'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {}, // Implement as needed
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.list),
            label: const Text('View Buses'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () {}, // Implement as needed
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          _buildActionButtons(),
          _buildUserForm(),
        ],
      ),
    );
  }
}
