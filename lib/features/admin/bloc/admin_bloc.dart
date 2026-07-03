import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_client.dart';

// ── Events ────────────────────────────────────────────────────
abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override List<Object?> get props => [];
}
class AdminLoadDashboardEvent  extends AdminEvent { const AdminLoadDashboardEvent(); }
class AdminLoadProductsEvent   extends AdminEvent { final String? search, categoryId, originType; final int page; const AdminLoadProductsEvent({this.search, this.categoryId, this.originType, this.page=1}); @override List<Object?> get props => [search,categoryId,originType,page]; }
class AdminLoadOrdersEvent     extends AdminEvent { final String? status, channel; final int page; const AdminLoadOrdersEvent({this.status, this.channel, this.page=1}); @override List<Object?> get props => [status,channel,page]; }
class AdminLoadInventoryEvent  extends AdminEvent { const AdminLoadInventoryEvent(); }
class AdminLoadCategoriesEvent extends AdminEvent { const AdminLoadCategoriesEvent(); }
class AdminLoadLocationsEvent  extends AdminEvent { const AdminLoadLocationsEvent(); }
class AdminLoadSuppliersEvent  extends AdminEvent { const AdminLoadSuppliersEvent(); }
class AdminLoadReportsEvent    extends AdminEvent { const AdminLoadReportsEvent(); }
class AdminLoadRFQsEvent       extends AdminEvent { final String? status, supplierId; const AdminLoadRFQsEvent({this.status, this.supplierId}); @override List<Object?> get props => [status,supplierId]; }
class AdminLoadPurchaseOrdersEvent extends AdminEvent { final String? status, supplierId; const AdminLoadPurchaseOrdersEvent({this.status, this.supplierId}); @override List<Object?> get props => [status,supplierId]; }
class AdminLoadPurchasesEvent  extends AdminEvent { final String? status, supplierId; const AdminLoadPurchasesEvent({this.status, this.supplierId}); @override List<Object?> get props => [status,supplierId]; }
class AdminLoadCustomersEvent  extends AdminEvent { final String? type, status, search; const AdminLoadCustomersEvent({this.type, this.status, this.search}); @override List<Object?> get props => [type,status,search]; }
class AdminLoadAccountingEvent extends AdminEvent { final String tab; const AdminLoadAccountingEvent({this.tab='pl'}); @override List<Object?> get props => [tab]; }

class AdminCreateProductEvent  extends AdminEvent { final Map<String,dynamic> data; const AdminCreateProductEvent(this.data); }
class AdminUpdateProductEvent  extends AdminEvent { final String id; final Map<String,dynamic> data; const AdminUpdateProductEvent(this.id, this.data); }
class AdminDeleteProductEvent  extends AdminEvent { final String id; const AdminDeleteProductEvent(this.id); }
class AdminUpdateOrderStatusEvent extends AdminEvent { final String orderId, status; final String? notes; const AdminUpdateOrderStatusEvent(this.orderId, this.status, {this.notes}); }
class AdminCreateCategoryEvent extends AdminEvent { final Map<String,dynamic> data; const AdminCreateCategoryEvent(this.data); }
class AdminCreateLocationEvent extends AdminEvent { final Map<String,dynamic> data; const AdminCreateLocationEvent(this.data); }
class AdminUpdateLocationEvent extends AdminEvent { final String id; final Map<String,dynamic> data; const AdminUpdateLocationEvent(this.id, this.data); }
class AdminDeleteLocationEvent extends AdminEvent { final String id; const AdminDeleteLocationEvent(this.id); }
class AdminCreateSupplierEvent extends AdminEvent { final Map<String,dynamic> data; const AdminCreateSupplierEvent(this.data); }
class AdminUpdateSupplierEvent extends AdminEvent { final String id; final Map<String,dynamic> data; const AdminUpdateSupplierEvent(this.id, this.data); }
class AdminDeleteSupplierEvent extends AdminEvent { final String id; const AdminDeleteSupplierEvent(this.id); }
class AdminCreateRFQEvent      extends AdminEvent { final Map<String,dynamic> data; const AdminCreateRFQEvent(this.data); }
class AdminUpdateRFQEvent      extends AdminEvent { final String id; final Map<String,dynamic> data; const AdminUpdateRFQEvent(this.id, this.data); }
class AdminDeleteRFQEvent      extends AdminEvent { final String id; const AdminDeleteRFQEvent(this.id); }
class AdminSendRFQEmailEvent   extends AdminEvent { final String id; const AdminSendRFQEmailEvent(this.id); }
class AdminCreatePOEvent       extends AdminEvent { final Map<String,dynamic> data; const AdminCreatePOEvent(this.data); }
class AdminUpdatePOEvent       extends AdminEvent { final String id; final Map<String,dynamic> data; const AdminUpdatePOEvent(this.id, this.data); }
class AdminDeletePOEvent       extends AdminEvent { final String id; const AdminDeletePOEvent(this.id); }
class AdminSendPOEmailEvent    extends AdminEvent { final String id; const AdminSendPOEmailEvent(this.id); }
class AdminCreatePurchaseEvent extends AdminEvent { final Map<String,dynamic> data; const AdminCreatePurchaseEvent(this.data); }
class AdminUpdatePurchaseEvent extends AdminEvent { final String id; final Map<String,dynamic> data; const AdminUpdatePurchaseEvent(this.id, this.data); }
class AdminConfirmPurchaseEvent extends AdminEvent { final String id; const AdminConfirmPurchaseEvent(this.id); }
class AdminDeletePurchaseEvent extends AdminEvent { final String id; const AdminDeletePurchaseEvent(this.id); }

