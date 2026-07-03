import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminPurchaseScreen extends StatefulWidget {
  const AdminPurchaseScreen({super.key});
  @override State<AdminPurchaseScreen> createState() => _AdminPurchaseScreenState();
}
class _AdminPurchaseScreenState extends State<AdminPurchaseScreen> {
  String? _statusFilter;
  @override void initState() { super.initState(); _load(); }
  void _load() => context.read<AdminBloc>().add(AdminLoadPurchasesEvent(status: _statusFilter));

  Color _sc(String s) { switch(s){ case 'draft':return AppColors.textHint; case 'confirmed':return AppColors.success; case 'cancelled':return AppColors.error; default:return AppColors.textHint; } }
  Color _pc(String s) { switch(s){ case 'paid':return AppColors.success; case 'partial':return AppColors.warning; default:return AppColors.error; } }
  String _fd(dynamic dt) { try { return DateTime.parse(dt.toString()).toLocal().toString().substring(0,10); } catch(_) { return dt?.toString()??''; } }

  void _showForm({Map? purchase}) {
    showDialog(context: context, barrierDismissible: false, builder: (_) => BlocProvider.value(
      value: context.read<AdminBloc>(),
      child: _PurchaseForm(purchase: purchase, onSaved: _load)));
  }

  void _confirmConfirm(BuildContext ctx, String id, String no) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      title: const Text('Confirm Purchase'),
      content: Text('Confirm $no? This will update inventory at the selected location.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); ctx.read<AdminBloc>().add(AdminConfirmPurchaseEvent(id)); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          child: const Text('Confirm & Update Inventory')),
      ]));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Purchase Records'),
      actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _showForm()),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ]),
    body: Column(children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal:16,vertical:10),
        child: Row(children: [
          _fc('All', null),
          ...['draft','confirmed','cancelled'].map((s) =>
            Padding(padding:const EdgeInsets.only(left:8), child: _fc(s[0].toUpperCase()+s.substring(1), s))),
        ])),
      Expanded(child: BlocConsumer<AdminBloc, AdminState>(
        listener: (ctx, state) {
          if (state is AdminSuccessState) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success)); _load(); }
          if (state is AdminErrorState)   { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error)); }
        },
        builder: (ctx, state) {
          if (state is AdminLoadingState) return const Center(child: CircularProgressIndicator());
          if (state is! AdminPurchasesLoaded || state.purchases.isEmpty)
            return AdminEmptyState(title: 'No purchase records', icon: Icons.shopping_cart_outlined, actionLabel: 'Add Purchase', onAction: () => _showForm());
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical:8),
            itemCount: state.purchases.length, separatorBuilder:(_,__)=>const SizedBox(height:10),
            itemBuilder: (_, i) {
              final p      = state.purchases[i] as Map;
              final status = p['status']?.toString()?? 'draft';
              final payStatus = p['payment_status']?.toString()?? 'pending';
              return Container(padding:const EdgeInsets.all(16), decoration:AppUI.cardDecoration(elevated:true),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Row(children:[
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Row(children:[Text(p['purchase_no']?.toString()??'',style:AppText.h3(color:AppColors.primary)),const SizedBox(width:8),AppUI.badge(status[0].toUpperCase()+status.substring(1),_sc(status))]),
                      const SizedBox(height:2),
                      Text(p['product_name']?.toString()??'',style:AppText.bodyMd(),maxLines:1,overflow:TextOverflow.ellipsis),
                      Text('${p['product_no']??''} • SKU: ${p['sku_code']??'N/A'}',style:AppText.caption()),
                    ])),
                    Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                      Text('Rs.${p['grand_total']??0}',style:AppText.price(size:16)),
                      AppUI.badge(payStatus,_pc(payStatus)),
                    ]),
                  ]),
                  const SizedBox(height:10),
                  Wrap(spacing:12,runSpacing:6,children:[
                    _chip(Icons.local_shipping_outlined,p['supplier_name']?.toString()??''),
                    _chip(Icons.store_outlined,p['location_name']?.toString()??''),
                    _chip(Icons.inventory_outlined,'${p['qty_purchased']??0} ${p['unit']??'pc'} @ Rs.${p['purchase_rate']??0}'),
                    _chip(Icons.calendar_today_outlined,_fd(p['purchase_date'])),
                    if(p['invoice_no']!=null) _chip(Icons.receipt_outlined,'INV: ${p['invoice_no']}'),
                  ]),
                  const SizedBox(height:10),
                  Row(children:[
                    if (status=='draft')...[
                      Expanded(child:OutlinedButton.icon(icon:const Icon(Icons.check_circle_outline,size:16),label:const Text('Confirm'),
                        style:OutlinedButton.styleFrom(foregroundColor:AppColors.success,side:const BorderSide(color:AppColors.success)),
                        onPressed:()=>_confirmConfirm(ctx,p['_id']?.toString()??'',p['purchase_no']?.toString()??''))),
                      const SizedBox(width:8),
                    ],
                    Expanded(child:OutlinedButton.icon(icon:const Icon(Icons.edit_outlined,size:16),label:const Text('Edit'),
                      onPressed:status!='confirmed'?()=>_showForm(purchase:p):null)),
                    const SizedBox(width:8),
                    if(status!='confirmed') OutlinedButton.icon(icon:const Icon(Icons.delete_outline,size:16,color:AppColors.error),label:const Text('Cancel',style:TextStyle(color:AppColors.error)),
                      style:OutlinedButton.styleFrom(side:const BorderSide(color:AppColors.error)),
                      onPressed:()=>ctx.read<AdminBloc>().add(AdminDeletePurchaseEvent(p['_id']?.toString()??''))),
                  ]),
                ]));
            });
        })),
    ]),
  );

  Widget _fc(String label, String? val) => FilterChip(label:Text(label,style:const TextStyle(fontSize:12)),selected:_statusFilter==val,onSelected:(_){setState(()=>_statusFilter=val);_load();},selectedColor:AppColors.primary.withAlpha(20),checkmarkColor:AppColors.primary);
  Widget _chip(IconData icon, String text) => Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),decoration:BoxDecoration(color:AppColors.surfaceWarm,borderRadius:BorderRadius.circular(AppRadius.full),border:Border.all(color:AppColors.border)),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:13,color:AppColors.textHint),const SizedBox(width:4),Text(text,style:AppText.caption())]));
}

