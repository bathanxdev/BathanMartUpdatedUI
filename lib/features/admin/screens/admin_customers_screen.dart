import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});
  @override State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}
class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  final _searchCtrl = TextEditingController();
  String? _typeFilter, _statusFilter;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }
  void _load() => context.read<AdminBloc>().add(AdminLoadCustomersEvent(type:_typeFilter,status:_statusFilter,search:_searchCtrl.text.isEmpty?null:_searchCtrl.text));

  Color _roleColor(String r) => r=='b2b'?AppColors.accent:AppColors.info;
  Color _statusColor(String s) { switch(s){ case 'active':return AppColors.success; case 'suspended':return AppColors.warning; default:return AppColors.error; } }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Customer Management'),
      actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        Row(children: [
          Expanded(child: TextField(controller:_searchCtrl,
            decoration: InputDecoration(hintText:'Search by name, email, phone...',prefixIcon:const Icon(Icons.search,size:18),
              filled:true,fillColor:AppColors.surface,
              border:OutlineInputBorder(borderRadius:BorderRadius.circular(10),borderSide:const BorderSide(color:AppColors.border)),
              enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(10),borderSide:const BorderSide(color:AppColors.border)),
              suffixIcon:IconButton(icon:const Icon(Icons.search),onPressed:_load)),
            onSubmitted:(_)=>_load())),
        ]),
        const SizedBox(height:8),
        SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[
          _fChip('All Types',null,_typeFilter==null,()=>setState(()=>_typeFilter=null)),
          const SizedBox(width:8),_fChip('Customer','customer',_typeFilter=='customer',()=>setState(()=>_typeFilter='customer')),
          const SizedBox(width:8),_fChip('B2B','b2b',_typeFilter=='b2b',()=>setState(()=>_typeFilter='b2b')),
          const SizedBox(width:16),
          _fChip('All Status',null,_statusFilter==null,()=>setState(()=>_statusFilter=null)),
          const SizedBox(width:8),_fChip('Active','active',_statusFilter=='active',()=>setState(()=>_statusFilter='active')),
          const SizedBox(width:8),_fChip('Suspended','suspended',_statusFilter=='suspended',()=>setState(()=>_statusFilter='suspended')),
        ])),
      ])),
      Expanded(child:BlocConsumer<AdminBloc,AdminState>(
        listener:(ctx,state){
          if(state is AdminSuccessState){ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text(state.message),backgroundColor:AppColors.success));_load();}
          if(state is AdminErrorState){ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text(state.message),backgroundColor:AppColors.error));}
        },
        builder:(ctx,state){
          if(state is AdminLoadingState)return const Center(child:CircularProgressIndicator());
          if(state is! AdminCustomersLoaded||state.customers.isEmpty)
            return const AdminEmptyState(title:'No customers found',icon:Icons.people_outlined);
          return ListView.separated(
            padding:EdgeInsets.symmetric(horizontal:context.pagePadding,vertical:8),
            itemCount:state.customers.length,separatorBuilder:(_,__)=>const SizedBox(height:10),
            itemBuilder:(_,i){
              final c=state.customers[i] as Map;
              final role=c['role']?.toString()??'customer';
              final status=c['status']?.toString()??'active';
              return GestureDetector(
                onTap:()=>_showDetail(ctx,c['_id']?.toString()??''),
                child:Container(padding:const EdgeInsets.all(16),decoration:AppUI.cardDecoration(elevated:true),
                  child:Row(children:[
                    CircleAvatar(radius:24,backgroundColor:AppColors.primary,child:Text((c['name']?.toString()??'?')[0].toUpperCase(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:18))),
                    const SizedBox(width:12),
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Row(children:[
                        Expanded(child:Text(c['name']?.toString()??'',style:AppText.bodyMd(),maxLines:1,overflow:TextOverflow.ellipsis)),
                        AppUI.badge(role=='b2b'?'B2B':'Customer',_roleColor(role)),
                        const SizedBox(width:6),
                        AppUI.badge(status,_statusColor(status)),
                      ]),
                      if(c['customer_no']!=null) Text(c['customer_no']?.toString()??'',style:AppText.caption(color:AppColors.primary)),
                      Text(c['email']?.toString()??'',style:AppText.caption()),
                      if(c['phone']!=null) Text(c['phone']?.toString()??'',style:AppText.caption()),
                      const SizedBox(height:6),
                      Row(children:[
                        _statBadge('${c['total_orders']??0}','Orders',AppColors.info),
                        const SizedBox(width:8),
                        _statBadge('Rs.${c['total_spent']??'0'}','Spent',AppColors.success),
                      ]),
                    ])),
                    const Icon(Icons.chevron_right,color:AppColors.textHint),
                  ])));
            });
        })),
    ]),
  );

  void _showDetail(BuildContext ctx, String id) async {
    showDialog(context:ctx,builder:(_)=>_CustomerDetailDialog(customerId:id));
  }

  Widget _fChip(String label,String? val,bool selected,VoidCallback onTap)=>FilterChip(label:Text(label,style:const TextStyle(fontSize:12)),selected:selected,onSelected:(_){onTap();_load();},selectedColor:AppColors.primary.withAlpha(20),checkmarkColor:AppColors.primary);
  Widget _statBadge(String val,String label,Color color)=>Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),decoration:BoxDecoration(color:color.withAlpha(15),borderRadius:BorderRadius.circular(AppRadius.full)),child:Text('$val $label',style:AppText.caption(color:color)));
}

