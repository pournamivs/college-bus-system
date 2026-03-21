import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AdminDriversScreen extends StatelessWidget {
  const AdminDriversScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Drivers', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_pin)),
              title: const Text('Rajesh M'),
              subtitle: const Text('License: KL-123456\nAssigned: Route A'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.call, color: AppColors.success),
                onPressed: () {},
              ),
            ),
          );
        },
      ),
    );
  }
}
