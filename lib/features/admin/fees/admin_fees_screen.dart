import 'package:flutter/material.dart';
import 'package:track_my_bus/core/constants/app_colors.dart';
import '../../../core/widgets/status_chip.dart';

class AdminFeesScreen extends StatelessWidget {
  const AdminFeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Fee Management', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Collected'),
              Tab(text: 'All'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: const Text('Rahul Kumar'),
                    subtitle: const Text('Sem 5 Fee • Due: 15 Oct\nRoute A'),
                    isThreeLine: true,
                    trailing: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹12,500', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        StatusChip(label: 'Overdue'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Center(child: Text('Collected Fees')),
            const Center(child: Text('All Fees')),
          ],
        ),
      ),
    );
  }
}