// ── States ────────────────────────────────────────────────────
abstract class AdminState extends Equatable { const AdminState(); @override List<Object?> get props => []; }
class AdminInitialState  extends AdminState { const AdminInitialState(); }
class AdminLoadingState  extends AdminState { const AdminLoadingState(); }
class AdminErrorState    extends AdminState { final String message; const AdminErrorState(this.message); @override List<Object?> get props => [message]; }
class AdminSuccessState  extends AdminState { final String message; const AdminSuccessState(this.message); @override List<Object?> get props => [message]; }
class AdminDashboardLoaded     extends AdminState { final Map<String,dynamic> data; const AdminDashboardLoaded(this.data); @override List<Object?> get props => [data]; }
class AdminProductsLoaded      extends AdminState { final List<dynamic> products; final int total, page; const AdminProductsLoaded(this.products, this.total, this.page); @override List<Object?> get props => [products,total,page]; }
class AdminOrdersLoaded        extends AdminState { final List<dynamic> orders; final int total, page; const AdminOrdersLoaded(this.orders, this.total, this.page); @override List<Object?> get props => [orders,total,page]; }
class AdminInventoryLoaded     extends AdminState { final List<dynamic> items, alerts; const AdminInventoryLoaded(this.items, this.alerts); @override List<Object?> get props => [items,alerts]; }
class AdminCategoriesLoaded    extends AdminState { final List<dynamic> categories; const AdminCategoriesLoaded(this.categories); @override List<Object?> get props => [categories]; }
class AdminLocationsLoaded     extends AdminState { final List<dynamic> locations; const AdminLocationsLoaded(this.locations); @override List<Object?> get props => [locations]; }
class AdminSuppliersLoaded     extends AdminState { final List<dynamic> suppliers; const AdminSuppliersLoaded(this.suppliers); @override List<Object?> get props => [suppliers]; }
class AdminReportsLoaded       extends AdminState { final List<dynamic> inventory, orders, subscriptions; const AdminReportsLoaded(this.inventory, this.orders, this.subscriptions); @override List<Object?> get props => [inventory,orders,subscriptions]; }
class AdminRFQsLoaded          extends AdminState { final List<dynamic> rfqs; final int total; const AdminRFQsLoaded(this.rfqs, this.total); @override List<Object?> get props => [rfqs,total]; }
class AdminPurchaseOrdersLoaded extends AdminState { final List<dynamic> pos; final int total; const AdminPurchaseOrdersLoaded(this.pos, this.total); @override List<Object?> get props => [pos,total]; }
class AdminPurchasesLoaded     extends AdminState { final List<dynamic> purchases; final int total; const AdminPurchasesLoaded(this.purchases, this.total); @override List<Object?> get props => [purchases,total]; }
class AdminCustomersLoaded     extends AdminState { final List<dynamic> customers; final int total; const AdminCustomersLoaded(this.customers, this.total); @override List<Object?> get props => [customers,total]; }
class AdminAccountingLoaded    extends AdminState { final List<dynamic> data; final Map<String,dynamic> summary; final String tab; const AdminAccountingLoaded(this.data, this.summary, this.tab); @override List<Object?> get props => [data,summary,tab]; }

