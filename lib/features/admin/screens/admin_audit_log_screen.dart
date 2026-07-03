import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});
  @override State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}
class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  List<dynamic> _logs = [], _summary = [];
  Map _summaryData = {};
  bool _loading = true;
  int _page = 1, _total = 0;
  String? _actionFilter, _resourceFilter, _statusFilter;
  final _searchCtrl = TextEditingController();

  @override void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); _load(); _loadSummary(); }
  @override void dispose()   { _tab.dispose(); _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = <String, dynamic>{'page': _page, 'limit': 50};
      if (_searchCtrl.text.isNotEmpty) p['search']        = _searchCtrl.text;
      if (_actionFilter   != null)     p['action']        = _actionFilter;
      if (_resourceFilter != null)     p['resource_type'] = _resourceFilter;
      if (_statusFilter   != null)     p['status']        = _statusFilter;
      final r = await ApiClient.instance.get('/admin/audit-logs', params: p);
      setState(() { _logs = (r['data'] as List?) ?? []; _total = r['meta']?['total'] ?? 0; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  Future<void> _loadSummary() async {
    try { final r = await ApiClient.instance.get('/admin/audit-logs/summary'); setState(() => _summaryData = (r['data'] as Map?) ?? {}); }
    catch (_) {}
  }

  Color _actionColor(String action) {
    if (action.contains('create'))   return AppColors.success;
    if (action.contains('delete') || action.contains('deactivate')) return AppColors.error;
    if (action.contains('update') || action.contains('edit') || action.contains('assign')) return AppColors.warning;
    if (action.contains('login') || action.contains('auth')) return AppColors.info;
    return AppColors.textSecondary;
  }

  IconData _actionIcon(String action) {
    if (action.contains('create'))   return Icons.add_circle_outline;
    if (action.contains('delete') || action.contains('deactivate')) return Icons.remove_circle_outline;
    if (action.contains('update') || action.contains('edit')) return Icons.edit_outlined;
    if (action.contains('login'))    return Icons.login;
    if (action.contains('view'))     return Icons.visibility_outlined;
    return Icons.history;
  }

  void _showLogDetail(Map log) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(log['action']?.toString() ?? 'Log Detail'),
      content: SizedBox(width: 480, height: 400, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _logRow('Actor',    "${log['actor_name'] ?? 'System'} (${log['actor_email'] ?? 'N/A'})"),
        _logRow('Role',     log['actor_role']?.toString() ?? ''),
        _logRow('IP',       log['actor_ip']?.toString() ?? ''),
        _logRow("Resource", "${log["resource_type"]} — ${log["resource_name"] ?? log['resource_id'] ?? ''}"),
        _logRow('Status',   log['status']?.toString() ?? 'success'),
        _logRow('Time',     log['createdAt'] != null ? DateFormat('dd MMM yyyy HH:mm:ss').format(DateTime.parse(log['createdAt'].toString())) : ''),
        if (log['notes'] != null) _logRow('Notes', log['notes'].toString()),
        if (log['error_message'] != null) _logRow('Error', log['error_message'].toString()),
        const SizedBox(height: 12),
        const Text('Changes:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        if (log['changes']?['before'] != null && (log['changes']['before'] as Map).isNotEmpty) ...[
          const Text('Before:', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600)),
          Container(padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(top: 4, bottom: 8),
            decoration: BoxDecoration(color: AppColors.error.withAlpha(10), borderRadius: BorderRadius.circular(8)),
            child: Text(log['changes']['before'].toString(), style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
        ],
        if (log['changes']?['after'] != null && (log['changes']['after'] as Map).isNotEmpty) ...[
          const Text('After:', style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
          Container(padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: AppColors.success.withAlpha(10), borderRadius: BorderRadius.circular(8)),
            child: Text(log['changes']['after'].toString(), style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
        ],
        if ((log['changes']?['before'] == null || (log['changes']['before'] as Map).isEmpty) && (log['changes']?['after'] == null || (log['changes']['after'] as Map).isEmpty))
          const Text('No field changes recorded.', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
    ));
  }

  Widget _logRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
    ]));

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Audit Logs'),
      actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () { _load(); _loadSummary(); })],
      bottom: TabBar(controller: _tab, indicatorColor: Colors.white, tabs: const [Tab(text: 'Activity Log'), Tab(text: 'Summary')]),
    ),
    body: TabBarView(controller: _tab, children: [
      // ── Activity Log ─────────────────────────────────────────
      Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: Column(children: [
          TextField(controller: _searchCtrl,
            decoration: InputDecoration(hintText: 'Search logs...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () { setState(()=>_page=1); _load(); })),
            onSubmitted: (_) { setState(()=>_page=1); _load(); },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
            _chip('All', null, null, null),
            const SizedBox(width: 8), _chip('Creates', 'create', null, null),
            const SizedBox(width: 8), _chip('Updates', 'update', null, null),
            const SizedBox(width: 8), _chip('Deletes', 'delete', null, null),
            const SizedBox(width: 8), _chip('Logins', 'login', null, null),
            const SizedBox(width: 8), _chip('Failed', null, null, 'failed'),
          ])),
        ])),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _logs.isEmpty
          ? const AdminEmptyState(title: 'No logs found', icon: Icons.history_outlined)
          : ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _logs.length, separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final log    = _logs[i] as Map;
                final action = log['action']?.toString() ?? '';
                final col    = _actionColor(action);
                final status = log['status']?.toString() ?? 'success';
                final dt     = log['createdAt'] != null ? DateTime.tryParse(log['createdAt'].toString()) : null;
                return GestureDetector(
                  onTap: () => _showLogDetail(log),
                  child: Container(padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: status == 'failed' ? AppColors.error.withAlpha(80) : AppColors.border)),
                    child: Row(children: [
                      Container(width: 36, height: 36, decoration: BoxDecoration(color: col.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                        child: Icon(_actionIcon(action), color: col, size: 18)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(action, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: col)),
                        Text("${log['resource_type'] ?? ""} ${log['resource_name'] != null ? "— ${log['resource_name']}" : ''}", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text("by ${log['actor_name'] ?? "System"}  •  ${log["actor_ip"] ?? ''}", style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        if (dt != null) Text(DateFormat('HH:mm:ss').format(dt), style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                        if (dt != null) Text(DateFormat('dd MMM').format(dt), style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
                        if (status == 'failed') const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                      ]),
                    ]),
                  ),
                );
              },
            ),
        ),
        AdminPagination(page: _page, total: _total, limit: 50,
          onPrev: () { if (_page > 1) { setState(()=>_page--); _load(); } },
          onNext: () { if (_page * 50 < _total) { setState(()=>_page++); _load(); } },
        ),
      ]),

      // ── Summary Tab ──────────────────────────────────────────
      SingleChildScrollView(padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Recent Activity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...((_summaryData['recent_activity'] as List?) ?? []).map((log) {
          final l = log as Map; final action = l['action']?.toString() ?? ''; final col = _actionColor(action);
          final dt = l['createdAt'] != null ? DateTime.tryParse(l['createdAt'].toString()) : null;
          return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Icon(_actionIcon(action), color: col, size: 18), const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(action, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: col)),
                Text("${l['actor_name'] ?? 'System'}  •  ${l['resource_type'] ?? ''}", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              if (dt != null) Text(DateFormat('dd MMM HH:mm').format(dt), style: const TextStyle(fontSize: 10, color: AppColors.textHint)),
            ]));
        }),
        const SizedBox(height: 20),
        const Text('Top Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...((_summaryData['by_action'] as List?) ?? []).take(10).map((a) {
          final action = (a as Map)['_id']?.toString() ?? ''; final count = a['count'] ?? 0; final col = _actionColor(action);
          return Container(margin: const EdgeInsets.only(bottom: 6), padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Icon(_actionIcon(action), color: col, size: 16), const SizedBox(width: 10),
              Expanded(child: Text(action, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: col))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: col.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: Text('$count', style: TextStyle(color: col, fontWeight: FontWeight.w700, fontSize: 13))),
            ]));
        }),
      ])),
    ]),
  );

  Widget _chip(String label, String? action, String? resource, String? status) => ChoiceChip(
    label: Text(label, style: const TextStyle(fontSize: 12)),
    selected: _actionFilter == action && _resourceFilter == resource && _statusFilter == status,
    onSelected: (_) { setState(() { _actionFilter = action; _resourceFilter = resource; _statusFilter = status; _page = 1; }); _load(); },
  );
}
