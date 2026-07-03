import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/app_models.dart';

abstract class InventoryEvent extends Equatable { const InventoryEvent(); @override List<Object?> get props => []; }
class InvLoadEvent       extends InventoryEvent { final String? warehouseId; const InvLoadEvent({this.warehouseId}); }
class InvLoadAlertsEvent extends InventoryEvent { const InvLoadAlertsEvent(); }
class InvResolveEvent    extends InventoryEvent { final String id; const InvResolveEvent(this.id); @override List<Object?> get props => [id]; }

abstract class InventoryState extends Equatable { const InventoryState(); @override List<Object?> get props => []; }
class InvInitialState extends InventoryState { const InvInitialState(); }
class InvLoadingState extends InventoryState { const InvLoadingState(); }
class InvLoadedState  extends InventoryState { final List<InventoryItemModel> items; final Map<String, int> summary; const InvLoadedState(this.items, this.summary); @override List<Object?> get props => [items]; }
class InvAlertsState  extends InventoryState { final List<InventoryAlertModel> alerts; const InvAlertsState(this.alerts); @override List<Object?> get props => [alerts]; }
class InvErrorState   extends InventoryState { final String message; const InvErrorState(this.message); @override List<Object?> get props => [message]; }

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  InventoryBloc() : super(const InvInitialState()) {
    on<InvLoadEvent>      ((e, em) async {
      em(const InvLoadingState());
      try {
        final p = <String, dynamic>{'limit': 100};
        if (e.warehouseId != null) p['warehouse_id'] = e.warehouseId;
        final r     = await ApiClient.instance.get('/inventory', params: p);
        final items = (r['data'] as List).map((i) => InventoryItemModel.fromJson(i)).toList();
        final sum   = <String, int>{ 'Healthy': items.where((i) => i.stockStatus == 'Healthy').length, 'Alert': items.where((i) => i.stockStatus == 'Alert').length, 'Critical': items.where((i) => i.stockStatus == 'Critical').length, 'Overstock': items.where((i) => i.stockStatus == 'Overstock').length };
        em(InvLoadedState(items, sum));
      } catch (err) { em(InvErrorState(err.toString())); }
    });
    on<InvLoadAlertsEvent>((_, em) async { em(const InvLoadingState()); try { final r = await ApiClient.instance.get('/alerts'); em(InvAlertsState((r['data'] as List).map((a) => InventoryAlertModel.fromJson(a)).toList())); } catch (err) { em(InvErrorState(err.toString())); } });
    on<InvResolveEvent>   ((e, em) async { try { await ApiClient.instance.patch('/inventory/alerts/' + e.id + '/resolve', data: {'action_taken': 'resolved'}); add(const InvLoadAlertsEvent()); } catch (err) { em(InvErrorState(err.toString())); } });
  }
}
