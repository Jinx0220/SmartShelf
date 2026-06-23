import 'package:flutter/material.dart';
import '../utils/colors.dart';

class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool fullScreen;

  const LoadingIndicator({
    super.key,
    this.message,
    this.fullScreen = true,
  });

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColor.primary,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: AppColor.secondary,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );

    if (fullScreen) {
      return Scaffold(
        backgroundColor: AppColor.background,
        body: child,
      );
    }

    return child;
  }
}