class _CustomerDetailDialog extends StatefulWidget {
  final String customerId;
  const _CustomerDetailDialog({required this.customerId});
  @override State<_CustomerDetailDialog> createState()=>_CustomerDetailDialogState();
}
class _CustomerDetailDialogState extends State<_CustomerDetailDialog> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  Map<String,dynamic>? _data;
  bool _loading=true;
  String? _err;

  @override void initState(){super.initState();_tabs=TabController(length:3,vsync:this);_load();}
  @override void dispose(){_tabs.dispose();super.dispose();}

  Future<void> _load() async {
    try {
      final r=await ApiClient.instance.get('/customers/${widget.customerId}');
      if(mounted)setState((){_data=Map<String,dynamic>.from(r['data']);_loading=false;});
    } catch(e){if(mounted)setState((){_err=e.toString();_loading=false;});}
  }

  @override Widget build(BuildContext context){
    return Dialog(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
      child:SizedBox(width:620,height:640,
        child:_loading?const Center(child:CircularProgressIndicator())
          :_err!=null?Center(child:Text(_err!))
          :_buildContent()));
  }

  Widget _buildContent(){
    final d=_data!;
    final stats=d['stats'] as Map?;
    final orders=(d['orders'] as List?)??[];
    final subs=(d['subscriptions'] as List?)??[];
    final addresses=(d['addresses'] as List?)??[];
    final billing=d['billing_address'] as Map?;
    return Column(children:[
      // Header
      Container(padding:const EdgeInsets.all(20),decoration:const BoxDecoration(gradient:AppGradients.primary,borderRadius:BorderRadius.only(topLeft:Radius.circular(16),topRight:Radius.circular(16))),
        child:Row(children:[
          CircleAvatar(radius:28,backgroundColor:Colors.white.withAlpha(30),child:Text((d['name']?.toString()??'?')[0].toUpperCase(),style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:22))),
          const SizedBox(width:16),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(d['name']?.toString()??'',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:18)),
            Text(d['customer_no']?.toString()??'',style:const TextStyle(color:Colors.white70,fontSize:13)),
            Text(d['email']?.toString()??'',style:const TextStyle(color:Colors.white70,fontSize:13)),
          ])),
          Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
            AppUI.badge(d['status']?.toString()??'active',d['status']=='active'?AppColors.success:AppColors.error),
            const SizedBox(height:4),
            TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Close',style:TextStyle(color:Colors.white70))),
          ]),
        ])),
      // Stats row
      Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),color:AppColors.surfaceWarm,
        child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
          _st('${stats?['total_orders']??0}','Orders',AppColors.primary),
          _st('Rs.${stats?['total_spent']??'0'}','Spent',AppColors.success),
          _st('Rs.${stats?['avg_order_value']??'0'}','Avg Order',AppColors.info),
          _st('${stats?['active_subscriptions']??0}','Subs',AppColors.accent),
        ])),
      // Tabs
      TabBar(controller:_tabs,labelColor:AppColors.primary,unselectedLabelColor:AppColors.textSecondary,
        indicatorColor:AppColors.primary,labelStyle:const TextStyle(fontSize:13,fontWeight:FontWeight.w600),
        tabs:const [Tab(text:'Orders'),Tab(text:'Subscriptions'),Tab(text:'Addresses')]),
      Expanded(child:TabBarView(controller:_tabs,children:[
        // Orders
        orders.isEmpty?const Center(child:Text('No orders yet')):ListView.separated(
          padding:const EdgeInsets.all(12),itemCount:orders.length,separatorBuilder:(_,__)=>const SizedBox(height:6),
          itemBuilder:(_,i){
            final o=orders[i] as Map;
            return Container(padding:const EdgeInsets.all(12),decoration:AppUI.cardDecoration(),
              child:Row(children:[
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text('Order #${o['_id']?.toString().substring(0,8)??''}',style:AppText.caption(color:AppColors.primary)),
                  Text('Rs.${o['total_amount']??0} • ${o['payment_method']??''}',style:AppText.bodyMd()),
                  Text('${o['status']??''} • ${o['payment_status']??''}',style:AppText.caption()),
                ])),
                Text(_fd(o['createdAt']),style:AppText.caption()),
              ]));
          }),
        // Subs
        subs.isEmpty?const Center(child:Text('No subscriptions')):ListView.builder(
          padding:const EdgeInsets.all(12),itemCount:subs.length,
          itemBuilder:(_,i){
            final s=subs[i] as Map;
            final sku=s['sku_id'] as Map?;
            return Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),decoration:AppUI.cardDecoration(),
              child:Row(children:[
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(sku?['name']?.toString()??'Product',style:AppText.bodyMd()),
                  Text('Every ${s['frequency_days']} days • Qty: ${s['qty']}',style:AppText.caption()),
                ])),
                AppUI.badge(s['status']?.toString()??'',s['status']=='active'?AppColors.success:AppColors.warning),
              ]));
          }),
        // Addresses
        Column(children:[
          if(billing!=null)...[
            Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Billing Address',style:AppText.bodyMd()),
              const SizedBox(height:6),
              Container(padding:const EdgeInsets.all(12),decoration:AppUI.cardDecoration(),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(billing['name']?.toString()??'',style:AppText.bodyMd()),
                  Text('${billing['line1']??''}, ${billing['city']??''}, ${billing['country']??''}',style:AppText.caption()),
                ])),
            ])),
            const Divider(),
          ],
          Expanded(child:addresses.isEmpty?const Center(child:Text('No delivery addresses')):ListView.builder(
            padding:const EdgeInsets.all(12),itemCount:addresses.length,
            itemBuilder:(_,i){
              final a=addresses[i] as Map;
              return Container(margin:const EdgeInsets.only(bottom:8),padding:const EdgeInsets.all(12),decoration:AppUI.cardDecoration(),
                child:Row(children:[
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Row(children:[Text(a['label']?.toString()??'',style:AppText.bodyMd()),const SizedBox(width:8),if(a['is_default']==true)AppUI.badge('Default',AppColors.primary)]),
                    Text(a['name']?.toString()??'',style:AppText.caption()),
                    Text('${a['line1']??''}, ${a['city']??''}, ${a['country']??''}',style:AppText.caption()),
                  ])),
                ]));
            })),
        ]),
      ])),
    ]);
  }

  Widget _st(String val,String label,Color color)=>Column(children:[Text(val,style:AppText.h3(color:color)),Text(label,style:AppText.caption())]);
  String _fd(dynamic dt){try{return DateTime.parse(dt.toString()).toLocal().toString().substring(0,10);}catch(_){return dt?.toString()??'';}}
}
