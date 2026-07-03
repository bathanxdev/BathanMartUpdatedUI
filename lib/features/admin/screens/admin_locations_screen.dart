import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminLocationsScreen extends StatefulWidget {
  const AdminLocationsScreen({super.key});
  @override State<AdminLocationsScreen> createState() => _AdminLocationsScreenState();
}
class _AdminLocationsScreenState extends State<AdminLocationsScreen> {
  @override void initState() { super.initState(); context.read<AdminBloc>().add(const AdminLoadLocationsEvent()); }

  static const _typeLabels = {
    'warehouse':               ('Warehouse',               AppColors.primary,  Icons.warehouse_outlined),
    'selling_point':           ('Selling Point',           AppColors.success,  Icons.storefront_outlined),
    'purchasing_point':        ('Purchasing Point',        AppColors.info,     Icons.input_outlined),
    'selling_purchasing_point':('Selling & Purchasing',    AppColors.accent,   Icons.swap_horiz_outlined),
    'delivering_point':        ('Delivering Point',        AppColors.teal,     Icons.local_shipping_outlined),
  };

  void _showForm({Map? location}) {
    showDialog(context: context, builder: (_) => BlocProvider.value(
      value: context.read<AdminBloc>(),
      child: _LocationForm(location: location, onSaved: () => context.read<AdminBloc>().add(const AdminLoadLocationsEvent())),
    ));
  }

  void _confirmDelete(BuildContext ctx, String id, String name) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Deactivate Location'),
      content: Text('Deactivate "$name"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); ctx.read<AdminBloc>().add(AdminDeleteLocationEvent(id)); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Deactivate')),
      ],
    ));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Locations'),
      actions: [
        IconButton(icon: const Icon(Icons.add), tooltip: 'Add Location', onPressed: () => _showForm()),
        IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<AdminBloc>().add(const AdminLoadLocationsEvent())),
      ],
    ),
    body: BlocConsumer<AdminBloc, AdminState>(
      listener: (ctx, state) {
        if (state is AdminSuccessState) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success)); ctx.read<AdminBloc>().add(const AdminLoadLocationsEvent()); }
        if (state is AdminErrorState)   { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error)); }
      },
      builder: (ctx, state) {
        if (state is AdminLoadingState) return const Center(child: CircularProgressIndicator());
        if (state is! AdminLocationsLoaded || state.locations.isEmpty)
          return AdminEmptyState(title: 'No locations found', icon: Icons.store_outlined, actionLabel: 'Add Location', onAction: () => _showForm());
        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 16),
          itemCount: state.locations.length, separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final loc  = state.locations[i] as Map;
            final type = loc['type']?.toString() ?? 'warehouse';
            final cfg  = _typeLabels[type] ?? ('Location', AppColors.primary, Icons.store_outlined);
            final (label, color, icon) = cfg;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: AppUI.cardDecoration(elevated: true),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width:40,height:40,decoration:BoxDecoration(color:color.withAlpha(18),borderRadius:BorderRadius.circular(AppRadius.md)),child:Icon(icon,color:color,size:20)),
                  const SizedBox(width:12),
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(loc['name']?.toString()??'',style:AppText.h3(),maxLines:1,overflow:TextOverflow.ellipsis),
                    Text(loc['location_no']?.toString()??'',style:AppText.caption()),
                  ])),
                  AppUI.badge(label, color),
                  const SizedBox(width:8),
                  PopupMenuButton<String>(
                    onSelected:(v){ if(v=='edit') _showForm(location:loc); if(v=='delete') _confirmDelete(ctx,loc['_id']?.toString()??'',loc['name']?.toString()??''); },
                    itemBuilder:(_)=>const [
                      PopupMenuItem(value:'edit',child:Row(children:[Icon(Icons.edit_outlined,size:16),SizedBox(width:8),Text('Edit')])),
                      PopupMenuItem(value:'delete',child:Row(children:[Icon(Icons.delete_outline,size:16,color:AppColors.error),SizedBox(width:8),Text('Deactivate',style:TextStyle(color:AppColors.error))])),
                    ]),
                ]),
                const SizedBox(height:12),
                Wrap(spacing:8,runSpacing:6,children:[
                  if (loc['city']!=null) _chip(Icons.location_city_outlined,'${loc['city']}${loc['country']!=null?", ${loc['country']}":""}'),
                  if (loc['phone']!=null) _chip(Icons.phone_outlined,loc['phone']?.toString()??''),
                  if (loc['manager_name']!=null) _chip(Icons.person_outline,loc['manager_name']?.toString()??''),
                  _chip(Icons.inventory_2_outlined,'${loc['sku_count']??0} SKUs • ${loc['total_units']??0} units'),
                ]),
                if (loc['address']!=null) ...[
                  const SizedBox(height:8),
                  Text(loc['address']?.toString()??'',style:AppText.caption(),maxLines:2,overflow:TextOverflow.ellipsis),
                ],
              ]),
            );
          },
        );
      },
    ),
  );

  Widget _chip(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal:10,vertical:5),
    decoration: BoxDecoration(color:AppColors.surfaceWarm,borderRadius:BorderRadius.circular(AppRadius.full),border:Border.all(color:AppColors.border)),
    child: Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:13,color:AppColors.textHint),const SizedBox(width:4),Text(text,style:AppText.caption())]));
}

