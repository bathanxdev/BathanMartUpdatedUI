import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminPurchaseOrdersScreen extends StatefulWidget {
  const AdminPurchaseOrdersScreen({super.key});
  @override State<AdminPurchaseOrdersScreen> createState() => _AdminPurchaseOrdersScreenState();
}
class _AdminPurchaseOrdersScreenState extends State<AdminPurchaseOrdersScreen> {
  String? _statusFilter;
  @override void initState() { super.initState(); _load(); }
  void _load() => context.read<AdminBloc>().add(AdminLoadPurchaseOrdersEvent(status: _statusFilter));

  Color _sc(String s) { switch(s){ case 'draft':return AppColors.textHint; case 'sent':return AppColors.info; case 'acknowledged':return AppColors.warning; case 'partially_delivered':return AppColors.accent; case 'delivered':return AppColors.success; case 'cancelled':return AppColors.error; default:return AppColors.textHint; } }
  String _sl(String s) => s.replaceAll('_',' ').split(' ').map((w)=>w.isEmpty?w:'${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  String _fd(dynamic dt) { try { return DateTime.parse(dt.toString()).toLocal().toString().substring(0,10); } catch(_) { return dt?.toString()??''; } }

  void _showForm({Map? po}) {
    showDialog(context: context, barrierDismissible: false, builder: (_) => BlocProvider.value(
      value: context.read<AdminBloc>(),
      child: _POForm(po: po, onSaved: _load)));
  }

  void _confirmSendEmail(BuildContext ctx, String id, String poNo, String email) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Send PO Email'),
      content: Text('Send acceptance/PO email for $poNo to $email?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { Navigator.pop(ctx); ctx.read<AdminBloc>().add(AdminSendPOEmailEvent(id)); }, child: const Text('Send')),
      ]));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Purchase Orders'),
      actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _showForm()),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
    body: Column(children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal:16,vertical:10),
        child: Row(children: [
          _sc2('All', null),
          ...['draft','sent','acknowledged','partially_delivered','delivered','cancelled'].map((s) =>
            Padding(padding: const EdgeInsets.only(left:8), child: _sc2(_sl(s), s))),
        ])),
      Expanded(child: BlocConsumer<AdminBloc, AdminState>(
        listener: (ctx, state) {
          if (state is AdminSuccessState) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success)); _load(); }
          if (state is AdminErrorState)   { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error)); }
        },
        builder: (ctx, state) {
          if (state is AdminLoadingState) return const Center(child: CircularProgressIndicator());
          if (state is! AdminPurchaseOrdersLoaded || state.pos.isEmpty)
            return AdminEmptyState(title: 'No Purchase Orders', icon: Icons.assignment_outlined, actionLabel: 'Create PO', onAction: () => _showForm());
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical:8),
            itemCount: state.pos.length, separatorBuilder: (_, __) => const SizedBox(height:10),
            itemBuilder: (_, i) {
              final po  = state.pos[i] as Map;
              final status = po['status']?.toString()?? 'draft';
              final sup    = po['supplier_id'] as Map?;
              final loc    = po['delivery_location_id'] as Map?;
              final items  = (po['items'] as List?)??[];
              return Container(padding: const EdgeInsets.all(16), decoration: AppUI.cardDecoration(elevated:true),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children:[
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Text(po['po_no']?.toString()??'', style:AppText.h3(color:AppColors.primary)),
                      Text(sup?['name']?.toString()??'Supplier', style:AppText.bodyMd()),
                      if (loc!=null) Text('→ ${loc['name']?.toString()??''}', style:AppText.caption()),
                    ])),
                    Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                      AppUI.badge(_sl(status), _sc(status)),
                      const SizedBox(height:4),
                      Text('Rs.${po['total_amount']??0}', style:AppText.price(size:16)),
                    ]),
                    const SizedBox(width:8),
                    PopupMenuButton<String>(
                      onSelected:(v){
                        if(v=='edit') _showForm(po:po);
                        if(v=='email') _confirmSendEmail(ctx,po['_id']?.toString()??'',po['po_no']?.toString()??'',po['supplier_email']?.toString()??'');
                        if(v=='delete') { ctx.read<AdminBloc>().add(AdminDeletePOEvent(po['_id']?.toString()??'')); }
                      },
                      itemBuilder:(_)=>[
                        const PopupMenuItem(value:'edit',child:Row(children:[Icon(Icons.edit_outlined,size:16),SizedBox(width:8),Text('Edit')])),
                        const PopupMenuItem(value:'email',child:Row(children:[Icon(Icons.email_outlined,size:16,color:AppColors.info),SizedBox(width:8),Text('Send PO Email',style:TextStyle(color:AppColors.info))])),
                        const PopupMenuItem(value:'delete',child:Row(children:[Icon(Icons.delete_outline,size:16,color:AppColors.error),SizedBox(width:8),Text('Delete',style:TextStyle(color:AppColors.error))])),
                      ]),
                  ]),
                  if (items.isNotEmpty)...[
                    const SizedBox(height:8), const Divider(),
                    ...items.take(2).map((item){
                      final im=item as Map;
                      return Padding(padding:const EdgeInsets.only(bottom:4),child:Row(children:[
                        const Icon(Icons.circle,size:6,color:AppColors.textHint),const SizedBox(width:8),
                        Expanded(child:Text('${im['product_name']??'Product'} × ${im['qty']??0} ${im['unit']??''}',style:AppText.caption())),
                        Text('Rs.${im['agreed_price']??0}',style:AppText.caption()),
                      ]));
                    }),
                    if(items.length>2) Text('+${items.length-2} more',style:AppText.caption(color:AppColors.textHint)),
                  ],
                  const SizedBox(height:6),
                  Wrap(spacing:12,children:[
                    if(po['expected_delivery_date']!=null) Text('Expected: ${_fd(po['expected_delivery_date'])}',style:AppText.caption()),
                    if(po['po_sent_at']!=null) Text('Sent: ${_fd(po['po_sent_at'])}',style:AppText.caption(color:AppColors.info)),
                    Text('Terms: ${po['payment_terms']??'N/A'}',style:AppText.caption()),
                  ]),
                ]));
            });
        })),
    ]),
  );

  Widget _sc2(String label, String? val) => FilterChip(
    label: Text(label, style: const TextStyle(fontSize:12)),
    selected: _statusFilter == val,
    onSelected:(_){setState(()=>_statusFilter=val);_load();},
    selectedColor:AppColors.primary.withAlpha(20), checkmarkColor:AppColors.primary);
}

