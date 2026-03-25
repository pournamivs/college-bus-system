import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/glass_morphic_card.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final res = await http.get(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/admin/users'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        setState(() => _users = jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteUser(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final res = await http.delete(
        Uri.parse('${ApiConstants.apiBaseUrl}/api/admin/users/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (res.statusCode == 200) {
        _fetchUsers();
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String role = 'student';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: role,
              items: ['admin', 'driver', 'student', 'staff', 'parent']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                  .toList(),
              onChanged: (v) => role = v ?? 'student',
            ),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Username/Email')),
            TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final token = prefs.getString('token');
              final res = await http.post(
                Uri.parse('${ApiConstants.apiBaseUrl}/api/auth/register'),
                headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                body: jsonEncode({
                  'name': nameCtrl.text,
                  'email': emailCtrl.text,
                  'password': passwordCtrl.text,
                  'role': role,
                }),
              );
              if (res.statusCode == 200 || res.statusCode == 201) {
                _fetchUsers();
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddUserDialog),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _users.length,
            itemBuilder: (ctx, i) {
              final u = _users[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(u['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${u['email']} | Role: ${u['role']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: AppColors.error),
                    onPressed: () => _deleteUser(u['id']),
                  ),
                ),
              );
            },
          ),
    );
  }
}
