import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/app_models.dart';

abstract class ProductEvent extends Equatable { const ProductEvent(); @override List<Object?> get props => []; }
class ProductLoadListEvent   extends ProductEvent { final String? categoryId, search, originType; final int page; const ProductLoadListEvent({this.categoryId, this.search, this.originType, this.page = 1}); @override List<Object?> get props => [categoryId, search, originType, page]; }
class ProductLoadDetailEvent extends ProductEvent { final String id; const ProductLoadDetailEvent(this.id); @override List<Object?> get props => [id]; }

abstract class ProductState extends Equatable { const ProductState(); @override List<Object?> get props => []; }
class ProductInitialState extends ProductState { const ProductInitialState(); }
class ProductLoadingState extends ProductState { const ProductLoadingState(); }
class ProductListLoaded   extends ProductState { final List<ProductModel> products; final int total, page; const ProductListLoaded(this.products, this.total, this.page); @override List<Object?> get props => [products, total, page]; }
class ProductDetailLoaded extends ProductState { final ProductModel product; const ProductDetailLoaded(this.product); @override List<Object?> get props => [product]; }
class ProductErrorState   extends ProductState { final String message; const ProductErrorState(this.message); @override List<Object?> get props => [message]; }

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  ProductBloc() : super(const ProductInitialState()) {
    on<ProductLoadListEvent>((e, em) async {
      em(const ProductLoadingState());
      try {
        final p = <String, dynamic>{'page': e.page, 'limit': 20};
        if (e.categoryId  != null) p['category_id']  = e.categoryId;
        if (e.search      != null) p['search']        = e.search;
        if (e.originType  != null) p['origin_type']   = e.originType;
        final r = await ApiClient.instance.get('/products', params: p);
        em(ProductListLoaded((r['data'] as List).map((p) => ProductModel.fromJson(p)).toList(), r['meta']?['total'] ?? 0, e.page));
      } catch (err) { em(ProductErrorState(err.toString())); }
    });
    on<ProductLoadDetailEvent>((e, em) async {
      em(const ProductLoadingState());
      try { final r = await ApiClient.instance.get('/products/' + e.id); em(ProductDetailLoaded(ProductModel.fromJson(r['data']))); }
      catch (err) { em(ProductErrorState(err.toString())); }
    });
  }
}
