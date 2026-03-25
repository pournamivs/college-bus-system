import 'package:flutter/material.dart';

class CustomGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const CustomGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<CustomGradientButton> createState() => _CustomGradientButtonState();
}

class _CustomGradientButtonState extends State<CustomGradientButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: widget.isLoading ? null : widget.onPressed,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.purple, Colors.deepPurple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: widget.isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: const CircularProgressIndicator(color: Colors.white),
              )
            : Text(
                widget.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}