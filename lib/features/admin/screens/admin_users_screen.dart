import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}
class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [], _roles = [];
  bool _loading = true;
  String? _roleFilter, _statusFilter;
  int _page = 1;
  int _total = 0;
  final _searchCtrl = TextEditingController();

  @override void initState() { super.initState(); _load(); _loadRoles(); }
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = <String, dynamic>{'page': _page, 'limit': 20};
      if (_searchCtrl.text.isNotEmpty) p['search']  = _searchCtrl.text;
      if (_roleFilter   != null)       p['role']    = _roleFilter;
      if (_statusFilter != null)       p['status']  = _statusFilter;
      final r = await ApiClient.instance.get('/admin/users', params: p);
      setState(() { _users = (r['data'] as List?) ?? []; _total = r['meta']?['total'] ?? 0; _loading = false; });
    } catch (e) { setState(() => _loading = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error)); }
  }

  Future<void> _loadRoles() async {
    try { final r = await ApiClient.instance.get('/admin/roles'); setState(() => _roles = (r['data'] as List?) ?? []); }
    catch (_) {}
  }

  Color _statusColor(String s) => s == 'active' ? AppColors.success : AppColors.error;
  Color _roleColor(String r) {
    switch (r) { case 'admin': return AppColors.error; case 'operations': return AppColors.warning; case 'warehouse': return AppColors.info; case 'rider': return AppColors.secondary; default: return AppColors.primary; }
  }

  void _showUserDialog({Map? user}) {
    showDialog(context: context, builder: (_) => _UserFormDialog(user: user, roles: _roles, onSaved: _load));
  }

  void _showAssignRoleDialog(Map user) {
    String? selectedRole = user['assigned_role']?["_id"]?.toString();
    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      title: Text("Assign Role to ${user['name']}"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("Select a role to assign:", style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        DropdownButton<String>(
          value: selectedRole, isExpanded: true, hint: const Text('Select role'),
          items: _roles.map((r) => DropdownMenuItem<String>(value: r['_id']?.toString(), child: Text(r['display_name']?.toString() ?? ''))).toList(),
          onChanged: (v) => setS(() => selectedRole = v),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        ElevatedButton(onPressed: () async {
          if (selectedRole == null) return;
          try {
            await ApiClient.instance.post("/admin/users/${user['_id']}/assign-role", data: {"role_id": selectedRole});
            Navigator.pop(ctx);
            _load();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role assigned'), backgroundColor: AppColors.success));
          } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error)); }
        }, child: const Text('Assign')),
      ],
    )));
  }

  void _deactivateUser(Map user) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text("Deactivate User"),
      content: Text("Deactivate ${user['name']}? They will no longer be able to login."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), onPressed: () async {
          Navigator.pop(context);
          try {
            await ApiClient.instance.patch("/admin/users/${user['_id']}/deactivate");
            _load();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deactivated"), backgroundColor: AppColors.success));
          } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error)); }
        }, child: const Text('Deactivate')),
      ],
    ));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('User Management'), actions: [
      IconButton(icon: const Icon(Icons.person_add_outlined), onPressed: () => _showUserDialog()),
    ]),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        TextField(controller: _searchCtrl,
          decoration: InputDecoration(hintText: 'Search by name, email or phone...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () { setState(()=>_page=1); _load(); })),
          onSubmitted: (_) { setState(()=>_page=1); _load(); },
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _chip('All Roles',   null,         null),
          const SizedBox(width: 8),
          _chip('Customer',    'customer',   null),
          const SizedBox(width: 8),
          _chip('Operations',  'operations', null),
          const SizedBox(width: 8),
          _chip('Warehouse',   'warehouse',  null),
          const SizedBox(width: 8),
          _chip('Rider',       'rider',      null),
          const SizedBox(width: 16),
          _chip('Active',      null,         'active'),
          const SizedBox(width: 8),
          _chip('Inactive',    null,         'inactive'),
        ])),
      ])),
      Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _users.isEmpty
        ? const AdminEmptyState(title: 'No users found', icon: Icons.people_outline)
        : ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _users.length, separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final u      = _users[i] as Map;
              final role   = u['role']?.toString() ?? 'customer';
              final status = u['status']?.toString() ?? 'active';
              final aRole  = u['assigned_role'] as Map?;
              return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 20, backgroundColor: _roleColor(role).withAlpha(25),
                    child: Text((u['name']?.toString() ?? '?').substring(0,1).toUpperCase(), style: TextStyle(color: _roleColor(role), fontWeight: FontWeight.w700))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(u['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(u['email']?.toString() ?? u['phone']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ])),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _statusColor(status).withAlpha(25), borderRadius: BorderRadius.circular(12)),
                    child: Text(status.toUpperCase(), style: TextStyle(color: _statusColor(status), fontSize: 10, fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _roleColor(role).withAlpha(15), borderRadius: BorderRadius.circular(8)),
                    child: Text(role.toUpperCase(), style: TextStyle(color: _roleColor(role), fontSize: 11, fontWeight: FontWeight.w600))),
                  const SizedBox(width: 8),
                  if (aRole != null) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.info.withAlpha(15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.info.withAlpha(50))),
                    child: Text(aRole['display_name']?.toString() ?? '', style: const TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.w600))),
                  const Spacer(),
                  PopupMenuButton<String>(onSelected: (val) {
                    if (val == 'edit')       _showUserDialog(user: u);
                    if (val == 'role')       _showAssignRoleDialog(u);
                    if (val == 'deactivate') _deactivateUser(u);
                  }, itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit',       child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit User')])),
                    PopupMenuItem(value: 'role',       child: Row(children: [Icon(Icons.manage_accounts_outlined, size: 16), SizedBox(width: 8), Text('Assign Role')])),
                    PopupMenuItem(value: 'deactivate', child: Row(children: [Icon(Icons.block_outlined, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Deactivate', style: TextStyle(color: AppColors.error))])),
                  ]),
                ]),
              ])));
            },
          ),
      ),
      AdminPagination(page: _page, total: _total, limit: 20,
        onPrev: () { if (_page > 1) { setState(()=>_page--); _load(); } },
        onNext: () { if (_page * 20 < _total) { setState(()=>_page++); _load(); } },
      ),
    ]),
  );

  Widget _chip(String label, String? roleVal, String? statusVal) => ChoiceChip(
    label: Text(label, style: const TextStyle(fontSize: 12)),
    selected: _roleFilter == roleVal && _statusFilter == statusVal,
    onSelected: (_) { setState(() { _roleFilter = roleVal; _statusFilter = statusVal; _page = 1; }); _load(); },
  );
}

