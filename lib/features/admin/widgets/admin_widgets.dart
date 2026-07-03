import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AdminEmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  const AdminEmptyState({super.key, required this.title, this.message, required this.icon, this.actionLabel, this.onAction});
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 72, color: AppColors.textHint),
    const SizedBox(height: 16),
    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
    if (message != null) ...[const SizedBox(height: 8), Text(message!, style: const TextStyle(color: AppColors.textSecondary), textAlign: TextAlign.center)],
    if (actionLabel != null && onAction != null) ...[const SizedBox(height: 20), ElevatedButton(onPressed: onAction, child: Text(actionLabel!))],
  ])));
}

class AdminPagination extends StatelessWidget {
  final int page, total, limit;
  final VoidCallback onPrev, onNext;
  const AdminPagination({super.key, required this.page, required this.total, required this.limit, required this.onPrev, required this.onNext});
  @override Widget build(BuildContext context) {
    final pages = (total / limit).ceil();
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(children: [
        Text('$total results', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: page > 1 ? onPrev : null, color: AppColors.primary),
        Text('$page / $pages', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: page < pages ? onNext : null, color: AppColors.primary),
      ]),
    );
  }
}

class DeliveryTierBadge extends StatelessWidget {
  final String tier;
  const DeliveryTierBadge({super.key, required this.tier});
  @override Widget build(BuildContext context) => AppUI.tierBadge(tier);
}

