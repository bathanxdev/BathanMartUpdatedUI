import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminRolesScreen extends StatefulWidget {
  const AdminRolesScreen({super.key});
  @override State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}
class _AdminRolesScreenState extends State<AdminRolesScreen> {
  List<dynamic> _roles = [], _permissions = [];
  List<String>  _presets = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r1 = await ApiClient.instance.get('/admin/roles');
      final r2 = await ApiClient.instance.get('/admin/roles/permissions');
      setState(() {
        _roles       = (r1['data'] as List?) ?? [];
        _permissions = (r2['data']?['permissions'] as List?) ?? [];
        _presets     = ((r2['data']?['presets'] as List?) ?? []).cast<String>();
        _loading     = false;
      });
    } catch (e) { setState(() => _loading = false); }
  }

  void _showCreateFromPreset() {
    String? preset; final nameCtrl = TextEditingController(); final dispCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: const Text('Create Role from Template'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        DropdownButtonFormField<String>(value: preset, decoration: const InputDecoration(labelText: 'Select Template *'),
          items: _presets.map((p) => DropdownMenuItem(value: p, child: Text(p.replaceAll('_', ' ').toUpperCase()))).toList(),
          onChanged: (v) { setS(() => preset = v); dispCtrl.text = v?.replaceAll('_', ' ') ?? ''; }),
        const SizedBox(height: 10),
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Role key name (no spaces) *')),
        const SizedBox(height: 10),
        TextField(controller: dispCtrl, decoration: const InputDecoration(labelText: 'Display name *')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          if (preset == null || nameCtrl.text.isEmpty) return;
          try {
            await ApiClient.instance.post('/admin/roles/from-preset', data: {'preset_name': preset, 'name': nameCtrl.text.trim(), 'display_name': dispCtrl.text.trim()});
            Navigator.pop(ctx); _load();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role created from template'), backgroundColor: AppColors.success));
          } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error)); }
        }, child: const Text('Create')),
      ],
    )));
  }

  void _showRoleDetail(Map role) {
    final perms = (role['permissions'] as List?) ?? [];
    final grouped = <String, List<String>>{};
    for (final p in perms) { final parts = p.toString().split(':'); final res = parts[0]; grouped.putIfAbsent(res, () => []).add(parts.length > 1 ? parts[1] : p.toString()); }
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(role['display_name']?.toString() ?? ''),
      content: SizedBox(width: 440, height: 400, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (role['description'] != null) ...[Text(role['description'].toString(), style: const TextStyle(color: AppColors.textSecondary)), const SizedBox(height: 16)],
        Text('${perms.length} permissions assigned', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...grouped.entries.map((e) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.key.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: e.value.map((a) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.success.withAlpha(20), borderRadius: BorderRadius.circular(10)),
            child: Text(a, style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
          )).toList()),
          const SizedBox(height: 10),
        ])),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  }

  void _deleteRole(Map role) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text("Delete Role"),
      content: Text("Delete role `${role['display_name']}`? This cannot be undone."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), onPressed: () async {
          Navigator.pop(context);
          try {
            await ApiClient.instance.delete("/admin/roles/${role['_id']}");
            _load();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Role deleted"), backgroundColor: AppColors.success));
          } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error)); }
        }, child: const Text('Delete')),
      ],
    ));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Role Management'), actions: [
      IconButton(icon: const Icon(Icons.add), tooltip: 'Create from Template', onPressed: _showCreateFromPreset),
      IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
    ]),
    body: _loading ? const Center(child: CircularProgressIndicator()) : _roles.isEmpty
      ? AdminEmptyState(title: 'No roles', icon: Icons.manage_accounts_outlined, actionLabel: 'Create from Template', onAction: _showCreateFromPreset)
      : ListView.separated(padding: const EdgeInsets.all(12),
          itemCount: _roles.length, separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final r      = _roles[i] as Map;
            final perms  = (r['permissions'] as List?)?.length ?? 0;
            final isSystem = r['is_system_role'] as bool? ?? false;
            final isActive = r['is_active'] as bool? ?? true;
            return Card(child: Padding(padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(r['display_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(width: 8),
                    if (isSystem) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.warning.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                      child: const Text('SYSTEM', style: TextStyle(fontSize: 9, color: AppColors.warning, fontWeight: FontWeight.w700))),
                  ]),
                  Text(r['name']?.toString() ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: isActive ? AppColors.success.withAlpha(20) : AppColors.error.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                  child: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(color: isActive ? AppColors.success : AppColors.error, fontSize: 11, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 8),
              if (r['description'] != null) Text(r['description'].toString(), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.primary.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                  child: Text('$perms permissions', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600))),
                const Spacer(),
                TextButton.icon(icon: const Icon(Icons.visibility_outlined, size: 16), label: const Text('View', style: TextStyle(fontSize: 12)), onPressed: () => _showRoleDetail(r)),
                if (!isSystem) ...[
                  const SizedBox(width: 4),
                  TextButton.icon(icon: const Icon(Icons.delete_outlined, size: 16, color: AppColors.error), label: const Text('Delete', style: TextStyle(fontSize: 12, color: AppColors.error)), onPressed: () => _deleteRole(r)),
                ],
              ]),
            ])));
          },
        ),
  );
}
