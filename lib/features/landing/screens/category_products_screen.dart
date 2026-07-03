import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/cart/bloc/cart_bloc.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/storefront_nav.dart';

enum _SortOption { featured, priceLowHigh, priceHighLow, topRated }

const Map<_SortOption, String> _sortLabels = {
  _SortOption.featured: 'Featured',
  _SortOption.priceLowHigh: 'Price: Low to High',
  _SortOption.priceHighLow: 'Price: High to Low',
  _SortOption.topRated: 'Top rated',
};

class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  const CategoryProductsScreen({super.key, required this.categoryId});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<dynamic> _allCategories = [];
  List<dynamic> _products = [];
  bool _loading = true;
  String? _error;

  final Set<String> _selectedBrands = {};
  double _priceFloor = 0, _priceCeil = 100;
  RangeValues _priceRange = const RangeValues(0, 100);
  double? _minRating;
  bool _inStockOnly = false;
  _SortOption _sort = _SortOption.featured;

  @override
  void initState() {
    super.initState();
    _load();
    context.read<CartBloc>().add(const CartLoadEvent());
  }

  @override
  void didUpdateWidget(covariant CategoryProductsScreen old) {
    super.didUpdateWidget(old);
    if (old.categoryId != widget.categoryId) {
      _resetFilters(reload: false);
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/categories'),
        ApiClient.instance.get('/products', params: {
          'category_id': widget.categoryId,
          'limit': '100',
        }),
      ]);
      final categories = (results[0]['data'] as List?) ?? [];
      final products = (results[1]['data'] as List?) ?? [];

      double lo = 0, hi = 100;
      if (products.isNotEmpty) {
        final prices = products
            .map((p) =>
                double.tryParse((p as Map)['price']?.toString() ?? '0') ?? 0)
            .toList();
        lo = prices.reduce((a, b) => a < b ? a : b).floorToDouble();
        hi = prices.reduce((a, b) => a > b ? a : b).ceilToDouble();
        if (hi <= lo) hi = lo + 10;
      }

      if (mounted) {
        setState(() {
          _allCategories = categories;
          _products = products;
          _priceFloor = lo;
          _priceCeil = hi;
          _priceRange = RangeValues(lo, hi);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not load this category';
          _loading = false;
        });
      }
    }
  }

  Map get _category {
    for (final c in _allCategories) {
      if ((c as Map)['_id']?.toString() == widget.categoryId) return c;
    }
    return const {};
  }

  int get _categoryIndex {
    for (var i = 0; i < _allCategories.length; i++) {
      if ((_allCategories[i] as Map)['_id']?.toString() == widget.categoryId) {
        return i;
      }
    }
    return 0;
  }

  List<String> get _availableBrands {
    final set = <String>{};
    for (final p in _products) {
      final b = (p as Map)['brand']?.toString();
      if (b != null && b.trim().isNotEmpty) set.add(b);
    }
    return set.toList()..sort();
  }

  List<dynamic> get _filtered {
    var list = _products.where((p) {
      final m = p as Map;
      final price = double.tryParse(m['price']?.toString() ?? '0') ?? 0;
      if (price < _priceRange.start || price > _priceRange.end) return false;
      if (_selectedBrands.isNotEmpty &&
          !_selectedBrands.contains(m['brand']?.toString() ?? '')) {
        return false;
      }
      if (_minRating != null) {
        final r = double.tryParse(m['rating_avg']?.toString() ?? '0') ?? 0;
        if (r < _minRating!) return false;
      }
      if (_inStockOnly && m['in_stock'] != true) return false;
      return true;
    }).toList();

    double price(dynamic p) =>
        double.tryParse((p as Map)['price']?.toString() ?? '0') ?? 0;
    double rating(dynamic p) =>
        double.tryParse((p as Map)['rating_avg']?.toString() ?? '0') ?? 0;

    switch (_sort) {
      case _SortOption.priceLowHigh:
        list.sort((a, b) => price(a).compareTo(price(b)));
        break;
      case _SortOption.priceHighLow:
        list.sort((a, b) => price(b).compareTo(price(a)));
        break;
      case _SortOption.topRated:
        list.sort((a, b) => rating(b).compareTo(rating(a)));
        break;
      case _SortOption.featured:
        break;
    }
    return list;
  }

  void _resetFilters({bool reload = true}) {
    setState(() {
      _selectedBrands.clear();
      _priceRange = RangeValues(_priceFloor, _priceCeil);
      _minRating = null;
      _inStockOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final auth = context.watch<AuthBloc>().state;
    final user = auth is AuthAuthenticatedState ? auth.user : null;
    final cartState = context.watch<CartBloc>().state;
    final cartCount =
        cartState is CartLoadedState ? cartState.cart.itemCount : 0;

    final name = _category['name']?.toString() ?? '';
    final color = colorForCategoryIndex(_categoryIndex);
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StorefrontTopNavBar(
        user: user,
        cartCount: cartCount,
        isDesktop: isDesktop,
        categories: _allCategories,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 100),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: AppUI.emptyState(
                    title: _error!,
                    icon: Icons.error_outline,
                    message: 'Pull to refresh and try again.',
                  ),
                )
              else
                PageContainer(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: isDesktop ? 24 : 12,
                        horizontal: isDesktop ? 0 : 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Breadcrumb(categoryName: name),
                        const SizedBox(height: 16),
                        _CategoryBanner(
                          name: name,
                          icon: iconForCategory(name),
                          color: color,
                          count: _products.length,
                        ),
                        const SizedBox(height: 28),
                        Text(name,
                            style: AppText.display(
                                size: isDesktop ? 28 : 22,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 18),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 260,
                                child: _FiltersPanel(
                                  brands: _availableBrands,
                                  selectedBrands: _selectedBrands,
                                  priceFloor: _priceFloor,
                                  priceCeil: _priceCeil,
                                  priceRange: _priceRange,
                                  minRating: _minRating,
                                  inStockOnly: _inStockOnly,
                                  onBrandToggle: (b, sel) => setState(() => sel
                                      ? _selectedBrands.add(b)
                                      : _selectedBrands.remove(b)),
                                  onPriceChanged: (v) =>
                                      setState(() => _priceRange = v),
                                  onRatingChanged: (v) =>
                                      setState(() => _minRating = v),
                                  onInStockChanged: (v) =>
                                      setState(() => _inStockOnly = v),
                                  onReset: _resetFilters,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _ResultsArea(
                                  count: filtered.length,
                                  total: _products.length,
                                  sort: _sort,
                                  onSortChanged: (v) =>
                                      setState(() => _sort = v),
                                  products: filtered,
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openMobileFilters(),
                                      icon: const Icon(Icons.tune, size: 18),
                                      label: const Text('Filters'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SortDropdown(
                                      value: _sort,
                                      onChanged: (v) =>
                                          setState(() => _sort = v),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Text(
                                      '${filtered.length} of ${_products.length} items',
                                      style: AppText.caption()),
                                ),
                              ),
                              _ProductsGrid(products: filtered),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              const StorefrontFooter(),
            ],
          ),
        ),
      ),
    );
  }

  void _openMobileFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _FiltersPanel(
                brands: _availableBrands,
                selectedBrands: _selectedBrands,
                priceFloor: _priceFloor,
                priceCeil: _priceCeil,
                priceRange: _priceRange,
                minRating: _minRating,
                inStockOnly: _inStockOnly,
                onBrandToggle: (b, sel) {
                  setState(() =>
                      sel ? _selectedBrands.add(b) : _selectedBrands.remove(b));
                  setSheetState(() {});
                },
                onPriceChanged: (v) {
                  setState(() => _priceRange = v);
                  setSheetState(() {});
                },
                onRatingChanged: (v) {
                  setState(() => _minRating = v);
                  setSheetState(() {});
                },
                onInStockChanged: (v) {
                  setState(() => _inStockOnly = v);
                  setSheetState(() {});
                },
                onReset: () {
                  _resetFilters();
                  setSheetState(() {});
                },
              ),
            ),
          );
        });
      },
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  final String categoryName;
  const _Breadcrumb({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    TextStyle link = AppText.caption(color: AppColors.textSecondary);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        InkWell(onTap: () => context.go('/'), child: Text('Home', style: link)),
        Text('  >  ', style: link),
        InkWell(
            onTap: () => context.go('/categories'),
            child: Text('Categories', style: link)),
        Text('  >  ', style: link),
        Text(categoryName,
            style: AppText.caption(color: AppColors.textPrimary)
                .copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _CategoryBanner extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final int count;
  const _CategoryBanner(
      {required this.name,
      required this.icon,
      required this.color,
      required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: AppColors.textPrimary.withAlpha(200)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name,
                  style:
                      AppText.display(size: 24, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text('$count product${count == 1 ? '' : 's'} available',
                  style: AppText.body(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  final List<String> brands;
  final Set<String> selectedBrands;
  final double priceFloor, priceCeil;
  final RangeValues priceRange;
  final double? minRating;
  final bool inStockOnly;
  final void Function(String brand, bool selected) onBrandToggle;
  final ValueChanged<RangeValues> onPriceChanged;
  final ValueChanged<double?> onRatingChanged;
  final ValueChanged<bool> onInStockChanged;
  final VoidCallback onReset;

  const _FiltersPanel({
    required this.brands,
    required this.selectedBrands,
    required this.priceFloor,
    required this.priceCeil,
    required this.priceRange,
    required this.minRating,
    required this.inStockOnly,
    required this.onBrandToggle,
    required this.onPriceChanged,
    required this.onRatingChanged,
    required this.onInStockChanged,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: AppText.h3()),
              InkWell(
                onTap: onReset,
                child: Text('Reset',
                    style: AppText.bodyMd(
                        color: AppColors.accent, weight: FontWeight.w700)),
              ),
            ],
          ),
          const Divider(height: 28, color: AppColors.border),
          if (brands.isNotEmpty) ...[
            Text('Brand', style: AppText.bodyMd(weight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...brands.map((b) => _CheckRow(
                  label: b,
                  value: selectedBrands.contains(b),
                  onChanged: (v) => onBrandToggle(b, v),
                )),
            const Divider(height: 28, color: AppColors.border),
          ],
          Text('Price', style: AppText.bodyMd(weight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _PriceField(
                label: priceRange.start.toStringAsFixed(0),
                onSubmitted: (v) {
                  final val = double.tryParse(v);
                  if (val == null) return;
                  final clamped = val.clamp(priceFloor, priceRange.end);
                  onPriceChanged(RangeValues(clamped, priceRange.end));
                },
              )),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('–'),
              ),
              Expanded(
                  child: _PriceField(
                label: priceRange.end.toStringAsFixed(0),
                onSubmitted: (v) {
                  final val = double.tryParse(v);
                  if (val == null) return;
                  final clamped = val.clamp(priceRange.start, priceCeil);
                  onPriceChanged(RangeValues(priceRange.start, clamped));
                },
              )),
            ],
          ),
          RangeSlider(
            values: priceRange,
            min: priceFloor,
            max: priceCeil == priceFloor ? priceFloor + 1 : priceCeil,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.border,
            onChanged: onPriceChanged,
          ),
          const Divider(height: 12, color: AppColors.border),
          const SizedBox(height: 16),
          Text('Rating', style: AppText.bodyMd(weight: FontWeight.w700)),
          const SizedBox(height: 8),
          _RatingRadio(
              label: '4★ & up',
              value: 4,
              groupValue: minRating,
              onChanged: onRatingChanged),
          _RatingRadio(
              label: '3★ & up',
              value: 3,
              groupValue: minRating,
              onChanged: onRatingChanged),
          _RatingRadio(
              label: '2★ & up',
              value: 2,
              groupValue: minRating,
              onChanged: onRatingChanged),
          _RatingRadio(
              label: 'All ratings',
              value: null,
              groupValue: minRating,
              onChanged: onRatingChanged),
          const Divider(height: 28, color: AppColors.border),
          Text('Availability', style: AppText.bodyMd(weight: FontWeight.w700)),
          const SizedBox(height: 8),
          _CheckRow(
              label: 'In stock only',
              value: inStockOnly,
              onChanged: onInStockChanged),
        ],
      ),
    );
  }
}

class _PriceField extends StatelessWidget {
  final String label;
  final ValueChanged<String> onSubmitted;
  const _PriceField({required this.label, required this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: label,
      key: ValueKey(label),
      keyboardType: TextInputType.number,
      style: AppText.bodyMd(),
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border)),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CheckRow(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Checkbox(
                value: value,
                activeColor: AppColors.primary,
                onChanged: (v) => onChanged(v ?? false)),
            Expanded(child: Text(label, style: AppText.bodyMd())),
          ],
        ),
      ),
    );
  }
}