// ── BLoC ──────────────────────────────────────────────────────
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  AdminBloc() : super(const AdminInitialState()) {
    on<AdminLoadDashboardEvent> (_onDashboard);
    on<AdminLoadProductsEvent>  (_onProducts);
    on<AdminLoadOrdersEvent>    (_onOrders);
    on<AdminLoadInventoryEvent> (_onInventory);
    on<AdminLoadCategoriesEvent>(_onCategories);
    on<AdminLoadLocationsEvent> (_onLocations);
    on<AdminLoadSuppliersEvent> (_onSuppliers);
    on<AdminLoadReportsEvent>   (_onReports);
    on<AdminLoadRFQsEvent>      (_onRFQs);
    on<AdminLoadPurchaseOrdersEvent>(_onPOs);
    on<AdminLoadPurchasesEvent> (_onPurchases);
    on<AdminLoadCustomersEvent> (_onCustomers);
    on<AdminLoadAccountingEvent>(_onAccounting);
    on<AdminCreateProductEvent> (_onCreateProduct);
    on<AdminUpdateProductEvent> (_onUpdateProduct);
    on<AdminDeleteProductEvent> (_onDeleteProduct);
    on<AdminUpdateOrderStatusEvent>(_onUpdateOrderStatus);
    on<AdminCreateCategoryEvent>(_onCreateCategory);
    on<AdminCreateLocationEvent>(_onCreateLocation);
    on<AdminUpdateLocationEvent>(_onUpdateLocation);
    on<AdminDeleteLocationEvent>(_onDeleteLocation);
    on<AdminCreateSupplierEvent>(_onCreateSupplier);
    on<AdminUpdateSupplierEvent>(_onUpdateSupplier);
    on<AdminDeleteSupplierEvent>(_onDeleteSupplier);
    on<AdminCreateRFQEvent>     (_onCreateRFQ);
    on<AdminUpdateRFQEvent>     (_onUpdateRFQ);
    on<AdminDeleteRFQEvent>     (_onDeleteRFQ);
    on<AdminSendRFQEmailEvent>  (_onSendRFQEmail);
    on<AdminCreatePOEvent>      (_onCreatePO);
    on<AdminUpdatePOEvent>      (_onUpdatePO);
    on<AdminDeletePOEvent>      (_onDeletePO);
    on<AdminSendPOEmailEvent>   (_onSendPOEmail);
    on<AdminCreatePurchaseEvent>(_onCreatePurchase);
    on<AdminUpdatePurchaseEvent>(_onUpdatePurchase);
    on<AdminConfirmPurchaseEvent>(_onConfirmPurchase);
    on<AdminDeletePurchaseEvent>(_onDeletePurchase);
  }

  Future<void> _onDashboard(AdminLoadDashboardEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { final r = await ApiClient.instance.get('/admin/dashboard'); emit(AdminDashboardLoaded(Map<String,dynamic>.from(r['data']))); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }

  Future<void> _onProducts(AdminLoadProductsEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try {
      final p = <String,dynamic>{'page':e.page,'limit':20,'status':'active'};
      if (e.search != null) p['search'] = e.search;
      if (e.categoryId != null) p['category_id'] = e.categoryId;
      if (e.originType != null) p['origin_type'] = e.originType;
      final r = await ApiClient.instance.get('/products', params: p);
      emit(AdminProductsLoaded((r['data'] as List?) ?? [], r['meta']?['total'] ?? 0, e.page));
    } catch (err) { emit(AdminErrorState(err.toString())); }
  }

  Future<void> _onOrders(AdminLoadOrdersEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try {
      final p = <String,dynamic>{'page':e.page,'limit':20};
      if (e.status != null) p['status'] = e.status;
      if (e.channel != null) p['channel'] = e.channel;
      final r = await ApiClient.instance.get('/orders', params: p);
      emit(AdminOrdersLoaded((r['data'] as List?) ?? [], r['meta']?['total'] ?? 0, e.page));
    } catch (err) { emit(AdminErrorState(err.toString())); }
  }

  Future<void> _onInventory(AdminLoadInventoryEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try {
      final r1 = await ApiClient.instance.get('/inventory', params: {'limit':'100'});
      final r2 = await ApiClient.instance.get('/alerts');
      emit(AdminInventoryLoaded((r1['data'] as List?) ?? [], (r2['data'] as List?) ?? []));
    } catch (err) { emit(AdminErrorState(err.toString())); }
  }

  Future<void> _onCategories(AdminLoadCategoriesEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { final r = await ApiClient.instance.get('/categories'); emit(AdminCategoriesLoaded((r['data'] as List?) ?? [])); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }

  Future<void> _onLocations(AdminLoadLocationsEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { final r = await ApiClient.instance.get('/warehouses', params: {'status':'active'}); emit(AdminLocationsLoaded((r['data'] as List?) ?? [])); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }

  Future<void> _onSuppliers(AdminLoadSuppliersEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { final r = await ApiClient.instance.get('/suppliers'); emit(AdminSuppliersLoaded((r['data'] as List?) ?? [])); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }

  Future<void> _onReports(AdminLoadReportsEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try {
      final r1 = await ApiClient.instance.get('/admin/reports/inventory');
      final r2 = await ApiClient.instance.get('/admin/reports/orders');
      final r3 = await ApiClient.instance.get('/admin/reports/subscriptions');
      emit(AdminReportsLoaded((r1['data'] as List?) ?? [], (r2['data'] as List?) ?? [], (r3['data'] as List?) ?? []));
    } catch (err) { emit(AdminErrorState(err.toString())); }
  }

  Future<void> _onRFQs(AdminLoadRFQsEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try {
      final p = <String,dynamic>{};
      if (e.status != null) p['status'] = e.status;
      if (e.supplierId != null) p['supplier_id'] = e.supplierId;
      final r = await ApiClient.instance.get('/rfq', params: p);
      emit(AdminRFQsLoaded((r['data'] as List?) ?? [], r['meta']?['total'] ?? 0));
    } catch (err) { emit(AdminErrorState(err.toString())); }
  }

  Future<void> _onPOs(AdminLoadPurchaseOrdersEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try {
      final p = <String,dynamic>{};
      if (e.status != null) p['status'] = e.status;
      if (e.supplierId != null) p['supplier_id'] = e.supplierId;
      final r = await ApiClient.instance.get('/purchase-orders', params: p);
      emit(AdminPurchaseOrdersLoaded((r['data'] as List?) ?? [], r['meta']?['total'] ?? 0));
    } catch (err) { emit(AdminErrorState(err.toString())); }
  }

  Future<void> _onPurchases(AdminLoadPurchasesEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try {
      final p = <String,dynamic>{};
      if (e.status != null) p['status'] = e.status;
      if (e.supplierId != null) p['supplier_id'] = e.supplierId;
      final r = await ApiClient.instance.get('/purchases', params: p);
      emit(AdminPurchasesLoaded((r['data'] as List?) ?? [], r['meta']?['total'] ?? 0));
    } catch (err) { emit(AdminErrorState(err.toString())); }
  }

  Future<void> _onCustomers(AdminLoadCustomersEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try {
      final p = <String,dynamic>{};
      if (e.type != null) p['type'] = e.type;
      if (e.status != null) p['status'] = e.status;
      if (e.search != null) p['search'] = e.search;
      final r = await ApiClient.instance.get('/customers', params: p);
      emit(AdminCustomersLoaded((r['data'] as List?) ?? [], r['meta']?['total'] ?? 0));
    } catch (err) { emit(AdminErrorState(err.toString())); }
  }

  Future<void> _onAccounting(AdminLoadAccountingEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try {
      final r = await ApiClient.instance.get('/accounting/product-pl');
      final data    = (r['data']?['data'] as List?)    ?? (r['data'] as List?) ?? [];
      final summary = Map<String,dynamic>.from(r['data']?['summary'] as Map? ?? {});
      emit(AdminAccountingLoaded(data, summary, e.tab));
    } catch (err) { emit(AdminErrorState(err.toString())); }
  }

  Future<void> _onCreateProduct(AdminCreateProductEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.post('/products', data: e.data); emit(const AdminSuccessState('Product created')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onUpdateProduct(AdminUpdateProductEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.put('/products/${e.id}', data: e.data); emit(const AdminSuccessState('Product updated')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onDeleteProduct(AdminDeleteProductEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.delete('/products/${e.id}'); emit(const AdminSuccessState('Product deactivated')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onUpdateOrderStatus(AdminUpdateOrderStatusEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.patch('/orders/${e.orderId}/status', data: {'status':e.status,'notes':e.notes??'Updated by admin'}); emit(const AdminSuccessState('Order status updated')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onCreateCategory(AdminCreateCategoryEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.post('/categories', data: e.data); emit(const AdminSuccessState('Category created')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onCreateLocation(AdminCreateLocationEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.post('/warehouses', data: e.data); emit(const AdminSuccessState('Location created')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onUpdateLocation(AdminUpdateLocationEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.put('/warehouses/${e.id}', data: e.data); emit(const AdminSuccessState('Location updated')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onDeleteLocation(AdminDeleteLocationEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.delete('/warehouses/${e.id}'); emit(const AdminSuccessState('Location deactivated')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onCreateSupplier(AdminCreateSupplierEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.post('/suppliers', data: e.data); emit(const AdminSuccessState('Supplier created')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onUpdateSupplier(AdminUpdateSupplierEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.put('/suppliers/${e.id}', data: e.data); emit(const AdminSuccessState('Supplier updated')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onDeleteSupplier(AdminDeleteSupplierEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.delete('/suppliers/${e.id}'); emit(const AdminSuccessState('Supplier deactivated')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onCreateRFQ(AdminCreateRFQEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.post('/rfq', data: e.data); emit(const AdminSuccessState('RFQ created')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onUpdateRFQ(AdminUpdateRFQEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.put('/rfq/${e.id}', data: e.data); emit(const AdminSuccessState('RFQ updated')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onDeleteRFQ(AdminDeleteRFQEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.delete('/rfq/${e.id}'); emit(const AdminSuccessState('RFQ deleted')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onSendRFQEmail(AdminSendRFQEmailEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.post('/rfq/${e.id}/send-email', data: {}); emit(const AdminSuccessState('RFQ email sent to supplier')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onCreatePO(AdminCreatePOEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.post('/purchase-orders', data: e.data); emit(const AdminSuccessState('Purchase Order created')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onUpdatePO(AdminUpdatePOEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.put('/purchase-orders/${e.id}', data: e.data); emit(const AdminSuccessState('Purchase Order updated')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onDeletePO(AdminDeletePOEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.delete('/purchase-orders/${e.id}'); emit(const AdminSuccessState('Purchase Order deleted')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onSendPOEmail(AdminSendPOEmailEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.post('/purchase-orders/${e.id}/send-email', data: {}); emit(const AdminSuccessState('PO email sent to supplier')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onCreatePurchase(AdminCreatePurchaseEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.post('/purchases', data: e.data); emit(const AdminSuccessState('Purchase record created')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onUpdatePurchase(AdminUpdatePurchaseEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.put('/purchases/${e.id}', data: e.data); emit(const AdminSuccessState('Purchase updated')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onConfirmPurchase(AdminConfirmPurchaseEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.post('/purchases/${e.id}/confirm', data: {}); emit(const AdminSuccessState('Purchase confirmed — inventory updated!')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
  Future<void> _onDeletePurchase(AdminDeletePurchaseEvent e, Emitter<AdminState> emit) async {
    emit(const AdminLoadingState());
    try { await ApiClient.instance.delete('/purchases/${e.id}'); emit(const AdminSuccessState('Purchase cancelled')); }
    catch (err) { emit(AdminErrorState(err.toString())); }
  }
}
