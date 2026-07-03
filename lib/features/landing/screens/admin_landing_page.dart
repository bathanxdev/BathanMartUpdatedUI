import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/admin/bloc/admin_bloc.dart';

class AdminLandingPage extends StatefulWidget {
  const AdminLandingPage({super.key});
  @override State<AdminLandingPage> createState() => _AdminLandingPageState();
}
class _AdminLandingPageState extends State<AdminLandingPage> {
  @override void initState() { super.initState(); context.read<AdminBloc>().add(const AdminLoadDashboardEvent()); }

  String get _greeting { final h = DateTime.now().hour; if (h<12) return 'Good morning'; if (h<17) return 'Good afternoon'; return 'Good evening'; }

  void _confirmLogout(BuildContext ctx) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24,20,24,0),
      actionsPadding: const EdgeInsets.fromLTRB(24,16,24,20),
      title: Row(children: [
        Container(width:40,height:40,decoration:BoxDecoration(color:Colors.red.withAlpha(20),borderRadius:BorderRadius.circular(10)),child:const Icon(Icons.logout_rounded,color:Colors.red,size:20)),
        const SizedBox(width:12),
        const Text('Sign Out',style:TextStyle(fontSize:18,fontWeight:FontWeight.w700)),
      ]),
      content: const Text('Are you sure you want to sign out of Bathan Mart?',style:TextStyle(fontSize:14,color:Colors.black54,height:1.5)),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(style:TextButton.styleFrom(foregroundColor:Colors.grey[600],padding:const EdgeInsets.symmetric(horizontal:20,vertical:10)),
          onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel',style:TextStyle(fontWeight:FontWeight.w600,fontSize:14))),
        ElevatedButton(onPressed:(){Navigator.pop(ctx);ctx.read<AuthBloc>().add(const AuthLogoutEvent());},
          style:ElevatedButton.styleFrom(backgroundColor:Colors.red,foregroundColor:Colors.white,minimumSize:const Size(0,44),padding:const EdgeInsets.symmetric(horizontal:28),elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12))),
          child:const Text('Sign Out',style:TextStyle(fontWeight:FontWeight.w700,fontSize:14))),
      ],
    ));
  }

  @override Widget build(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    final user = auth is AuthAuthenticatedState ? auth.user : null;
    final firstName = user?.name.split(' ').first ?? 'Admin';
    final isDesktop = context.isDesktop;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<AdminBloc, AdminState>(builder: (ctx, state) {
        final data  = state is AdminDashboardLoaded ? state.data : <String,dynamic>{};
        final today = data['today']         as Map? ?? {};
        final inv   = data['inventory']     as Map? ?? {};
        final riders= data['riders']        as Map? ?? {};
        final subs  = data['subscriptions'] as Map? ?? {};
        final top   = (data['top_products_7d'] as List?) ?? [];
        final loading = state is AdminLoadingState;

        return RefreshIndicator(
          onRefresh: () async => ctx.read<AdminBloc>().add(const AdminLoadDashboardEvent()),
          child: CustomScrollView(slivers: [

            // ── Hero ────────────────────────────────────────
            SliverToBoxAdapter(child: Container(
              decoration: const BoxDecoration(gradient: AppGradients.primary),
              child: SafeArea(bottom:false,child:_PC(
                padding: EdgeInsets.fromLTRB(context.pagePadding,isDesktop?32:20,context.pagePadding,isDesktop?40:28),
                child: Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Row(children:[
                    Container(width:40,height:40,decoration:BoxDecoration(color:Colors.white.withAlpha(20),borderRadius:BorderRadius.circular(AppRadius.md)),child:const Icon(Icons.admin_panel_settings_rounded,color:Colors.white,size:22)),
                    const SizedBox(width:12),
                    Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[Text('Bathan Mart',style:AppText.bodyMd(color:Colors.white)),Text('Operations Panel',style:AppText.caption(color:Colors.white54))]),
                    const Spacer(),
                    IconButton(icon:const Icon(Icons.refresh_rounded,color:Colors.white70),onPressed:()=>ctx.read<AdminBloc>().add(const AdminLoadDashboardEvent())),
                    IconButton(icon:const Icon(Icons.logout_rounded,color:Colors.white70),onPressed:()=>_confirmLogout(ctx),tooltip:'Sign Out'),
                  ]),
                  const SizedBox(height:24),
                  if (isDesktop)
                    Row(crossAxisAlignment:CrossAxisAlignment.end,children:[
                      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                        Text('$_greeting,',style:AppText.bodyLg(color:Colors.white70)),
                        Text(firstName,style:AppText.display(color:Colors.white,size:40)),
                        const SizedBox(height:8),
                        Text("Here's your operations snapshot for today",style:AppText.body(color:Colors.white.withAlpha(180))),
                      ])),
                      if (!loading) Row(children:[
                        _hStat("${today['total']??0}",'Orders Today',Icons.receipt_outlined),
                        const SizedBox(width:12),
                        _hStat("Rs.${today['gmv']??'0'}",'GMV Today',Icons.currency_rupee),
                        const SizedBox(width:12),
                        _hStat("${riders['on_delivery']??0}",'Active Riders',Icons.delivery_dining_outlined),
                      ]),
                    ])
                  else Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text('$_greeting,',style:AppText.body(color:Colors.white70)),
                    Text(firstName,style:AppText.display(color:Colors.white,size:32)),
                    const SizedBox(height:12),
                    if (!loading) Row(children:[
                      _pStat("${today['total']??0}",'Orders'),
                      const SizedBox(width:8),
                      _pStat("Rs.${today['gmv']??'0'}",'GMV'),
                      const SizedBox(width:8),
                      _pStat("${inv['critical']??0}",'Alerts'),
                    ]),
                  ]),
                ]),
              )),
            )),

            // ── KPI Cards ────────────────────────────────────
            SliverToBoxAdapter(child:_PC(
              padding:EdgeInsets.fromLTRB(context.pagePadding,24,context.pagePadding,0),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text("Today's Overview",style:AppText.h2()),
                const SizedBox(height:16),
                if (loading) const Center(child:Padding(padding:EdgeInsets.all(32),child:CircularProgressIndicator()))
                else GridView.count(
                  crossAxisCount:context.kpiColumns, shrinkWrap:true, physics:const NeverScrollableScrollPhysics(),
                  crossAxisSpacing:12, mainAxisSpacing:12, childAspectRatio:isDesktop?1.8:1.4,
                  children:[
                    _kpi("Total Orders","${today['total']??0}",Icons.receipt_outlined,AppColors.primary,"+${today['pending']??0} pending"),
                    _kpi("GMV Today","Rs.${today['gmv']??0}",Icons.currency_rupee_outlined,AppColors.success,"${today['delivered']??0} delivered"),
                    _kpi("Active Riders","${riders['online']??0}",Icons.delivery_dining_outlined,AppColors.teal,"${riders['on_delivery']??0} on delivery"),
                    _kpi("Active Subs","${subs['active']??0}",Icons.repeat_outlined,AppColors.accent,"${subs['due_today']??0} due today"),
                  ].take(context.kpiColumns).toList()),
              ]))),

            // ── Quick Actions ─────────────────────────────────
            SliverToBoxAdapter(child:_PC(
              padding:EdgeInsets.fromLTRB(context.pagePadding,28,context.pagePadding,0),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text('Quick Actions',style:AppText.h2()),
                const SizedBox(height:16),
                // Group 1: Operations
                Text('Operations',style:AppText.label(color:AppColors.textSecondary)),
                const SizedBox(height:10),
                GridView.count(crossAxisCount:isDesktop?5:3,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:isDesktop?1.6:1.1,
                  children:[
                    _act(ctx,'Products',Icons.inventory_2_outlined,AppColors.info,'/admin/products'),
                    _act(ctx,'Orders',Icons.receipt_long_outlined,AppColors.success,'/admin/orders'),
                    _act(ctx,'Inventory',Icons.warehouse_outlined,AppColors.teal,'/admin/inventory'),
                    _act(ctx,'Categories',Icons.category_outlined,AppColors.accent,'/admin/categories'),
                    _act(ctx,'Reports',Icons.bar_chart_outlined,AppColors.success,'/admin/reports'),
                  ]),
                const SizedBox(height:16),
                // Group 2: Procurement
                Text('Procurement',style:AppText.label(color:AppColors.textSecondary)),
                const SizedBox(height:10),
                GridView.count(crossAxisCount:isDesktop?5:3,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:isDesktop?1.6:1.1,
                  children:[
                    _act(ctx,'Locations',Icons.store_outlined,AppColors.primary,'/admin/locations'),
                    _act(ctx,'Suppliers',Icons.local_shipping_outlined,AppColors.info,'/admin/suppliers'),
                    _act(ctx,'RFQ',Icons.request_quote_outlined,AppColors.warning,'/admin/rfq'),
                    _act(ctx,'Purchase Orders',Icons.assignment_outlined,AppColors.accent,'/admin/purchase-orders'),
                    _act(ctx,'Purchases',Icons.shopping_cart_outlined,AppColors.teal,'/admin/purchases'),
                  ]),
                const SizedBox(height:16),
                // Group 3: Business Intelligence
                Text('Business Intelligence',style:AppText.label(color:AppColors.textSecondary)),
                const SizedBox(height:10),
                GridView.count(crossAxisCount:isDesktop?5:3,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),crossAxisSpacing:10,mainAxisSpacing:10,childAspectRatio:isDesktop?1.6:1.1,
                  children:[
                    _act(ctx,'Customers',Icons.people_outlined,AppColors.secondary,'/admin/customers'),
                    _act(ctx,'Accounting',Icons.account_balance_outlined,AppColors.gold,'/admin/accounting'),
                    _act(ctx,'Users',Icons.manage_accounts_outlined,AppColors.teal,'/admin/users'),
                    _act(ctx,'Roles',Icons.admin_panel_settings_outlined,AppColors.warning,'/admin/roles'),
                    _act(ctx,'Audit Log',Icons.history_outlined,AppColors.error,'/admin/audit-logs'),
                  ]),
              ]))),

            if (top.isNotEmpty) SliverToBoxAdapter(child:_PC(
              padding:EdgeInsets.fromLTRB(context.pagePadding,28,context.pagePadding,0),
              child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                AppUI.sectionHeader('Top Products (7 days)'),
                const SizedBox(height:16),
                ...top.asMap().entries.take(5).map((e){
                  final p=e.value as Map;
                  return Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.all(14),decoration:AppUI.cardDecoration(),
                    child:Row(children:[
                      Container(width:36,height:36,decoration:BoxDecoration(color:AppColors.primary.withAlpha(15),borderRadius:BorderRadius.circular(AppRadius.md)),child:Center(child:Text('${e.key+1}',style:AppText.h3(color:AppColors.primary)))),
                      const SizedBox(width:14),
                      Expanded(child:Text(p['name']?.toString()??'',style:AppText.bodyMd())),
                      Text("${p['units']??p['units_sold']??0} units",style:AppText.label(color:AppColors.textSecondary)),
                    ]));
                }),
              ]))),

            SliverToBoxAdapter(child:_PC(
              padding:EdgeInsets.fromLTRB(context.pagePadding,24,context.pagePadding,40),
              child:GestureDetector(onTap:()=>ctx.go('/home'),
                child:Container(padding:const EdgeInsets.all(16),decoration:AppUI.cardDecoration(),
                  child:Row(children:[
                    Container(width:44,height:44,decoration:BoxDecoration(color:AppColors.primarySoft,borderRadius:BorderRadius.circular(AppRadius.md)),child:const Icon(Icons.shopping_bag_outlined,color:AppColors.primary,size:22)),
                    const SizedBox(width:14),
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Visit Customer Store',style:AppText.bodyMd()),Text('See what customers see',style:AppText.caption())])),
                    const Icon(Icons.chevron_right,color:AppColors.textHint),
                  ]))))),
          ]),
        );
      }),
    );
  }

  Widget _hStat(String v,String l,IconData i)=>Container(padding:const EdgeInsets.symmetric(horizontal:20,vertical:14),decoration:BoxDecoration(color:Colors.white.withAlpha(15),borderRadius:BorderRadius.circular(AppRadius.lg)),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(i,color:Colors.white70,size:18),const SizedBox(height:6),Text(v,style:AppText.h2(color:Colors.white)),Text(l,style:AppText.caption(color:Colors.white60))]));
  Widget _pStat(String v,String l)=>Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:8),decoration:BoxDecoration(color:Colors.white.withAlpha(15),borderRadius:BorderRadius.circular(AppRadius.full)),child:Row(mainAxisSize:MainAxisSize.min,children:[Text(v,style:AppText.h3(color:Colors.white)),const SizedBox(width:6),Text(l,style:AppText.caption(color:Colors.white60))]));
  Widget _kpi(String label,String value,IconData icon,Color color,String sub)=>Container(padding:const EdgeInsets.all(16),decoration:AppUI.cardDecoration(elevated:true),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Container(width:36,height:36,decoration:BoxDecoration(color:color.withAlpha(18),borderRadius:BorderRadius.circular(AppRadius.md)),child:Icon(icon,color:color,size:18)),Icon(Icons.trending_up,color:color.withAlpha(120),size:14)]),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:AppText.price(color:color,size:24)),const SizedBox(height:2),Text(label,style:AppText.caption()),Text(sub,style:AppText.caption(color:color.withAlpha(160)))])]));
  Widget _act(BuildContext ctx,String label,IconData icon,Color color,String route)=>GestureDetector(onTap:()=>ctx.go(route),child:Container(padding:const EdgeInsets.all(14),decoration:AppUI.cardDecoration(elevated:true),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Container(width:44,height:44,decoration:BoxDecoration(color:color.withAlpha(18),borderRadius:BorderRadius.circular(AppRadius.lg)),child:Icon(icon,color:color,size:22)),const SizedBox(height:10),Text(label,style:AppText.label(),textAlign:TextAlign.center)])));
}

class _PC extends StatelessWidget {
  final Widget child; final EdgeInsets? padding;
  const _PC({required this.child, this.padding});
  @override Widget build(BuildContext context)=>Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1440),child:Padding(padding:padding??EdgeInsets.symmetric(horizontal:context.pagePadding),child:child)));
}