class _RatingRadio extends StatelessWidget {
  final String label;
  final double? value, groupValue;
  final ValueChanged<double?> onChanged;
  const _RatingRadio(
      {required this.label,
      required this.value,
      required this.groupValue,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Radio<double?>(
                value: value,
                groupValue: groupValue,
                activeColor: AppColors.accent,
                onChanged: onChanged),
            Expanded(child: Text(label, style: AppText.bodyMd())),
          ],
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final _SortOption value;
  final ValueChanged<_SortOption> onChanged;
  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_SortOption>(
          value: value,
          isExpanded: true,
          items: _sortLabels.entries
              .map((e) => DropdownMenuItem(
                  value: e.key, child: Text(e.value, style: AppText.bodyMd())))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _ResultsArea extends StatelessWidget {
  final int count, total;
  final _SortOption sort;
  final ValueChanged<_SortOption> onSortChanged;
  final List<dynamic> products;
  const _ResultsArea({
    required this.count,
    required this.total,
    required this.sort,
    required this.onSortChanged,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$count of $total items', style: AppText.bodyMd()),
            Row(
              children: [
                Text('Sort: ', style: AppText.bodyMd()),
                SizedBox(
                    width: 200,
                    child:
                        _SortDropdown(value: sort, onChanged: onSortChanged)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ProductsGrid(products: products),
      ],
    );
  }
}

class _ProductsGrid extends StatelessWidget {
  final List<dynamic> products;
  const _ProductsGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: AppUI.emptyState(
          title: 'No products match these filters',
          icon: Icons.search_off,
          message: 'Try widening your price range or clearing a filter.',
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.productColumns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.64,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) =>
          _CategoryProductCard(product: products[i] as Map, colorIndex: i),
    );
  }
}

class _CategoryProductCard extends StatelessWidget {
  final Map product;
  final int colorIndex;
  const _CategoryProductCard({required this.product, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final id = product['_id']?.toString() ?? '';
    final name = product['name']?.toString() ?? '';
    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0;
    final original =
        double.tryParse(product['original_price']?.toString() ?? '') ??
            double.tryParse(product['compare_at_price']?.toString() ?? '');
    final discount = (original != null && original > price)
        ? (((original - price) / original) * 100).round()
        : 0;
    final thumbnail = product['thumbnail']?.toString() ??
        ((product['images'] as List?)?.isNotEmpty == true
            ? (product['images'] as List).first.toString()
            : null);
    final ratingAvg =
        double.tryParse(product['rating_avg']?.toString() ?? '0') ?? 0;
    final ratingCount =
        int.tryParse(product['rating_count']?.toString() ?? '0') ?? 0;
    final brand = product['brand']?.toString() ?? '';
    final bg = colorForCategoryIndex(colorIndex);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.go('/products/$id'),
      child: Container(
        decoration: AppUI.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.1,
              child: Container(
                color: bg,
                child: thumbnail != null && thumbnail.isNotEmpty
                    ? Image.network(thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.shopping_bag_outlined,
                                color: AppColors.textPrimary, size: 36)))
                    : const Center(
                        child: Icon(Icons.shopping_bag_outlined,
                            color: AppColors.textPrimary, size: 36)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand.isNotEmpty)
                    Text(brand.toUpperCase(), style: AppText.caption()),
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyMd(weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  if (ratingCount > 0)
                    Row(children: [
                      const Icon(Icons.star,
                          size: 13, color: Color(0xFFFFB800)),
                      const SizedBox(width: 3),
                      Text('${ratingAvg.toStringAsFixed(1)} ($ratingCount)',
                          style: AppText.caption()),
                    ]),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Rs.${price.toStringAsFixed(2)}',
                          style: AppText.h2(color: AppColors.textPrimary)),
                      if (original != null && original > price) ...[
                        const SizedBox(width: 6),
                        Text('Rs.${original.toStringAsFixed(2)}',
                            style: AppText.caption().copyWith(
                                decoration: TextDecoration.lineThrough)),
                        const SizedBox(width: 4),
                        Text('-$discount%',
                            style: AppText.caption(color: AppColors.accent)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<CartBloc>().add(CartAddEvent(id, qty: 1));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              duration: const Duration(milliseconds: 900),
                              content: Text('Added $name to cart')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.full)),
                      ),
                      child: const Text('Add to cart',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
