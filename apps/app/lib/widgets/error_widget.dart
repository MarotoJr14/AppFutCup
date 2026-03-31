import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding : EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 48),
            SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: AppColors.onSurface)),
            if (onRetry != null) ...[
              SizedBox(height: 12),
              ElevatedButton(onPressed: onRetry, child: Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }
}
