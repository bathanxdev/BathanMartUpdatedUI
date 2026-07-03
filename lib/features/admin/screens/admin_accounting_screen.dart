import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminAccountingScreen extends StatefulWidget {
  const AdminAccountingScreen({super.key});
  @override State<AdminAccountingScreen> createState() => _AdminAccountingScreenState();
}
class _AdminAccountingScreenState extends State<AdminAccountingScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  List<dynamic> _salesData=[], _purchaseData=[], _supplierPayData=[];
  bool _loadingExtra=false;

  @override void initState(){
    super.initState();
    _tabs=TabController(length:4,vsync:this);
    _tabs.addListener((){if(!_tabs.indexIsChanging)_onTabChange();});
    context.read<AdminBloc>().add(const AdminLoadAccountingEvent());
    _loadExtraData();
  }
  @override void dispose(){_tabs.dispose();super.dispose();}

  void _onTabChange(){
    if(_tabs.index==0) context.read<AdminBloc>().add(const AdminLoadAccountingEvent());
  }

  Future<void> _loadExtraData() async {
    setState(()=>_loadingExtra=true);
    try {
      final r1=await ApiClient.instance.get('/accounting/sales-summary');
      final r2=await ApiClient.instance.get('/accounting/purchase-summary');
      final r3=await ApiClient.instance.get('/accounting/supplier-payments');
      if(mounted) setState((){
        _salesData=(r1['data'] as List?)??[];
        _purchaseData=(r2['data'] as List?)??[];
        _supplierPayData=(r3['data'] as List?)??[];
        _loadingExtra=false;
      });
    } catch(_){if(mounted)setState(()=>_loadingExtra=false);}
  }

  Color _plColor(String s){switch(s){case 'profitable':return AppColors.success;case 'break_even':return AppColors.warning;case 'loss':return AppColors.error;default:return AppColors.textHint;}}
  String _plLabel(String s){switch(s){case 'profitable':return '🟢 Profitable';case 'break_even':return '🟡 Break-even';case 'loss':return '🔴 Loss';default:return '⚪ No Sales';}}

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Accounting'),
      actions:[IconButton(icon:const Icon(Icons.refresh),onPressed:(){context.read<AdminBloc>().add(const AdminLoadAccountingEvent());_loadExtraData();})]),
    body:Column(children:[
      TabBar(controller:_tabs,labelColor:AppColors.primary,unselectedLabelColor:AppColors.textSecondary,
        indicatorColor:AppColors.primary,isScrollable:true,tabAlignment:TabAlignment.start,
        labelStyle:const TextStyle(fontSize:13,fontWeight:FontWeight.w600),
        tabs:const [Tab(text:'Product P&L'),Tab(text:'Sales Summary'),Tab(text:'Purchase Summary'),Tab(text:'Supplier Payments')]),
      Expanded(child:TabBarView(controller:_tabs,children:[
        // ── Tab 1: Product P&L ────────────────────────────
        BlocBuilder<AdminBloc,AdminState>(builder:(ctx,state){
          if(state is AdminLoadingState) return const Center(child:CircularProgressIndicator());
          if(state is AdminErrorState)   return Center(child:Text(state.message));
          if(state is! AdminAccountingLoaded) return const Center(child:Text('Loading...'));
          final summary=state.summary;
          final rows=state.data;
          return CustomScrollView(slivers:[
            // Summary cards
            SliverToBoxAdapter(child:Padding(padding:EdgeInsets.all(context.pagePadding),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('Financial Overview',style:AppText.h2()),
              const SizedBox(height:12),
              GridView.count(crossAxisCount:context.isDesktop?4:2,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:1.6,children:[
                _kpi('Total Revenue','Rs.${summary['total_revenue']??0}',AppColors.success),
                _kpi('Total Cost','Rs.${summary['total_cost']??0}',AppColors.error),
                _kpi('Gross Profit','Rs.${summary['gross_profit']??0}',AppColors.primary),
                _kpi('Overall Margin','${summary['overall_margin']??0}%',AppColors.accent),
                _kpi('Profitable','${summary['profitable']??0} products',AppColors.success),
                _kpi('Loss Making','${summary['loss_making']??0} products',AppColors.error),
                _kpi('No Sales Yet','${summary['no_sales']??0} products',AppColors.textHint),
                _kpi('Unsold Stock','Rs.${summary['unsold_stock_value']??0}',AppColors.warning),
              ]),
            ]))),
            // Product rows
            if(rows.isEmpty) const SliverToBoxAdapter(child:Center(child:Padding(padding:EdgeInsets.all(32),child:Text('No product data yet')))),
            SliverList(delegate:SliverChildBuilderDelegate((ctx,i){
              final row=rows[i] as Map;
              final pl=row['pl_status']?.toString()??'no_sales';
              final margin=row['margin_pct'] as num? ??0;
              return Container(margin:const EdgeInsets.fromLTRB(16,0,16,10),padding:const EdgeInsets.all(16),decoration:AppUI.cardDecoration(elevated:true),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Row(children:[
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Text(row['product_name']?.toString()??'',style:AppText.bodyMd(),maxLines:1,overflow:TextOverflow.ellipsis),
                      Text('${row['product_no']??''} • ${row['category']??''}',style:AppText.caption()),
                    ])),
                    AppUI.badge(_plLabel(pl),_plColor(pl)),
                  ]),
                  const SizedBox(height:10),
                  Row(children:[
                    Expanded(child:_metric('Purchase Rate','Rs.${row['purchase_rate']??0}')),
                    Expanded(child:_metric('Selling Price','Rs.${row['selling_price']??0}')),
                    Expanded(child:_metric('Units Sold','${row['units_sold']??0}')),
                    Expanded(child:_metric('Units Left','${row['units_remaining']??0}')),
                  ]),
                  const SizedBox(height:8),
                  Row(children:[
                    Expanded(child:_metric('Revenue','Rs.${row['revenue']??0}',AppColors.success)),
                    Expanded(child:_metric('Cost','Rs.${row['cost']??0}',AppColors.error)),
                    Expanded(child:_metric('Profit','Rs.${row['gross_profit']??0}',margin>=0?AppColors.success:AppColors.error)),
                    Expanded(child:_metric('Margin','${margin.toStringAsFixed(1)}%',margin>=0?AppColors.success:AppColors.error)),
                  ]),
                  if((row['unsold_stock_value'] as num?)!=null&&(row['unsold_stock_value'] as num)>0)
                    Padding(padding:const EdgeInsets.only(top:8),child:Text('Unsold stock value: Rs.${row['unsold_stock_value']}',style:AppText.caption(color:AppColors.warning))),
                ]));
            },childCount:rows.length)),
          ]);
        }),

        // ── Tab 2: Sales Summary ──────────────────────────
        _loadingExtra?const Center(child:CircularProgressIndicator()):_salesData.isEmpty?const Center(child:Text('No sales data'))
          :ListView.separated(padding:const EdgeInsets.all(16),itemCount:_salesData.length,separatorBuilder:(_,__)=>const SizedBox(height:8),
            itemBuilder:(_,i){
              final r=_salesData[i] as Map;
              final period=r['_id'] as Map?;
              return Container(padding:const EdgeInsets.all(14),decoration:AppUI.cardDecoration(elevated:true),
                child:Row(children:[
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text('${_month(period?['month'])} ${period?['year']}',style:AppText.bodyMd()),
                    Text('${r['total_orders']??0} orders • ${r['total_items']??0} items',style:AppText.caption()),
                  ])),
                  Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                    Text('Rs.${_fmt(r['total_revenue'])}',style:AppText.price(color:AppColors.success,size:16)),
                    Text('Avg: Rs.${_fmt(r['avg_order_value'])}',style:AppText.caption()),
                  ]),
                ]));
            }),

        // ── Tab 3: Purchase Summary ───────────────────────
        _loadingExtra?const Center(child:CircularProgressIndicator()):_purchaseData.isEmpty?const Center(child:Text('No purchase data'))
          :ListView.separated(padding:const EdgeInsets.all(16),itemCount:_purchaseData.length,separatorBuilder:(_,__)=>const SizedBox(height:8),
            itemBuilder:(_,i){
              final r=_purchaseData[i] as Map;
              final period=r['_id'] as Map?;
              return Container(padding:const EdgeInsets.all(14),decoration:AppUI.cardDecoration(elevated:true),
                child:Row(children:[
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text('${_month(period?['month'])} ${period?['year']}',style:AppText.bodyMd()),
                    Text('${r['total_purchases']??0} purchases',style:AppText.caption()),
                    if(r['top_supplier']!=null) Text('Top: ${r['top_supplier']}',style:AppText.caption(color:AppColors.info)),
                  ])),
                  Text('Rs.${_fmt(r['total_amount'])}',style:AppText.price(color:AppColors.error,size:16)),
                ]));
            }),

        // ── Tab 4: Supplier Payments ──────────────────────
        _loadingExtra?const Center(child:CircularProgressIndicator()):_supplierPayData.isEmpty?const Center(child:Text('No payment data'))
          :ListView.separated(padding:const EdgeInsets.all(16),itemCount:_supplierPayData.length,separatorBuilder:(_,__)=>const SizedBox(height:8),
            itemBuilder:(_,i){
              final r=_supplierPayData[i] as Map;
              final outstanding=r['outstanding'] as num? ??0;
              return Container(padding:const EdgeInsets.all(14),decoration:AppUI.cardDecoration(elevated:true),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Row(children:[
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Text(r['supplier_name']?.toString()??'',style:AppText.bodyMd()),
                      Text(r['supplier_no']?.toString()??'',style:AppText.caption(color:AppColors.primary)),
                    ])),
                    if(outstanding>0) AppUI.badge('Outstanding',AppColors.error) else AppUI.badge('Paid',AppColors.success),
                  ]),
                  const SizedBox(height:10),
                  Row(children:[
                    Expanded(child:_metric('Total Purchased','Rs.${_fmt(r['total_purchased'])}')),
                    Expanded(child:_metric('Total Paid','Rs.${_fmt(r['total_paid'])}',AppColors.success)),
                    Expanded(child:_metric('Outstanding','Rs.${_fmt(r['outstanding'])}',outstanding>0?AppColors.error:AppColors.success)),
                    Expanded(child:_metric('Pending POs','${r['pending_count']??0}')),
                  ]),
                ]));
            }),
      ])),
    ]),
  );

  Widget _kpi(String label,String value,Color color)=>Container(padding:const EdgeInsets.all(14),decoration:AppUI.cardDecoration(elevated:true),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Text(label,style:AppText.caption()),
      Text(value,style:AppText.price(color:color,size:18)),
    ]));

  Widget _metric(String label,String value,[Color? color])=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Text(label,style:AppText.caption()),
    Text(value,style:AppText.bodyMd(color:color??AppColors.textPrimary)),
  ]);

  String _month(dynamic m){const months=['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];return months[(m as num?)?.toInt()??0];}
  String _fmt(dynamic v){if(v==null)return '0';final n=num.tryParse(v.toString())??0;return n.toStringAsFixed(2);}
}
