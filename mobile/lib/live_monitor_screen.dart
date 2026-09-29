import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class LiveMonitorScreen extends StatelessWidget {
  final String ownerId;
  final bool isVet;
  const LiveMonitorScreen({
    super.key,
    required this.ownerId,
    required this.isVet,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                size: 72,
                color: isVet ? AppColors.vetPrimary : AppColors.userPrimary,
              ),
              const SizedBox(height: 20),
              Text(
                'Canlı İzleme',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isVet ? AppColors.vetPrimary : AppColors.userPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Bu özellik yakında kullanıma açılacak.\nSensör verilerini buradan takip edebileceksiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
