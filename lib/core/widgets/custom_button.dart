import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isLoading;
  final Color? backgroundColor;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: backgroundColor != null 
          ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
          : null,
        onPressed: isLoading ? null : onPressed,
        child: isLoading 
            ? const SizedBox(
                width: 24, 
                height: 24, 
                child: CircularProgressIndicator(
                  color: Colors.white, 
                  strokeWidth: 2
                )
              )
            : Text(text),
      ),
    );
  }
}