class _PurchaseForm extends StatefulWidget {
  final Map? purchase; final VoidCallback onSaved;
  const _PurchaseForm({this.purchase, required this.onSaved});
  @override State<_PurchaseForm> createState() => _PurchaseFormState();
}
class _PurchaseFormState extends State<_PurchaseForm> {
  final _fk = GlobalKey<FormState>();
  late final TextEditingController _qty, _rate, _tax, _invoice, _remarks;
  String? _skuId, _supplierId, _locationId;
  String _unit='piece', _payMethod='cash', _payStatus='pending', _condition='good', _status='draft';
  DateTime? _purchaseDate, _payDate, _invoiceDate;
  List<dynamic> _products=[], _suppliers=[], _locations=[];
  double _total=0, _taxAmt=0, _grand=0;

  void _calcTotals() {
    final q=double.tryParse(_qty.text)??0;
    final r=double.tryParse(_rate.text)??0;
    final t=double.tryParse(_tax.text)??0;
    _total=q*r; _taxAmt=_total*t/100; _grand=_total+_taxAmt;
    setState((){});
  }

  @override void initState() {
    super.initState();
    final p=widget.purchase;
    _qty     = TextEditingController(text:p?['qty_purchased']?.toString()??'')..addListener(_calcTotals);
    _rate    = TextEditingController(text:p?['purchase_rate']?.toString()??'')..addListener(_calcTotals);
    _tax     = TextEditingController(text:p?['tax_percent']?.toString()??'0')..addListener(_calcTotals);
    _invoice = TextEditingController(text:p?['invoice_no']?.toString()??'');
    _remarks = TextEditingController(text:p?['remarks']?.toString()??'');
    _unit    = p?['unit']?.toString()??'piece';
    _payMethod=p?['payment_method']?.toString()??'cash';
    _payStatus=p?['payment_status']?.toString()??'pending';
    _condition=p?['condition_received']?.toString()??'good';
    _status  = p?['status']?.toString()??'draft';
    _skuId   = (p?['sku_id'] is Map?p!['sku_id']['_id']:p?['sku_id'])?.toString();
    _supplierId=(p?['supplier_id'] is Map?p!['supplier_id']['_id']:p?['supplier_id'])?.toString();
    _locationId=(p?['location_id'] is Map?p!['location_id']['_id']:p?['location_id'])?.toString();
    if(p?['purchase_date']!=null){try{_purchaseDate=DateTime.parse(p!['purchase_date'].toString());}catch(_){}}
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final r1=await ApiClient.instance.get('/products',params:{'limit':'100','status':'active'});
      final r2=await ApiClient.instance.get('/suppliers');
      final r3=await ApiClient.instance.get('/warehouses');
      if(mounted) setState((){_products=(r1['data'] as List?)??[];_suppliers=(r2['data'] as List?)??[];_locations=(r3['data'] as List?)??[];});
    } catch(_){}
  }

  @override void dispose() { for(final c in [_qty,_rate,_tax,_invoice,_remarks])c.dispose(); super.dispose(); }

  void _save() {
    if(!_fk.currentState!.validate())return;
    if(_skuId==null||_supplierId==null||_locationId==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Select product, supplier and location')));return;}
    final data={
      'sku_id':_skuId,'supplier_id':_supplierId,'location_id':_locationId,
      'qty_purchased':double.tryParse(_qty.text)??0,'purchase_rate':double.tryParse(_rate.text)??0,
      'unit':_unit,'tax_percent':double.tryParse(_tax.text)??0,
      'payment_method':_payMethod,'payment_status':_payStatus,
      'condition_received':_condition,'status':_status,
      'invoice_no':_invoice.text.trim(),'remarks':_remarks.text.trim(),
      if(_purchaseDate!=null)'purchase_date':_purchaseDate!.toIso8601String(),
      if(_payDate!=null)'payment_date':_payDate!.toIso8601String(),
      if(_invoiceDate!=null)'invoice_date':_invoiceDate!.toIso8601String(),
    };
    if(widget.purchase!=null){context.read<AdminBloc>().add(AdminUpdatePurchaseEvent(widget.purchase!['_id']?.toString()??'',data));}
    else{context.read<AdminBloc>().add(AdminCreatePurchaseEvent(data));}
    Navigator.pop(context);widget.onSaved();
  }

  @override Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.purchase==null?'Add Purchase Record':'Edit Purchase'),
    content: SizedBox(width:560,height:600,child:Form(key:_fk,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      DropdownButtonFormField<String>(value:_skuId,decoration:const InputDecoration(labelText:'Product *'),
        items:_products.map((p)=>DropdownMenuItem<String>(value:p['_id']?.toString(),child:Text(p['name']?.toString()??'',overflow:TextOverflow.ellipsis))).toList(),
        onChanged:(v)=>setState(()=>_skuId=v),validator:(v)=>v==null?'Required':null),
      const SizedBox(height:10),
      DropdownButtonFormField<String>(value:_supplierId,decoration:const InputDecoration(labelText:'Supplier *'),
        items:_suppliers.map((s)=>DropdownMenuItem<String>(value:s['_id']?.toString(),child:Text(s['name']?.toString()??''))).toList(),
        onChanged:(v)=>setState(()=>_supplierId=v),validator:(v)=>v==null?'Required':null),
      const SizedBox(height:10),
      DropdownButtonFormField<String>(value:_locationId,decoration:const InputDecoration(labelText:'Receiving Location *'),
        items:_locations.map((l)=>DropdownMenuItem<String>(value:l['_id']?.toString(),child:Text(l['name']?.toString()??''))).toList(),
        onChanged:(v)=>setState(()=>_locationId=v),validator:(v)=>v==null?'Required':null),
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:TextFormField(controller:_qty,decoration:const InputDecoration(labelText:'Qty Purchased *'),keyboardType:TextInputType.number,validator:(v)=>v!.isEmpty?'Required':null)),
        const SizedBox(width:8),
        SizedBox(width:90,child:DropdownButtonFormField<String>(value:_unit,decoration:const InputDecoration(labelText:'Unit'),
          items:['piece','kg','g','litre','ml','metre','box','pack'].map((u)=>DropdownMenuItem(value:u,child:Text(u))).toList(),
          onChanged:(v)=>setState(()=>_unit=v!))),
        const SizedBox(width:8),
        Expanded(child:TextFormField(controller:_rate,decoration:const InputDecoration(labelText:'Rate (Rs.) *'),keyboardType:TextInputType.number,validator:(v)=>v!.isEmpty?'Required':null)),
      ]),
      const SizedBox(height:8),
      Row(children:[
        Expanded(child:TextFormField(controller:_tax,decoration:const InputDecoration(labelText:'Tax %'),keyboardType:TextInputType.number)),
        const SizedBox(width:8),
        Expanded(child:Container(padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:AppColors.primarySoft,borderRadius:BorderRadius.circular(AppRadius.md)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text('Total: Rs.${_total.toStringAsFixed(2)}',style:AppText.caption()),
            Text('Tax: Rs.${_taxAmt.toStringAsFixed(2)}',style:AppText.caption()),
            Text('Grand: Rs.${_grand.toStringAsFixed(2)}',style:AppText.bodyMd(color:AppColors.primary)),
          ]))),
      ]),
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:DropdownButtonFormField<String>(value:_payMethod,decoration:const InputDecoration(labelText:'Payment Method'),
          items:const [DropdownMenuItem(value:'cash',child:Text('Cash')),DropdownMenuItem(value:'bank_transfer',child:Text('Bank Transfer')),DropdownMenuItem(value:'cheque',child:Text('Cheque')),DropdownMenuItem(value:'credit',child:Text('Credit')),DropdownMenuItem(value:'upi',child:Text('UPI'))],
          onChanged:(v)=>setState(()=>_payMethod=v!))),
        const SizedBox(width:8),
        Expanded(child:DropdownButtonFormField<String>(value:_payStatus,decoration:const InputDecoration(labelText:'Payment Status'),
          items:const [DropdownMenuItem(value:'pending',child:Text('Pending')),DropdownMenuItem(value:'partial',child:Text('Partial')),DropdownMenuItem(value:'paid',child:Text('Paid'))],
          onChanged:(v)=>setState(()=>_payStatus=v!))),
      ]),
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:DropdownButtonFormField<String>(value:_condition,decoration:const InputDecoration(labelText:'Condition'),
          items:const [DropdownMenuItem(value:'good',child:Text('Good')),DropdownMenuItem(value:'partial',child:Text('Partial')),DropdownMenuItem(value:'damaged',child:Text('Damaged'))],
          onChanged:(v)=>setState(()=>_condition=v!))),
        const SizedBox(width:8),
        Expanded(child:DropdownButtonFormField<String>(value:_status,decoration:const InputDecoration(labelText:'Status'),
          items:const [DropdownMenuItem(value:'draft',child:Text('Draft')),DropdownMenuItem(value:'confirmed',child:Text('Confirmed')),DropdownMenuItem(value:'cancelled',child:Text('Cancelled'))],
          onChanged:(v)=>setState(()=>_status=v!))),
      ]),
      const SizedBox(height:10),
      TextFormField(controller:_invoice,decoration:const InputDecoration(labelText:'Invoice No.')),
      const SizedBox(height:8),
      TextFormField(controller:_remarks,decoration:const InputDecoration(labelText:'Remarks'),maxLines:2),
    ])))),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
      ElevatedButton(onPressed:_save,child:Text(widget.purchase==null?'Create':'Update')),
    ],
  );
}
