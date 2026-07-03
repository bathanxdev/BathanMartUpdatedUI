import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/app_models.dart';

abstract class OrderEvent  extends Equatable { const OrderEvent(); @override List<Object?> get props => []; }
class OrderLoadListEvent   extends OrderEvent { final String? status; const OrderLoadListEvent({this.status}); }
class OrderLoadDetailEvent extends OrderEvent { final String id; const OrderLoadDetailEvent(this.id); @override List<Object?> get props => [id]; }
class OrderPlaceEvent      extends OrderEvent { final List<Map<String, dynamic>> items; final Map<String, dynamic> address; final String paymentMethod, pincode; const OrderPlaceEvent({required this.items, required this.address, required this.paymentMethod, required this.pincode}); }
class OrderCancelEvent     extends OrderEvent { final String id; const OrderCancelEvent(this.id); @override List<Object?> get props => [id]; }

abstract class OrderState  extends Equatable { const OrderState(); @override List<Object?> get props => []; }
class OrderInitialState extends OrderState { const OrderInitialState(); }
class OrderLoadingState extends OrderState { const OrderLoadingState(); }
class OrderListLoaded   extends OrderState { final List<OrderModel> orders; const OrderListLoaded(this.orders); @override List<Object?> get props => [orders]; }
class OrderDetailLoaded extends OrderState { final OrderModel order; const OrderDetailLoaded(this.order); @override List<Object?> get props => [order]; }
class OrderPlacedState  extends OrderState { final String orderId; const OrderPlacedState(this.orderId); @override List<Object?> get props => [orderId]; }
class OrderErrorState   extends OrderState { final String message; const OrderErrorState(this.message); @override List<Object?> get props => [message]; }

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  OrderBloc() : super(const OrderInitialState()) {
    on<OrderLoadListEvent>  ((e, em) async { em(const OrderLoadingState()); try { final p = <String, dynamic>{'limit': 30}; if (e.status != null) p['status'] = e.status; final r = await ApiClient.instance.get('/orders', params: p); em(OrderListLoaded((r['data'] as List).map((o) => OrderModel.fromJson(o)).toList())); } catch (err) { em(OrderErrorState(err.toString())); } });
    on<OrderLoadDetailEvent>((e, em) async { em(const OrderLoadingState()); try { final r = await ApiClient.instance.get('/orders/' + e.id); em(OrderDetailLoaded(OrderModel.fromJson(r['data']))); } catch (err) { em(OrderErrorState(err.toString())); } });
    on<OrderPlaceEvent>     ((e, em) async { em(const OrderLoadingState()); try { final r = await ApiClient.instance.post('/orders', data: {'items': e.items, 'delivery_address': e.address, 'payment_method': e.paymentMethod, 'customer_pincode': e.pincode}); em(OrderPlacedState(r['data']['order_id']?.toString() ?? '')); } catch (err) { em(OrderErrorState(err.toString())); } });
    on<OrderCancelEvent>    ((e, em) async { try { await ApiClient.instance.post('/orders/' + e.id + '/cancel'); add(const OrderLoadListEvent()); } catch (err) { em(OrderErrorState(err.toString())); } });
  }
}