class _LocationForm extends StatefulWidget {
  final Map? location; final VoidCallback onSaved;
  const _LocationForm({this.location, required this.onSaved});
  @override State<_LocationForm> createState() => _LocationFormState();
}
class _LocationFormState extends State<_LocationForm> {
  final _fk = GlobalKey<FormState>();
  late final TextEditingController _name,_city,_state,_country,_address,_pincode,_phone,_email,_manager,_capacity,_openHr,_closeHr;
  String _type = 'warehouse';

  @override void initState() {
    super.initState();
    final l = widget.location;
    _name    = TextEditingController(text:l?['name']?.toString()??'');
    _city    = TextEditingController(text:l?['city']?.toString()??'');
    _state   = TextEditingController(text:l?['state']?.toString()??'');
    _country = TextEditingController(text:l?['country']?.toString()??'Nepal');
    _address = TextEditingController(text:l?['address']?.toString()??'');
    _pincode = TextEditingController(text:l?['pincode']?.toString()??'');
    _phone   = TextEditingController(text:l?['phone']?.toString()??'');
    _email   = TextEditingController(text:l?['email']?.toString()??'');
    _manager = TextEditingController(text:l?['manager_name']?.toString()??'');
    _capacity= TextEditingController(text:l?['capacity_sqft']?.toString()??'');
    final oh = l?['operating_hours'];
    _openHr  = TextEditingController(text:oh is Map?(oh['open']?.toString()??'09:00'):'09:00');
    _closeHr = TextEditingController(text:oh is Map?(oh['close']?.toString()??'18:00'):'18:00');
    _type    = l?['type']?.toString()??'warehouse';
  }

  @override void dispose() { for (final c in [_name,_city,_state,_country,_address,_pincode,_phone,_email,_manager,_capacity,_openHr,_closeHr]) c.dispose(); super.dispose(); }

  void _save() {
    if (!_fk.currentState!.validate()) return;
    final data = {
      'name':_name.text.trim(),'type':_type,'city':_city.text.trim(),
      'state':_state.text.trim(),'country':_country.text.trim(),
      'address':_address.text.trim(),'pincode':_pincode.text.trim(),
      'phone':_phone.text.trim(),'email':_email.text.trim(),
      'manager_name':_manager.text.trim(),
      if (_capacity.text.isNotEmpty) 'capacity_sqft':double.tryParse(_capacity.text),
      'operating_hours':{'open':_openHr.text.trim(),'close':_closeHr.text.trim()},
    };
    if (widget.location != null) {
      context.read<AdminBloc>().add(AdminUpdateLocationEvent(widget.location!['_id']?.toString()??'', data));
    } else {
      context.read<AdminBloc>().add(AdminCreateLocationEvent(data));
    }
    Navigator.pop(context);
    widget.onSaved();
  }

  @override Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.location==null?'Add Location':'Edit Location'),
    content: SizedBox(width:500,child:Form(key:_fk,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      TextFormField(controller:_name,decoration:const InputDecoration(labelText:'Location Name *'),validator:(v)=>v!.isEmpty?'Required':null),
      const SizedBox(height:12),
      DropdownButtonFormField<String>(value:_type,decoration:const InputDecoration(labelText:'Location Type *'),
        items:const [
          DropdownMenuItem(value:'warehouse',               child:Text('Warehouse — Storage only')),
          DropdownMenuItem(value:'selling_point',           child:Text('Selling Point — Walk-in sales')),
          DropdownMenuItem(value:'purchasing_point',        child:Text('Purchasing Point — Supplier delivery')),
          DropdownMenuItem(value:'selling_purchasing_point',child:Text('Selling & Purchasing Point')),
          DropdownMenuItem(value:'delivering_point',        child:Text('Delivering Point — Self-pickup')),
        ],
        onChanged:(v)=>setState(()=>_type=v!)),
      const SizedBox(height:12),
      TextFormField(controller:_address,decoration:const InputDecoration(labelText:'Address'),maxLines:2),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:TextFormField(controller:_city,decoration:const InputDecoration(labelText:'City *'),validator:(v)=>v!.isEmpty?'Required':null)),
        const SizedBox(width:12),
        Expanded(child:TextFormField(controller:_state,decoration:const InputDecoration(labelText:'State/Province'))),
      ]),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:TextFormField(controller:_country,decoration:const InputDecoration(labelText:'Country'))),
        const SizedBox(width:12),
        Expanded(child:TextFormField(controller:_pincode,decoration:const InputDecoration(labelText:'Pincode'))),
      ]),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:TextFormField(controller:_phone,decoration:const InputDecoration(labelText:'Phone'))),
        const SizedBox(width:12),
        Expanded(child:TextFormField(controller:_email,decoration:const InputDecoration(labelText:'Email'))),
      ]),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:TextFormField(controller:_manager,decoration:const InputDecoration(labelText:'Manager Name'))),
        const SizedBox(width:12),
        Expanded(child:TextFormField(controller:_capacity,decoration:const InputDecoration(labelText:'Capacity (sqft)'),keyboardType:TextInputType.number)),
      ]),
      const SizedBox(height:12),
      Row(children:[
        Expanded(child:TextFormField(controller:_openHr,decoration:const InputDecoration(labelText:'Opens at (e.g. 09:00)'))),
        const SizedBox(width:12),
        Expanded(child:TextFormField(controller:_closeHr,decoration:const InputDecoration(labelText:'Closes at (e.g. 21:00)'))),
      ]),
    ])))),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
      ElevatedButton(onPressed:_save,child:Text(widget.location==null?'Create':'Update')),
    ],
  );
}
