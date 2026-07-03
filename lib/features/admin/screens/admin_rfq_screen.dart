import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminRFQScreen extends StatefulWidget {
  const AdminRFQScreen({super.key});
  @override State<AdminRFQScreen> createState() => _AdminRFQScreenState();
}
class _AdminRFQScreenState extends State<AdminRFQScreen> {
  String? _statusFilter;

  @override void initState() { super.initState(); _load(); }
  void _load() => context.read<AdminBloc>().add(AdminLoadRFQsEvent(status: _statusFilter));

  static const _statusColors = {
    'draft':'draft','sent':'sent','quotation_received':'quotation_received',
    'accepted':'accepted','cancelled':'cancelled',
  };

  Color _statusColor(String s) {
    switch(s){
      case 'draft': return AppColors.textHint;
      case 'sent': return AppColors.info;
      case 'quotation_received': return AppColors.warning;
      case 'accepted': return AppColors.success;
      case 'cancelled': return AppColors.error;
      default: return AppColors.textHint;
    }
  }

  String _statusLabel(String s) {
    switch(s){
      case 'quotation_received': return 'Quote Received';
      default: return s.replaceAll('_',' ').split(' ').map((w)=>w.isEmpty?w:'${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    }
  }

  void _showForm({Map? rfq}) {
    showDialog(context: context, barrierDismissible: false, builder: (_) => BlocProvider.value(
      value: context.read<AdminBloc>(),
      child: _RFQForm(rfq: rfq, onSaved: _load),
    ));
  }

  void _confirmDelete(BuildContext ctx, String id) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Delete RFQ'),
      content: const Text('Only draft RFQs can be deleted. Continue?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); ctx.read<AdminBloc>().add(AdminDeleteRFQEvent(id)); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Delete')),
      ],
    ));
  }

  void _confirmSendEmail(BuildContext ctx, String id, String rfqNo, String email) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Send RFQ Email'),
      content: Text('Send RFQ $rfqNo to $email?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); ctx.read<AdminBloc>().add(AdminSendRFQEmailEvent(id)); },
          child: const Text('Send Email')),
      ],
    ));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Request for Quotation'),
      actions: [
        IconButton(icon: const Icon(Icons.add), tooltip: 'Create RFQ', onPressed: () => _showForm()),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ],
    ),
    body: Column(children: [
      // Status filter chips
      SingleChildScrollView(scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal:16,vertical:10),
        child: Row(children: [
          _sChip('All', null),
          ..._statusColors.keys.map((s) => Padding(padding: const EdgeInsets.only(left:8), child: _sChip(_statusLabel(s), s))),
        ])),
      Expanded(child: BlocConsumer<AdminBloc, AdminState>(
        listener: (ctx, state) {
          if (state is AdminSuccessState) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success)); _load(); }
          if (state is AdminErrorState)   { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error)); }
        },
        builder: (ctx, state) {
          if (state is AdminLoadingState) return const Center(child: CircularProgressIndicator());
          if (state is! AdminRFQsLoaded || state.rfqs.isEmpty)
            return AdminEmptyState(title: 'No RFQs found', icon: Icons.request_quote_outlined, actionLabel: 'Create RFQ', onAction: () => _showForm());
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical:8),
            itemCount: state.rfqs.length, separatorBuilder: (_, __) => const SizedBox(height:10),
            itemBuilder: (_, i) {
              final r = state.rfqs[i] as Map;
              final status = r['status']?.toString() ?? 'draft';
              final sc     = _statusColor(status);
              final sup    = r['supplier_id'] as Map?;
              final items  = (r['items'] as List?) ?? [];
              return Container(padding: const EdgeInsets.all(16), decoration: AppUI.cardDecoration(elevated: true),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r['rfq_no']?.toString() ?? '', style: AppText.h3(color: AppColors.primary)),
                      Text(sup?['name']?.toString() ?? 'Supplier', style: AppText.bodyMd()),
                      Text(sup?['email']?.toString() ?? '', style: AppText.caption()),
                    ])),
                    AppUI.badge(_statusLabel(status), sc),
                    const SizedBox(width:8),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v=='edit') _showForm(rfq: r);
                        if (v=='delete') _confirmDelete(ctx, r['_id']?.toString()??'');
                        if (v=='email') _confirmSendEmail(ctx, r['_id']?.toString()??'', r['rfq_no']?.toString()??'', r['supplier_email']?.toString()??'');
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value:'edit', child:Row(children:[Icon(Icons.edit_outlined,size:16),SizedBox(width:8),Text('Edit')])),
                        const PopupMenuItem(value:'email', child:Row(children:[Icon(Icons.email_outlined,size:16,color:AppColors.info),SizedBox(width:8),Text('Send RFQ Email',style:TextStyle(color:AppColors.info))])),
                        const PopupMenuItem(value:'delete', child:Row(children:[Icon(Icons.delete_outline,size:16,color:AppColors.error),SizedBox(width:8),Text('Delete',style:TextStyle(color:AppColors.error))])),
                      ]),
                  ]),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height:10),
                    const Divider(),
                    const SizedBox(height:6),
                    ...items.take(3).map((item) {
                      final im = item as Map;
                      return Padding(padding: const EdgeInsets.only(bottom:4),
                        child: Row(children:[
                          const Icon(Icons.circle, size:6, color:AppColors.textHint),
                          const SizedBox(width:8),
                          Expanded(child:Text('${im['product_name']??'Product'} — ${im['qty']??0} ${im['unit']??'pc'}', style:AppText.caption())),
                          if (im['quoted_price']!=null) Text('Rs.${im['quoted_price']}', style:AppText.caption(color:AppColors.success)),
                        ]));
                    }),
                    if (items.length > 3) Text('+ ${items.length-3} more items', style: AppText.caption(color: AppColors.textHint)),
                  ],
                  if (r['rfq_sent_at']!=null) Padding(padding:const EdgeInsets.only(top:8),
                    child:Text('Sent: ${_fmtDate(r['rfq_sent_at'])}', style:AppText.caption())),
                  if (r['quotation_received_at']!=null) Text('Quote received: ${_fmtDate(r['quotation_received_at'])}', style:AppText.caption(color:AppColors.success)),
                ]));
            });
        },
      )),
    ]),
  );

  Widget _sChip(String label, String? val) => FilterChip(
    label: Text(label, style: const TextStyle(fontSize: 12)),
    selected: _statusFilter == val,
    onSelected: (_) { setState(() => _statusFilter = val); _load(); },
    selectedColor: AppColors.primary.withAlpha(20),
    checkmarkColor: AppColors.primary);

  String _fmtDate(dynamic dt) {
    try { return DateTime.parse(dt.toString()).toLocal().toString().substring(0,16); }
    catch(_) { return dt?.toString()??''; }
  }
}