class _POForm extends StatefulWidget {
  final Map? po; final VoidCallback onSaved;
  const _POForm({this.po, required this.onSaved});
  @override State<_POForm> createState() => _POFormState();
}
class _POFormState extends State<_POForm> {
  final _fk = GlobalKey<FormState>();
  late final TextEditingController _supEmail, _instructions, _notes;
  String? _supplierId, _locationId, _rfqId, _status, _terms;
  DateTime? _delivDate;
  List<dynamic> _suppliers=[], _locations=[];
  List<Map<String,dynamic>> _items=[];

  @override void initState() {
    super.initState();
    final po = widget.po;
    final sup = po?['supplier_id'] as Map?;
    final loc = po?['delivery_location_id'] as Map?;
    _supplierId  = sup?['_id']?.toString()??po?['supplier_id']?.toString();
    _locationId  = loc?['_id']?.toString()??po?['delivery_location_id']?.toString();
    _supEmail    = TextEditingController(text:po?['supplier_email']?.toString()??'');
    _instructions= TextEditingController(text:po?['special_instructions']?.toString()??'');
    _notes       = TextEditingController(text:po?['internal_notes']?.toString()??'');
    _status      = po?['status']?.toString()??'draft';
    _terms       = po?['payment_terms']?.toString()??'net30';
    if (po?['expected_delivery_date']!=null) { try { _delivDate=DateTime.parse(po!['expected_delivery_date'].toString()); } catch(_) {} }
    _items = ((po?['items'] as List?)??[]).map((i)=>Map<String,dynamic>.from(i as Map)).toList();
    if (_items.isEmpty) _items.add({'product_name':'','qty':1,'unit':'piece','agreed_price':0});
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final r1 = await ApiClient.instance.get('/suppliers');
      final r2 = await ApiClient.instance.get('/warehouses');
      if (mounted) setState(()=>{ _suppliers=(r1['data'] as List?)??[], _locations=(r2['data'] as List?)??[] });
    } catch(_) {}
  }

  @override void dispose() { for (final c in [_supEmail,_instructions,_notes]) c.dispose(); super.dispose(); }

  void _save() {
    if (!_fk.currentState!.validate()) return;
    if (_supplierId==null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Select a supplier'))); return; }
    final data = {
      'supplier_id':_supplierId,'supplier_email':_supEmail.text.trim(),
      if (_locationId!=null) 'delivery_location_id':_locationId,
      'items':_items,'payment_terms':_terms,'status':_status,
      'special_instructions':_instructions.text.trim(),'internal_notes':_notes.text.trim(),
      if (_delivDate!=null) 'expected_delivery_date':_delivDate!.toIso8601String(),
    };
    if (widget.po!=null) { context.read<AdminBloc>().add(AdminUpdatePOEvent(widget.po!['_id']?.toString()??'', data)); }
    else { context.read<AdminBloc>().add(AdminCreatePOEvent(data)); }
    Navigator.pop(context); widget.onSaved();
  }

  @override Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.po==null?'Create Purchase Order':'Edit PO'),
    content: SizedBox(width:580,height:600,child:Form(key:_fk,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      DropdownButtonFormField<String>(value:_supplierId,decoration:const InputDecoration(labelText:'Supplier *'),
        items:_suppliers.map((s)=>DropdownMenuItem<String>(value:s['_id']?.toString(),child:Text(s['name']?.toString()??''))).toList(),
        onChanged:(v){setState(()=>_supplierId=v);final s=_suppliers.firstWhere((s)=>s['_id']?.toString()==v,orElse:()=>{});if(s['email']!=null)_supEmail.text=s['email']?.toString()??'';},
        validator:(v)=>v==null?'Required':null),
      const SizedBox(height:10),
      TextFormField(controller:_supEmail,decoration:const InputDecoration(labelText:'Supplier Email')),
      const SizedBox(height:10),
      DropdownButtonFormField<String>(value:_locationId,decoration:const InputDecoration(labelText:'Delivery Location'),
        items:_locations.map((l)=>DropdownMenuItem<String>(value:l['_id']?.toString(),child:Text(l['name']?.toString()??''))).toList(),
        onChanged:(v)=>setState(()=>_locationId=v)),
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:DropdownButtonFormField<String>(value:_status,decoration:const InputDecoration(labelText:'Status'),
          items:const [
            DropdownMenuItem(value:'draft',child:Text('Draft')),DropdownMenuItem(value:'sent',child:Text('Sent')),
            DropdownMenuItem(value:'acknowledged',child:Text('Acknowledged')),DropdownMenuItem(value:'partially_delivered',child:Text('Partially Delivered')),
            DropdownMenuItem(value:'delivered',child:Text('Delivered')),DropdownMenuItem(value:'cancelled',child:Text('Cancelled')),
          ],onChanged:(v)=>setState(()=>_status=v!))),
        const SizedBox(width:10),
        Expanded(child:DropdownButtonFormField<String>(value:_terms,decoration:const InputDecoration(labelText:'Payment Terms'),
          items:const [DropdownMenuItem(value:'net15',child:Text('Net 15')),DropdownMenuItem(value:'net30',child:Text('Net 30')),DropdownMenuItem(value:'net60',child:Text('Net 60')),DropdownMenuItem(value:'cod',child:Text('COD')),DropdownMenuItem(value:'advance',child:Text('Advance'))],
          onChanged:(v)=>setState(()=>_terms=v!))),
      ]),
      const SizedBox(height:10),
      InkWell(onTap:()async{final d=await showDatePicker(context:context,initialDate:_delivDate??DateTime.now().add(const Duration(days:14)),firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:365)));if(d!=null)setState(()=>_delivDate=d);},
        child:InputDecorator(decoration:const InputDecoration(labelText:'Expected Delivery Date'),child:Text(_delivDate!=null?'${_delivDate!.day}/${_delivDate!.month}/${_delivDate!.year}':'Select date',style:AppText.body()))),
      const SizedBox(height:12),
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        Text('Line Items',style:AppText.bodyMd()),
        TextButton.icon(icon:const Icon(Icons.add,size:16),label:const Text('Add Row'),onPressed:()=>setState(()=>_items.add({'product_name':'','qty':1,'unit':'piece','agreed_price':0}))),
      ]),
      ..._items.asMap().entries.map((e){
        final idx=e.key;final item=e.value;
        return Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(10),
          decoration:BoxDecoration(color:AppColors.surfaceWarm,borderRadius:BorderRadius.circular(AppRadius.md),border:Border.all(color:AppColors.border)),
          child:Row(children:[
            Expanded(child:TextFormField(initialValue:item['product_name']?.toString()??'',decoration:const InputDecoration(labelText:'Product',isDense:true),onChanged:(v)=>item['product_name']=v)),
            const SizedBox(width:6),
            SizedBox(width:55,child:TextFormField(initialValue:item['qty']?.toString()??'1',decoration:const InputDecoration(labelText:'Qty',isDense:true),keyboardType:TextInputType.number,onChanged:(v)=>item['qty']=int.tryParse(v)??1)),
            const SizedBox(width:6),
            SizedBox(width:65,child:TextFormField(initialValue:item['unit']?.toString()??'piece',decoration:const InputDecoration(labelText:'Unit',isDense:true),onChanged:(v)=>item['unit']=v)),
            const SizedBox(width:6),
            SizedBox(width:75,child:TextFormField(initialValue:item['agreed_price']?.toString()??'0',decoration:const InputDecoration(labelText:'Price',isDense:true),keyboardType:TextInputType.number,onChanged:(v){item['agreed_price']=double.tryParse(v)??0;item['line_total']=(item['agreed_price']??0)*(item['qty']??0);})),
            const SizedBox(width:4),
            IconButton(icon:const Icon(Icons.delete_outline,color:AppColors.error,size:18),onPressed:(){if(_items.length>1)setState(()=>_items.removeAt(idx));},padding:EdgeInsets.zero),
          ]));
      }),
      const SizedBox(height:10),
      TextFormField(controller:_instructions,decoration:const InputDecoration(labelText:'Special Instructions'),maxLines:2),
      const SizedBox(height:8),
      TextFormField(controller:_notes,decoration:const InputDecoration(labelText:'Internal Notes'),maxLines:2),
    ])))),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
      ElevatedButton(onPressed:_save,child:Text(widget.po==null?'Create':'Update')),
    ],
  );
}