class _UserFormDialog extends StatefulWidget {
  final Map? user; final List roles; final VoidCallback onSaved;
  const _UserFormDialog({this.user, required this.roles, required this.onSaved});
  @override State<_UserFormDialog> createState() => _UserFormDialogState();
}
class _UserFormDialogState extends State<_UserFormDialog> {
  final _fk = GlobalKey<FormState>();
  late final TextEditingController _name, _email, _phone, _pass;
  String _role = 'customer', _status = 'active';
  String? _assignedRole;
  bool _loading = false;

  @override void initState() {
    super.initState();
    final u = widget.user;
    _name   = TextEditingController(text: u?['name']?.toString() ?? '');
    _email  = TextEditingController(text: u?['email']?.toString() ?? '');
    _phone  = TextEditingController(text: u?['phone']?.toString() ?? '');
    _pass   = TextEditingController();
    _role   = u?['role']?.toString() ?? 'customer';
    _status = u?['status']?.toString() ?? 'active';
    _assignedRole = (u?['assigned_role'] is Map ? u!['assigned_role']['_id'] : u?['assigned_role'])?.toString();
  }
  @override void dispose() { for (final c in [_name,_email,_phone,_pass]) c.dispose(); super.dispose(); }

  void _save() async {
    if (!_fk.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = {'name':_name.text,'email':_email.text,'phone':_phone.text.isEmpty?null:_phone.text,'role':_role,'status':_status,'assigned_role_id':_assignedRole};
      if (widget.user == null) { data['password'] = _pass.text; await ApiClient.instance.post("/admin/users", data: data); }
      else                     await ApiClient.instance.put("/admin/users/${widget.user!['_id']}", data: data);
      Navigator.pop(context); widget.onSaved();
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error)); }
    setState(() => _loading = false);
  }

  @override Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.user == null ? "Add User" : 'Edit User'),
    content: SizedBox(width: 440, child: Form(key: _fk, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextFormField(controller: _name,  decoration: const InputDecoration(labelText: 'Full Name *'), validator: (v) => v!.isEmpty ? 'Required' : null),
      const SizedBox(height: 10),
      TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email *'), keyboardType: TextInputType.emailAddress, validator: (v) => !v!.contains('@') ? 'Valid email required' : null),
      const SizedBox(height: 10),
      TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone (optional)')),
      const SizedBox(height: 10),
      if (widget.user == null) TextFormField(controller: _pass, decoration: const InputDecoration(labelText: 'Password *'), obscureText: true, validator: (v) => (v?.length ?? 0) < 8 ? 'Min 8 chars' : null),
      if (widget.user == null) const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: _role, decoration: const InputDecoration(labelText: 'System Role'),
        items: ['customer','operations','warehouse','rider','sourcing','b2b'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
        onChanged: (v) => setState(() => _role = v!)),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: _status, decoration: const InputDecoration(labelText: 'Status'),
        items: const [DropdownMenuItem(value: 'active', child: Text('Active')), DropdownMenuItem(value: 'inactive', child: Text('Inactive'))],
        onChanged: (v) => setState(() => _status = v!)),
      if (widget.roles.isNotEmpty) ...[
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(value: _assignedRole, decoration: const InputDecoration(labelText: 'Assign Role (optional)'),
          items: [const DropdownMenuItem(value: null, child: Text('No role assigned')), ...widget.roles.map((r) => DropdownMenuItem<String>(value: r['_id']?.toString(), child: Text(r['display_name']?.toString() ?? '')))],
          onChanged: (v) => setState(() => _assignedRole = v)),
      ],
    ])))),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(onPressed: _loading ? null : _save, child: Text(widget.user == null ? 'Create User' : 'Save Changes')),
    ],
  );
}
