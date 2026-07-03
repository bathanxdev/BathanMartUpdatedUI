import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/app_models.dart';

abstract class CartEvent  extends Equatable { const CartEvent(); @override List<Object?> get props => []; }
class CartLoadEvent   extends CartEvent { const CartLoadEvent(); }
class CartAddEvent    extends CartEvent { final String skuId; final int qty; const CartAddEvent(this.skuId, {this.qty = 1}); @override List<Object?> get props => [skuId, qty]; }
class CartUpdateEvent extends CartEvent { final String skuId; final int qty; const CartUpdateEvent(this.skuId, this.qty); @override List<Object?> get props => [skuId, qty]; }
class CartClearEvent  extends CartEvent { const CartClearEvent(); }

abstract class CartState  extends Equatable { const CartState(); @override List<Object?> get props => []; }
class CartInitialState extends CartState { const CartInitialState(); }
class CartLoadingState extends CartState { const CartLoadingState(); }
class CartLoadedState  extends CartState { final CartModel cart; const CartLoadedState(this.cart); @override List<Object?> get props => [cart]; }
class CartErrorState   extends CartState { final String message; const CartErrorState(this.message); @override List<Object?> get props => [message]; }

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc() : super(const CartInitialState()) {
    on<CartLoadEvent>  ((_, em) async { em(const CartLoadingState()); try { final r = await ApiClient.instance.get('/cart'); em(CartLoadedState(CartModel.fromJson(r['data']))); } catch (err) { em(CartErrorState(err.toString())); } });
    on<CartAddEvent>   ((e, em) async { try { await ApiClient.instance.post('/cart/add', data: {'sku_id': e.skuId, 'qty': e.qty}); add(const CartLoadEvent()); } catch (err) { em(CartErrorState(err.toString())); } });
    on<CartUpdateEvent>((e, em) async { try { await ApiClient.instance.patch('/cart/update', data: {'sku_id': e.skuId, 'qty': e.qty}); add(const CartLoadEvent()); } catch (err) { em(CartErrorState(err.toString())); } });
    on<CartClearEvent> ((_, em) async { try { await ApiClient.instance.delete('/cart/clear'); em(const CartLoadedState(CartModel(items: [], subtotal: 0, itemCount: 0))); } catch (_) {} });
  }
}
