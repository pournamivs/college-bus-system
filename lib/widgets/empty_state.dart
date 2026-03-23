import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({Key? key, required this.message, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 50, color: Colors.grey),
          SizedBox(height: 20),
          Text(message,
              style: TextStyle(fontSize: 20, color: Colors.grey)),
        ],
      ),
    );
  }
}