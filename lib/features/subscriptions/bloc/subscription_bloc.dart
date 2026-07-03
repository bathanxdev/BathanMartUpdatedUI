import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/app_models.dart';

abstract class SubscriptionEvent extends Equatable { const SubscriptionEvent(); @override List<Object?> get props => []; }
class SubLoadEvent   extends SubscriptionEvent { const SubLoadEvent(); }
class SubCreateEvent extends SubscriptionEvent { final String skuId, paymentMethod; final int qty, frequencyDays; const SubCreateEvent(this.skuId, this.qty, this.frequencyDays, this.paymentMethod); @override List<Object?> get props => [skuId, qty, frequencyDays]; }
class SubPauseEvent  extends SubscriptionEvent { final String id; final int days; const SubPauseEvent(this.id, this.days); }
class SubResumeEvent extends SubscriptionEvent { final String id; const SubResumeEvent(this.id); }
class SubSkipEvent   extends SubscriptionEvent { final String id; const SubSkipEvent(this.id); }
class SubCancelEvent extends SubscriptionEvent { final String id; const SubCancelEvent(this.id); }

abstract class SubscriptionState extends Equatable { const SubscriptionState(); @override List<Object?> get props => []; }
class SubInitialState extends SubscriptionState { const SubInitialState(); }
class SubLoadingState extends SubscriptionState { const SubLoadingState(); }
class SubLoadedState  extends SubscriptionState { final List<SubscriptionModel> subs; const SubLoadedState(this.subs); @override List<Object?> get props => [subs]; }
class SubCreatedState extends SubscriptionState { final String id; const SubCreatedState(this.id); @override List<Object?> get props => [id]; }
class SubErrorState   extends SubscriptionState { final String message; const SubErrorState(this.message); @override List<Object?> get props => [message]; }

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc() : super(const SubInitialState()) {
    on<SubLoadEvent>  ((_, em) async { em(const SubLoadingState()); try { final r = await ApiClient.instance.get('/subscriptions'); em(SubLoadedState((r['data'] as List).map((s) => SubscriptionModel.fromJson(s)).toList())); } catch (err) { em(SubErrorState(err.toString())); } });
    on<SubCreateEvent>((e, em) async { em(const SubLoadingState()); try { final r = await ApiClient.instance.post('/subscriptions', data: {'sku_id': e.skuId, 'qty': e.qty, 'frequency_days': e.frequencyDays, 'payment_method': e.paymentMethod}); em(SubCreatedState(r['data']['_id']?.toString() ?? '')); } catch (err) { em(SubErrorState(err.toString())); } });
    on<SubPauseEvent> ((e, em) async { try { await ApiClient.instance.patch('/subscriptions/' + e.id + '/pause', data: {'pause_days': e.days}); add(const SubLoadEvent()); } catch (err) { em(SubErrorState(err.toString())); } });
    on<SubResumeEvent>((e, em) async { try { await ApiClient.instance.patch('/subscriptions/' + e.id + '/resume'); add(const SubLoadEvent()); } catch (err) { em(SubErrorState(err.toString())); } });
    on<SubSkipEvent>  ((e, em) async { try { await ApiClient.instance.post('/subscriptions/' + e.id + '/skip-cycle'); add(const SubLoadEvent()); } catch (err) { em(SubErrorState(err.toString())); } });
    on<SubCancelEvent>((e, em) async { try { await ApiClient.instance.delete('/subscriptions/' + e.id); add(const SubLoadEvent()); } catch (err) { em(SubErrorState(err.toString())); } });
  }
}
