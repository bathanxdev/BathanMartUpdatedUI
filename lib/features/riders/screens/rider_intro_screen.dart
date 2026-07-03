import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class RiderIntroScreen extends StatelessWidget {
  const RiderIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.delivery_dining,
                      color: Colors.white, size: 48),

                  const SizedBox(height: 20),

                  Text(
                    "Become a Rider",
                    style: AppText.display(
                      color: Colors.white,
                      size: 32,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Earn money by delivering orders in your city with flexible working hours.",
                    style: AppText.body(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () => context.go('/rider-apply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Apply Now"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // BENEFITS SECTION
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildFeature(
                    Icons.monetization_on_outlined,
                    "Earn Weekly Income",
                    "Get paid every week directly to your account.",
                  ),
                  _buildFeature(
                    Icons.schedule,
                    "Flexible Timing",
                    "Work whenever you want — full-time or part-time.",
                  ),
                  _buildFeature(
                    Icons.location_on_outlined,
                    "Local Deliveries",
                    "Deliver within your nearby areas only.",
                  ),
                  _buildFeature(
                    Icons.verified_user_outlined,
                    "Verified Platform",
                    "Safe, secure and trusted delivery ecosystem.",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h3()),
                const SizedBox(height: 4),
                Text(subtitle, style: AppText.body()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}