class _RFQForm extends StatefulWidget {
  final Map? rfq; final VoidCallback onSaved;
  const _RFQForm({this.rfq, required this.onSaved});
  @override State<_RFQForm> createState() => _RFQFormState();
}
class _RFQFormState extends State<_RFQForm> {
  final _fk = GlobalKey<FormState>();
  late final TextEditingController _supEmail, _instructions, _notes, _intNotes;

  // Edit mode (existing RFQ) — single supplier, unchanged behaviour.
  String? _supplierId;

  // Create mode (new RFQ) — multiple suppliers, fan-out on save.
  List<String> _supplierIds = [];
  bool _saving = false;

  String? _status;
  DateTime? _delivDate;
  List<dynamic> _suppliers=[], _products=[];
  List<Map<String,dynamic>> _items=[];

  bool get _isEdit => widget.rfq != null;

  @override void initState() {
    super.initState();
    final r = widget.rfq;
    final sup = r?['supplier_id'] as Map?;
    _supplierId  = sup?['_id']?.toString() ?? r?['supplier_id']?.toString();
    _supEmail    = TextEditingController(text:r?['supplier_email']?.toString()??'');
    _instructions= TextEditingController(text:r?['special_instructions']?.toString()??'');
    _notes       = TextEditingController(text:r?['supplier_notes']?.toString()??'');
    _intNotes    = TextEditingController(text:r?['internal_notes']?.toString()??'');
    _status      = r?['status']?.toString()??'draft';
    if (r?['expected_delivery_date']!=null) { try { _delivDate=DateTime.parse(r!['expected_delivery_date'].toString()); } catch(_) {} }
    _items = ((r?['items'] as List?)??[]).map((i)=>Map<String,dynamic>.from(i as Map)).toList();
    if (_items.isEmpty) _items.add({'product_name':'','qty':1,'unit':'piece','notes':'','quoted_price':null});
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final r1 = await ApiClient.instance.get('/suppliers');
      final r2 = await ApiClient.instance.get('/products', params: {'limit':'100','status':'active'});
      if (mounted) setState(() { _suppliers=(r1['data'] as List?)??[]; _products=(r2['data'] as List?)??[]; });
    } catch(_) {}
  }

  @override void dispose() { for (final c in [_supEmail,_instructions,_notes,_intNotes]) c.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_fk.currentState!.validate()) return;

    if (!_isEdit) {
      // ── CREATE: one RFQ per selected supplier ──────────────
      if (_supplierIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one supplier')));
        return;
      }
      setState(() => _saving = true);
      try {
        final data = {
          'supplier_ids': _supplierIds,
          'items': _items,
          'special_instructions': _instructions.text.trim(),
          'supplier_notes': _notes.text.trim(),
          'internal_notes': _intNotes.text.trim(),
          'status': _status,
          if (_delivDate != null) 'expected_delivery_date': _delivDate!.toIso8601String(),
        };
        await ApiClient.instance.post('/rfq', data: data);
        if (mounted) { Navigator.pop(context); widget.onSaved(); }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create RFQ(s): $e'), backgroundColor: AppColors.error));
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    } else {
      // ── EDIT: single supplier, unchanged behaviour ─────────
      if (_supplierId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a supplier')));
        return;
      }
      final data = {
        'supplier_id':_supplierId,'supplier_email':_supEmail.text.trim(),
        'items':_items,'special_instructions':_instructions.text.trim(),
        'supplier_notes':_notes.text.trim(),'internal_notes':_intNotes.text.trim(),
        'status':_status,
        if (_delivDate!=null) 'expected_delivery_date':_delivDate!.toIso8601String(),
      };
      context.read<AdminBloc>().add(AdminUpdateRFQEvent(widget.rfq!['_id']?.toString()??'', data));
      Navigator.pop(context); widget.onSaved();
    }
  }

  @override Widget build(BuildContext context) => AlertDialog(
    title: Text(_isEdit?'Edit RFQ':'Create RFQ'),
    content: SizedBox(width:580,height:600,child:Form(key:_fk,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      // Supplier selection — multi-select dropdown with removable chips
      if (!_isEdit) ...[
        Align(alignment: Alignment.centerLeft, child: Text('Select Supplier(s) *', style: AppText.bodyMd())),
        const SizedBox(height: 6),
        _SupplierMultiSelect(
          allSuppliers: _suppliers,
          selectedIds: _supplierIds,
          onChanged: (ids) => setState(() => _supplierIds = ids),
        ),
      ] else ...[
        DropdownButtonFormField<String>(value:_supplierId,decoration:const InputDecoration(labelText:'Supplier *'),
          items:_suppliers.map((s)=>DropdownMenuItem<String>(value:s['_id']?.toString(),child:Text(s['name']?.toString()??''))).toList(),
          onChanged:(v){
            setState(()=>_supplierId=v);
            final sup=_suppliers.firstWhere((s)=>s['_id']?.toString()==v, orElse:()=>{});
            if (sup['email']!=null) _supEmail.text=sup['email']?.toString()??'';
          }, validator:(v)=>v==null?'Required':null),
        const SizedBox(height:10),
        TextFormField(controller:_supEmail,decoration:const InputDecoration(labelText:'Supplier Email')),
      ],
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:DropdownButtonFormField<String>(value:_status,decoration:const InputDecoration(labelText:'Status'),
          items:const [
            DropdownMenuItem(value:'draft',child:Text('Draft')),
            DropdownMenuItem(value:'sent',child:Text('Sent')),
            DropdownMenuItem(value:'quotation_received',child:Text('Quotation Received')),
            DropdownMenuItem(value:'accepted',child:Text('Accepted')),
            DropdownMenuItem(value:'cancelled',child:Text('Cancelled')),
          ],
          onChanged:(v)=>setState(()=>_status=v!))),
        const SizedBox(width:10),
        Expanded(child:InkWell(
          onTap:()async{final d=await showDatePicker(context:context,initialDate:_delivDate??DateTime.now().add(const Duration(days:14)),firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:365)));if(d!=null)setState(()=>_delivDate=d);},
          child:InputDecorator(decoration:const InputDecoration(labelText:'Expected Delivery'),
            child:Text(_delivDate!=null?'${_delivDate!.day}/${_delivDate!.month}/${_delivDate!.year}':'Select date',style:AppText.body())))),
      ]),
      const SizedBox(height:12),
      // Product rows
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        Text('Product Rows',style:AppText.bodyMd()),
        TextButton.icon(icon:const Icon(Icons.add,size:16),label:const Text('Add Row'),
          onPressed:()=>setState(()=>_items.add({'product_name':'','qty':1,'unit':'piece','notes':'','quoted_price':null}))),
      ]),
      ..._items.asMap().entries.map((e){
        final idx=e.key; final item=e.value;
        return Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(10),
          decoration:BoxDecoration(color:AppColors.surfaceWarm,borderRadius:BorderRadius.circular(AppRadius.md),border:Border.all(color:AppColors.border)),
          child:Column(children:[
            Row(children:[
              Expanded(child:_products.isEmpty
                ? TextFormField(initialValue:item['product_name']?.toString(),decoration:const InputDecoration(labelText:'Product Name',isDense:true),onChanged:(v)=>item['product_name']=v)
                : DropdownButtonFormField<String>(
                    value:item['sku_id']?.toString(),decoration:const InputDecoration(labelText:'Product',isDense:true),
                    items:_products.map((p)=>DropdownMenuItem<String>(value:p['_id']?.toString(),child:Text(p['name']?.toString()??'',overflow:TextOverflow.ellipsis))).toList(),
                    onChanged:(v){setState((){final p=_products.firstWhere((p)=>p['_id']?.toString()==v,orElse:()=>{});item['sku_id']=v;item['product_name']=p['name']?.toString()??'';});})
              ),
              const SizedBox(width:8),
              SizedBox(width:60,child:TextFormField(initialValue:item['qty']?.toString()??'1',decoration:const InputDecoration(labelText:'Qty',isDense:true),keyboardType:TextInputType.number,onChanged:(v)=>item['qty']=int.tryParse(v)??1)),
              const SizedBox(width:8),
              SizedBox(width:70,child:TextFormField(initialValue:item['unit']?.toString()??'piece',decoration:const InputDecoration(labelText:'Unit',isDense:true),onChanged:(v)=>item['unit']=v)),
              const SizedBox(width:4),
              IconButton(icon:const Icon(Icons.delete_outline,color:AppColors.error,size:18),onPressed:(){if(_items.length>1)setState(()=>_items.removeAt(idx));}),
            ]),
            const SizedBox(height:6),
            Row(children:[
              Expanded(child:TextFormField(initialValue:item['quoted_price']?.toString()??'',decoration:const InputDecoration(labelText:'Quoted Price (if received)',isDense:true),keyboardType:TextInputType.number,onChanged:(v)=>item['quoted_price']=double.tryParse(v))),
              const SizedBox(width:8),
              Expanded(flex:2,child:TextFormField(initialValue:item['notes']?.toString()??'',decoration:const InputDecoration(labelText:'Notes',isDense:true),onChanged:(v)=>item['notes']=v)),
            ]),
          ]));
      }),
      const SizedBox(height:10),
      TextFormField(controller:_instructions,decoration:const InputDecoration(labelText:'Special Instructions'),maxLines:2),
      const SizedBox(height:8),
      TextFormField(controller:_notes,decoration:const InputDecoration(labelText:'Supplier Notes (from quotation reply)'),maxLines:2),
      const SizedBox(height:8),
      TextFormField(controller:_intNotes,decoration:const InputDecoration(labelText:'Internal Notes'),maxLines:2),
    ])))),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
      ElevatedButton(
        onPressed:_saving?null:_save,
        child: _saving
            ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
            : Text(_isEdit?'Update':'Create')),
    ],
  );
}

