import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminSuppliersScreen extends StatefulWidget {
  const AdminSuppliersScreen({super.key});
  @override State<AdminSuppliersScreen> createState() => _AdminSuppliersScreenState();
}
class _AdminSuppliersScreenState extends State<AdminSuppliersScreen> {
  final _searchCtrl = TextEditingController();
  String? _typeFilter;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _load() => context.read<AdminBloc>().add(const AdminLoadSuppliersEvent());

  void _showForm({Map? supplier}) {
    showDialog(context: context, builder: (_) => BlocProvider.value(
      value: context.read<AdminBloc>(),
      child: _SupplierForm(supplier: supplier, onSaved: _load),
    ));
  }

  void _confirmDelete(BuildContext ctx, String id, String name) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Deactivate Supplier'),
      content: Text('Deactivate "$name"? They will no longer appear in dropdowns.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); ctx.read<AdminBloc>().add(AdminDeleteSupplierEvent(id)); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Deactivate')),
      ],
    ));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Suppliers'),
      actions: [
        IconButton(icon: const Icon(Icons.add), tooltip: 'Add Supplier', onPressed: () => _showForm()),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ],
    ),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Row(children: [
        Expanded(child: TextField(controller: _searchCtrl,
          decoration: InputDecoration(hintText: 'Search suppliers...', prefixIcon: const Icon(Icons.search,size:18),
            filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          ),
          onSubmitted: (_) => _load())),
        const SizedBox(width: 8),
        DropdownButton<String?>(
          value: _typeFilter, hint: const Text('All Types'),
          items: const [
            DropdownMenuItem(value: null, child: Text('All')),
            DropdownMenuItem(value: 'domestic', child: Text('Domestic')),
            DropdownMenuItem(value: 'international', child: Text('International')),
          ],
          onChanged: (v) { setState(() => _typeFilter = v); _load(); },
        ),
      ])),
      Expanded(child: BlocConsumer<AdminBloc, AdminState>(
        listener: (ctx, state) {
          if (state is AdminSuccessState) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success)); _load(); }
          if (state is AdminErrorState)   { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error)); }
        },
        builder: (ctx, state) {
          if (state is AdminLoadingState) return const Center(child: CircularProgressIndicator());
          if (state is! AdminSuppliersLoaded || state.suppliers.isEmpty)
            return AdminEmptyState(title: 'No suppliers found', icon: Icons.local_shipping_outlined, actionLabel: 'Add Supplier', onAction: () => _showForm());
          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 8),
            itemCount: state.suppliers.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final s    = state.suppliers[i] as Map;
              final type = s['type']?.toString() ?? 'domestic';
              final kyc  = s['kyc_status']?.toString() ?? 'pending';
              final score= double.tryParse(s['quality_score']?.toString() ?? '0') ?? 0;
              final isDomestic = type == 'domestic';
              final kycColor = kyc=='verified' ? AppColors.success : kyc=='rejected' ? AppColors.error : AppColors.warning;
              return Container(padding: const EdgeInsets.all(16), decoration: AppUI.cardDecoration(elevated: true),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width:40,height:40,decoration:BoxDecoration(color:(isDomestic?AppColors.success:AppColors.info).withAlpha(18),borderRadius:BorderRadius.circular(AppRadius.md)),
                      child:Icon(isDomestic?Icons.home_work_outlined:Icons.public_outlined,color:isDomestic?AppColors.success:AppColors.info,size:20)),
                    const SizedBox(width:12),
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Text(s['name']?.toString()??'',style:AppText.h3(),maxLines:1,overflow:TextOverflow.ellipsis),
                      Text(s['supplier_no']?.toString()??'',style:AppText.caption()),
                    ])),
                    AppUI.badge(isDomestic?'Domestic':'International', isDomestic?AppColors.success:AppColors.info),
                    const SizedBox(width:8),
                    PopupMenuButton<String>(
                      onSelected:(v){ if(v=='edit') _showForm(supplier:s); if(v=='delete') _confirmDelete(ctx,s['_id']?.toString()??'',s['name']?.toString()??''); },
                      itemBuilder:(_)=>const [
                        PopupMenuItem(value:'edit',child:Row(children:[Icon(Icons.edit_outlined,size:16),SizedBox(width:8),Text('Edit')])),
                        PopupMenuItem(value:'delete',child:Row(children:[Icon(Icons.delete_outline,size:16,color:AppColors.error),SizedBox(width:8),Text('Deactivate',style:TextStyle(color:AppColors.error))])),
                      ]),
                  ]),
                  const SizedBox(height:12),
                  Wrap(spacing:8,runSpacing:6,children:[
                    if(s['city']!=null||s['country']!=null) _chip(Icons.location_on_outlined,'${s['city']??''}${s['country']!=null?", ${s['country']}":''}'),
                    if(s['contact_person']!=null) _chip(Icons.person_outline,s['contact_person']?.toString()??''),
                    if(s['phone']!=null) _chip(Icons.phone_outlined,s['phone']?.toString()??''),
                    if(s['email']!=null) _chip(Icons.email_outlined,s['email']?.toString()??''),
                  ]),
                  const SizedBox(height:12),
                  Row(children:[
                    AppUI.badge('KYC: ${kyc.toUpperCase()}',kycColor),
                    const SizedBox(width:8),
                    const Icon(Icons.star,color:Colors.amber,size:14),
                    Text(' ${score.toStringAsFixed(1)}/100',style:AppText.caption()),
                    const Spacer(),
                    Text('Terms: ${s['payment_terms']??'N/A'}',style:AppText.caption()),
                  ]),
                ]));
            });
        },
      )),
    ]),
  );

  Widget _chip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal:10,vertical:5),
    decoration: BoxDecoration(color:AppColors.surfaceWarm,borderRadius:BorderRadius.circular(AppRadius.full),border:Border.all(color:AppColors.border)),
    child: Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:13,color:AppColors.textHint),const SizedBox(width:4),Text(text,style:AppText.caption())]));
}

