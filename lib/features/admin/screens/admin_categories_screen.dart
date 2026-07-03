import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});
  @override State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const AdminLoadCategoriesEvent());
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => BlocProvider.value(
        value: context.read<AdminBloc>(),
        child: AlertDialog(
          title: const Text('Add Category'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Category Name *'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                context.read<AdminBloc>().add(AdminCreateCategoryEvent({
                  'name':        nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                }));
                Navigator.pop(dialogCtx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Categories'),
      actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
      ],
    ),
    body: BlocConsumer<AdminBloc, AdminState>(
      listener: (ctx, state) {
        if (state is AdminSuccessState) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
          );
          ctx.read<AdminBloc>().add(const AdminLoadCategoriesEvent());
        }
        if (state is AdminErrorState) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
          );
        }
      },
      builder: (ctx, state) {
        if (state is AdminLoadingState) return const Center(child: CircularProgressIndicator());
        if (state is! AdminCategoriesLoaded || state.categories.isEmpty) {
          return AdminEmptyState(
            title: 'No categories',
            icon: Icons.category_outlined,
            actionLabel: 'Add Category',
            onAction: _showAddDialog,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: state.categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final c = state.categories[i] as Map;
            // Extract values to variables — avoids map key access inside strings
            final catName      = c['name']?.toString() ?? '';
            final productCount = c['product_count']?.toString() ?? '0';
            final sortOrder    = c['sort_order']?.toString() ?? '0';

            return Card(child: ListTile(
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.category_outlined, color: AppColors.primary, size: 22),
              ),
              title: Text(catName, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '$productCount products  •  Sort: $sortOrder',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Active',
                    style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ));
          },
        );
      },
    ),
  );
}