// ─────────────────────────────────────────────────────────────
// Supplier multi-select: true anchored dropdown + removable chips
// ─────────────────────────────────────────────────────────────
class _SupplierMultiSelect extends StatefulWidget {
  final List<dynamic> allSuppliers;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  const _SupplierMultiSelect({
    required this.allSuppliers,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  State<_SupplierMultiSelect> createState() => _SupplierMultiSelectState();
}

class _SupplierMultiSelectState extends State<_SupplierMultiSelect> {
  final _layerLink = LayerLink();
  final _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _open = false;

  Map<String, dynamic>? _findById(String id) {
    for (final s in widget.allSuppliers) {
      if (s['_id']?.toString() == id) return Map<String, dynamic>.from(s as Map);
    }
    return null;
  }

  void _toggleDropdown() {
    if (_open) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (widget.allSuppliers.isEmpty) return;
    final renderBox = _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 300;

    _overlayEntry = OverlayEntry(
      builder: (overlayCtx) => Stack(
        children: [
          // Invisible tap-catcher to close when tapping outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeDropdown,
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, (renderBox?.size.height ?? 48) + 4),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                width: width,
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: _buildOptionsList(),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _open = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _open = false);
  }

  Widget _buildOptionsList() {
    final available = widget.allSuppliers
        .where((s) => !widget.selectedIds.contains(s['_id']?.toString()))
        .toList();

    if (available.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('All suppliers already selected', style: TextStyle(fontSize: 13)),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: available.length,
      itemBuilder: (_, i) {
        final s = available[i];
        return InkWell(
          onTap: () {
            final id = s['_id']?.toString();
            if (id != null) widget.onChanged([...widget.selectedIds, id]);
            _closeDropdown();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s['name']?.toString() ?? '', style: AppText.bodyMd()),
              Text(s['email']?.toString() ?? '', style: AppText.caption()),
            ]),
          ),
        );
      },
    );
  }

  void _remove(String id) {
    widget.onChanged(widget.selectedIds.where((s) => s != id).toList());
    // Refresh the open dropdown's contents if it's currently visible
    if (_open) {
      _overlayEntry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        key: _fieldKey,
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: widget.allSuppliers.isEmpty ? null : _toggleDropdown,
        child: InputDecorator(
          decoration: InputDecoration(
            hintText: widget.allSuppliers.isEmpty ? 'Loading suppliers...' : 'Tap to add a supplier',
            suffixIcon: Icon(_open ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
          child: widget.selectedIds.isEmpty
              ? const SizedBox(height: 24)
              : Wrap(
                  spacing: 6, runSpacing: 6,
                  children: widget.selectedIds.map((id) {
                    final s = _findById(id);
                    final label = s?['name']?.toString() ?? id;
                    return Chip(
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => _remove(id),
                      backgroundColor: AppColors.primary.withAlpha(20),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
        ),
      ),
    );
  }
}