class _SupplierForm extends StatefulWidget {
  final Map? supplier; final VoidCallback onSaved;
  const _SupplierForm({this.supplier, required this.onSaved});
  @override State<_SupplierForm> createState() => _SupplierFormState();
}
class _SupplierFormState extends State<_SupplierForm> {
  final _fk = GlobalKey<FormState>();
  late final TextEditingController _name,_email,_phone,_country,_city,_state,_address,_pincode,_contact,_notes;
  String _type='domestic', _kyc='pending', _terms='net30';

  @override void initState() {
    super.initState();
    final s = widget.supplier;
    _name    = TextEditingController(text:s?['name']?.toString()??'');
    _email   = TextEditingController(text:s?['email']?.toString()??'');
    _phone   = TextEditingController(text:s?['phone']?.toString()??'');
    _country = TextEditingController(text:s?['country']?.toString()??'Nepal');
    _city    = TextEditingController(text:s?['city']?.toString()??'');
    _state   = TextEditingController(text:s?['state']?.toString()??'');
    _address = TextEditingController(text:s?['address']?.toString()??'');
    _pincode = TextEditingController(text:s?['pincode']?.toString()??'');
    _contact = TextEditingController(text:s?['contact_person']?.toString()??'');
    _notes   = TextEditingController(text:s?['notes']?.toString()??'');
    _type  = s?['type']?.toString()??'domestic';
    _kyc   = s?['kyc_status']?.toString()??'pending';
    _terms = s?['payment_terms']?.toString()??'net30';
  }

  @override void dispose() { for (final c in [_name,_email,_phone,_country,_city,_state,_address,_pincode,_contact,_notes]) c.dispose(); super.dispose(); }

  void _save() {
    if (!_fk.currentState!.validate()) return;
    final data = {
      'name':_name.text.trim(),'type':_type,'email':_email.text.trim(),
      'phone':_phone.text.trim(),'country':_country.text.trim(),
      'city':_city.text.trim(),'state':_state.text.trim(),
      'address':_address.text.trim(),'pincode':_pincode.text.trim(),
      'contact_person':_contact.text.trim(),'notes':_notes.text.trim(),
      'kyc_status':_kyc,'payment_terms':_terms,
    };
    if (widget.supplier != null) {
      context.read<AdminBloc>().add(AdminUpdateSupplierEvent(widget.supplier!['_id']?.toString()??'', data));
    } else {
      context.read<AdminBloc>().add(AdminCreateSupplierEvent(data));
    }
    Navigator.pop(context); widget.onSaved();
  }

  @override Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.supplier==null?'Add Supplier':'Edit Supplier'),
    content: SizedBox(width:520,child:Form(key:_fk,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextFormField(controller:_name,decoration:const InputDecoration(labelText:'Supplier Name *'),validator:(v)=>v!.isEmpty?'Required':null),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:DropdownButtonFormField<String>(value:_type,decoration:const InputDecoration(labelText:'Type *'),
          items:const [DropdownMenuItem(value:'domestic',child:Text('Domestic')),DropdownMenuItem(value:'international',child:Text('International'))],
          onChanged:(v)=>setState(()=>_type=v!))),
        const SizedBox(width:12),
        Expanded(child:DropdownButtonFormField<String>(value:_kyc,decoration:const InputDecoration(labelText:'KYC Status'),
          items:const [DropdownMenuItem(value:'pending',child:Text('Pending')),DropdownMenuItem(value:'verified',child:Text('Verified')),DropdownMenuItem(value:'rejected',child:Text('Rejected'))],
          onChanged:(v)=>setState(()=>_kyc=v!))),
      ]),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:TextFormField(controller:_email,decoration:const InputDecoration(labelText:'Email'),keyboardType:TextInputType.emailAddress)),
        const SizedBox(width:12),
        Expanded(child:TextFormField(controller:_phone,decoration:const InputDecoration(labelText:'Phone'))),
      ]),
      const SizedBox(height:12),
      TextFormField(controller:_contact,decoration:const InputDecoration(labelText:'Contact Person')),
      const SizedBox(height:12),
      TextFormField(controller:_address,decoration:const InputDecoration(labelText:'Address'),maxLines:2),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:TextFormField(controller:_city,decoration:const InputDecoration(labelText:'City'))),
        const SizedBox(width:12),
        Expanded(child:TextFormField(controller:_state,decoration:const InputDecoration(labelText:'State'))),
      ]),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:TextFormField(controller:_country,decoration:const InputDecoration(labelText:'Country'))),
        const SizedBox(width:12),
        Expanded(child:DropdownButtonFormField<String>(value:_terms,decoration:const InputDecoration(labelText:'Payment Terms'),
          items:const [
            DropdownMenuItem(value:'net15',child:Text('Net 15')),DropdownMenuItem(value:'net30',child:Text('Net 30')),
            DropdownMenuItem(value:'net60',child:Text('Net 60')),DropdownMenuItem(value:'cod',child:Text('COD')),
            DropdownMenuItem(value:'advance',child:Text('Advance')),DropdownMenuItem(value:'lc',child:Text('LC')),
          ],
          onChanged:(v)=>setState(()=>_terms=v!))),
      ]),
      const SizedBox(height:12),
      TextFormField(controller:_notes,decoration:const InputDecoration(labelText:'Internal Notes'),maxLines:2),
    ])))),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
      ElevatedButton(onPressed:_save,child:Text(widget.supplier==null?'Create':'Update')),
    ],
  );
}
