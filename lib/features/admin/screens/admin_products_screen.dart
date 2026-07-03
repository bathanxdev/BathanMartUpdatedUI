import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive.dart';
import '../widgets/admin_widgets.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});
  @override State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}
class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _searchCtrl = TextEditingController();
  String? _originFilter;
  int _page = 1;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _load() => context.read<AdminBloc>().add(AdminLoadProductsEvent(
    search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
    originType: _originFilter, page: _page));

  void _showForm({Map? product}) {
    showDialog(context: context, barrierDismissible: false, builder: (_) => BlocProvider.value(
      value: context.read<AdminBloc>(),
      child: _ProductFormDialog(product: product, onSaved: _load),
    ));
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Product Management'),
      actions: [
        IconButton(icon: const Icon(Icons.add), tooltip: 'Add Product', onPressed: () => _showForm()),
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ],
    ),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(12), child: Column(children: [
        TextField(controller: _searchCtrl,
          decoration: InputDecoration(hintText: 'Search products...', prefixIcon: const Icon(Icons.search,size:18),
            filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: () { setState(() => _page = 1); _load(); }),
          ), onSubmitted: (_) { setState(() => _page = 1); _load(); }),
        const SizedBox(height:8),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
          _fChip('All', null), const SizedBox(width:8),
          _fChip('Local', 'domestic'), const SizedBox(width:8),
          _fChip('Imported', 'international'),
        ])),
      ])),
      Expanded(child: BlocConsumer<AdminBloc, AdminState>(
        listener: (ctx, state) {
          if (state is AdminSuccessState) { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.success)); _load(); }
          if (state is AdminErrorState)   { ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppColors.error)); }
        },
        builder: (ctx, state) {
          if (state is AdminLoadingState) return const Center(child: CircularProgressIndicator());
          if (state is! AdminProductsLoaded || state.products.isEmpty)
            return AdminEmptyState(title: 'No products found', icon: Icons.inventory_2_outlined, actionLabel: 'Add Product', onAction: () => _showForm());
          return Column(children: [
            Expanded(child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: 8),
              itemCount: state.products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final p = state.products[i] as Map;
                final isImport = p['origin_type'] == 'international';
                return Container(padding: const EdgeInsets.all(14), decoration: AppUI.cardDecoration(elevated: true),
                  child: Row(children: [
                    Container(width:50,height:50,decoration:BoxDecoration(color:AppColors.primarySoft,borderRadius:BorderRadius.circular(AppRadius.md)),
                      child: p['thumbnail'] != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md),
                              //child: Image.network('${ApiClient.instance.baseUrl}${p['thumbnail']}', width: 50, height: 50, fit: BoxFit.cover,
                              child: Image.network('${ApiClient.instance.mediaBaseUrl}${p['thumbnail']}', width: 50, height: 50, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 24)))
                          : const Icon(Icons.inventory_2_outlined,color:AppColors.primary,size:24)),
                    const SizedBox(width:12),
                    Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Row(children:[
                        Text(p['product_no']?.toString()??'',style:AppText.caption(color:AppColors.primary)),
                        const SizedBox(width:8),
                        AppUI.badge(isImport?'Import':'Local', isImport?AppColors.info:AppColors.success),
                      ]),
                      const SizedBox(height:2),
                      Text(p['name']?.toString()??'',style:AppText.bodyMd(),maxLines:1,overflow:TextOverflow.ellipsis),
                      if (p['brand']!=null) Text(p['brand']?.toString()??'',style:AppText.caption()),
                      const SizedBox(height:4),
                      Row(children:[
                        Text('Rs.${p['price']}',style:AppText.price(size:15)),
                        const SizedBox(width:12),
                        Text('SKU: ${p['sku_code']??'N/A'}',style:AppText.caption()),
                        const SizedBox(width:12),
                        Text('Stock: ${p['total_available']??0}',style:AppText.caption(color:AppColors.teal)),
                      ]),
                    ])),
                    PopupMenuButton<String>(
                      onSelected:(v){
                        if(v=='edit') _showForm(product:p);
                        if(v=='delete') _confirmDelete(ctx,p['_id']?.toString()??'',p['name']?.toString()??'');
                      },
                      itemBuilder:(_)=>const [
                        PopupMenuItem(value:'edit',child:Row(children:[Icon(Icons.edit_outlined,size:16),SizedBox(width:8),Text('Edit')])),
                        PopupMenuItem(value:'delete',child:Row(children:[Icon(Icons.delete_outline,size:16,color:AppColors.error),SizedBox(width:8),Text('Deactivate',style:TextStyle(color:AppColors.error))])),
                      ]),
                  ]));
              })),
            AdminPagination(page: state.page, total: state.total, limit: 20,
              onPrev: () { if (_page>1) { setState(()=>_page--); _load(); } },
              onNext: () { if (_page*20<state.total) { setState(()=>_page++); _load(); } }),
          ]);
        },
      )),
    ]),
  );

  Widget _fChip(String label, String? val) => ChoiceChip(
    label: Text(label), selected: _originFilter == val,
    onSelected: (_) { setState(() { _originFilter = val; _page = 1; }); _load(); });

  void _confirmDelete(BuildContext ctx, String id, String name) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Deactivate Product'),
      content: Text('Deactivate "$name"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); ctx.read<AdminBloc>().add(AdminDeleteProductEvent(id)); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Deactivate')),
      ],
    ));
  }
}

class _ImageItem {
  final String? url;
  final XFile? file;
  final Uint8List? bytes;
  _ImageItem.existing(this.url) : file = null, bytes = null;
  _ImageItem.newFile(this.file, this.bytes) : url = null;
}

class _ProductFormDialog extends StatefulWidget {
  final Map? product; final VoidCallback onSaved;
  const _ProductFormDialog({this.product, required this.onSaved});
  @override State<_ProductFormDialog> createState() => _ProductFormDialogState();
}
class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _fk = GlobalKey<FormState>();
  late final TextEditingController _name,_title,_brand,_price,_cost,_sku,_desc,_unit,_color,_size,_material,_capacity,_count,_wtVal;
  String _origin='domestic', _status='active', _wtUnit='g', _dimUnit='cm';
  late final TextEditingController _dimL,_dimW,_dimH;
  List<String> _targetAudience = [];
  List<dynamic> _categories=[], _suppliers=[];
  String? _selectedCat, _selectedSup;
  bool _loading = false;
  bool _uploadingImages = false;

  final ImagePicker _picker = ImagePicker();
  List<_ImageItem> _images = [];
  int _thumbnailIndex = 0;

  static const _audiences = ['men','women','boys','girls','babies','unisex'];

  @override void initState() {
    super.initState();
    final p = widget.product;
    _name     = TextEditingController(text:p?['name']?.toString()??'');
    _title    = TextEditingController(text:p?['title']?.toString()??'');
    _brand    = TextEditingController(text:p?['brand']?.toString()??'');
    _price    = TextEditingController(text:p?['price']?.toString()??'');
    _cost     = TextEditingController(text:p?['landed_cost']?.toString()??'');
    _sku      = TextEditingController(text:p?['sku_code']?.toString()??'');
    _desc     = TextEditingController(text:p?['description']?.toString()??'');
    _unit     = TextEditingController(text:p?['unit']?.toString()??'piece');
    _color    = TextEditingController(text:p?['color']?.toString()??'');
    _size     = TextEditingController(text:p?['size']?.toString()??'');
    _material = TextEditingController(text:p?['material']?.toString()??'');
    _capacity = TextEditingController(text:p?['capacity']?.toString()??'');
    _count    = TextEditingController(text:p?['count']?.toString()??'');
    final wt  = p?['weight'] as Map?;
    _wtVal    = TextEditingController(text:wt?['value']?.toString()??'');
    _wtUnit   = wt?['unit']?.toString()??'g';
    final dim = p?['dimensions'] as Map?;
    _dimL     = TextEditingController(text:dim?['length']?.toString()??'');
    _dimW     = TextEditingController(text:dim?['width']?.toString()??'');
    _dimH     = TextEditingController(text:dim?['height']?.toString()??'');
    _dimUnit  = dim?['unit']?.toString()??'cm';
    _origin   = p?['origin_type']?.toString()??'domestic';
    _status   = p?['status']?.toString()??'active';
    _targetAudience = List<String>.from(p?['target_audience']??[]);
    _selectedCat = (p?['category_id'] is Map ? p!['category_id']['_id'] : p?['category_id'])?.toString();
    _selectedSup = (p?['supplier_id'] is Map ? p!['supplier_id']['_id'] : p?['supplier_id'])?.toString();

    final existingImages = List<String>.from(p?['images'] ?? []);
    _images = existingImages.map((u) => _ImageItem.existing(u)).toList();
    final thumb = p?['thumbnail']?.toString();
    if (thumb != null) {
      final idx = existingImages.indexOf(thumb);
      if (idx != -1) _thumbnailIndex = idx;
    }

    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    try {
      final r1 = await ApiClient.instance.get('/categories');
      final r2 = await ApiClient.instance.get('/suppliers');
      if (mounted) setState(() {
        _categories = (r1['data'] as List?) ?? [];
        _suppliers  = (r2['data'] as List?) ?? [];
      });
    } catch (_) {}
  }

  @override void dispose() {
    for (final c in [_name,_title,_brand,_price,_cost,_sku,_desc,_unit,_color,_size,_material,_capacity,_count,_wtVal,_dimL,_dimW,_dimH]) c.dispose();
    super.dispose();
  }

  // ── Image handling ──────────────────────────────────────────
  Future<void> _pickImages() async {
  final picked = await _picker.pickMultiImage(imageQuality: 80);
  if (picked.isEmpty) return;
  final items = <_ImageItem>[];
  for (final f in picked) {
    final bytes = await f.readAsBytes();
    items.add(_ImageItem.newFile(f, bytes));
  }
  setState(() => _images.addAll(items));
}

  void _removeImage(int i) {
    setState(() {
      _images.removeAt(i);
      if (_images.isEmpty) {
        _thumbnailIndex = 0;
      } else if (_thumbnailIndex >= _images.length) {
        _thumbnailIndex = _images.length - 1;
      } else if (_thumbnailIndex > i) {
        _thumbnailIndex--;
      }
    });
  }

 Future<List<String>> _uploadNewImages() async {
  final newItems = _images.where((e) => e.bytes != null).toList();
  if (newItems.isEmpty) return [];

  final files = newItems.map((e) => MapEntry(e.file!.name, e.bytes!)).toList();
  final result = await ApiClient.instance.uploadFiles('/products/upload-images', files);
  return List<String>.from(result['data']['urls']);
}

  Widget _buildImagePicker() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Align(alignment: Alignment.centerLeft, child: Text('Product Images', style: AppText.caption())),
    const SizedBox(height: 6),
    SizedBox(
      height: 90,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (int i = 0; i < _images.length; i++) _imageTile(i),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: 80, height: 80, margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
          ),
        ),
      ]),
    ),
    const SizedBox(height: 4),
    Text('Tap an image to set it as the thumbnail', style: AppText.caption(color: AppColors.textHint)),
  ]);

 Widget _imageTile(int i) {
  final item = _images[i];
  final isThumb = i == _thumbnailIndex;
  return Container(
    width: 80, height: 80, margin: const EdgeInsets.only(right: 8),
    child: Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: item.bytes != null
            ? Image.memory(item.bytes!, width: 80, height: 80, fit: BoxFit.cover)
            // : Image.network('${ApiClient.instance.baseUrl}${item.url}', width: 80, height: 80, fit: BoxFit.cover,
            : Image.network('${ApiClient.instance.mediaBaseUrl}${item.url}', width: 80, height: 80, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: AppColors.surface, child: const Icon(Icons.broken_image))),
      ),
      // Tap-to-select-thumbnail layer — now BELOW the star/X, so it no longer blocks them
      Positioned.fill(child: Material(color: Colors.transparent,
        child: InkWell(borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => setState(() => _thumbnailIndex = i)))),
      if (isThumb)
        Positioned(top: 2, left: 2, child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          child: const Icon(Icons.star, size: 12, color: Colors.white))),
      Positioned(top: 2, right: 2, child: GestureDetector(
        onTap: () => _removeImage(i),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          child: const Icon(Icons.close, size: 12, color: Colors.white)))),
    ]),
  );
}
  // ── Save ────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_fk.currentState!.validate()) return;
    setState(() { _loading = true; _uploadingImages = true; });

    try {
      final newUrls = await _uploadNewImages();
      var newUrlIdx = 0;
      final allUrls = _images.map((item) {
        if (item.url != null) return item.url!;
        return newUrls[newUrlIdx++];
      }).toList();
      final thumbnailUrl = allUrls.isNotEmpty ? allUrls[_thumbnailIndex] : null;

      final data = <String,dynamic>{
        'name':_name.text.trim(), 'price':double.tryParse(_price.text)??0,
        'landed_cost':double.tryParse(_cost.text)??double.tryParse(_price.text)??0,
        'title':_title.text.trim().isEmpty?null:_title.text.trim(),
        'brand':_brand.text.trim().isEmpty?null:_brand.text.trim(),
        'sku_code':_sku.text.trim().isEmpty?null:_sku.text.trim().toUpperCase(),
        'description':_desc.text.trim(), 'unit':_unit.text.trim(),
        'color':_color.text.trim().isEmpty?null:_color.text.trim(),
        'size':_size.text.trim().isEmpty?null:_size.text.trim(),
        'material':_material.text.trim().isEmpty?null:_material.text.trim(),
        'capacity':_capacity.text.trim().isEmpty?null:_capacity.text.trim(),
        if (_count.text.isNotEmpty) 'count':int.tryParse(_count.text),
        'origin_type':_origin, 'status':_status,
        'target_audience':_targetAudience,
        if (_selectedCat!=null) 'category_id':_selectedCat,
        if (_selectedSup!=null) 'supplier_id':_selectedSup,
        if (_wtVal.text.isNotEmpty) 'weight':{'value':double.tryParse(_wtVal.text),'unit':_wtUnit},
        if (_dimL.text.isNotEmpty||_dimW.text.isNotEmpty||_dimH.text.isNotEmpty)
          'dimensions':{'length':double.tryParse(_dimL.text),'width':double.tryParse(_dimW.text),'height':double.tryParse(_dimH.text),'unit':_dimUnit},
        'images': allUrls,
        if (thumbnailUrl != null) 'thumbnail': thumbnailUrl,
      };

      if (!mounted) return;
      if (widget.product != null) {
        context.read<AdminBloc>().add(AdminUpdateProductEvent(widget.product!['_id']?.toString()??'', data));
      } else {
        context.read<AdminBloc>().add(AdminCreateProductEvent(data));
      }
      Navigator.pop(context); widget.onSaved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image upload failed: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() { _loading = false; _uploadingImages = false; });
    }
  }

  @override Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.product==null?'Add Product':'Edit Product'),
    content: SizedBox(width:580,height:600,child:Form(key:_fk,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      // Images
      _buildImagePicker(),
      const SizedBox(height:14),
      // Name & Title
      TextFormField(controller:_name,decoration:const InputDecoration(labelText:'Product Name *'),validator:(v)=>v!.isEmpty?'Required':null),
      const SizedBox(height:10),
      TextFormField(controller:_title,decoration:const InputDecoration(labelText:'Marketing Title')),
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:TextFormField(controller:_brand,decoration:const InputDecoration(labelText:'Brand'))),
        const SizedBox(width:10),
        Expanded(child:TextFormField(controller:_sku,decoration:const InputDecoration(labelText:'SKU Code'))),
      ]),
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:TextFormField(controller:_price,decoration:const InputDecoration(labelText:'Selling Price (Rs.) *'),keyboardType:TextInputType.number,validator:(v)=>v!.isEmpty?'Required':null)),
        const SizedBox(width:10),
        Expanded(child:TextFormField(controller:_cost,decoration:const InputDecoration(labelText:'Landed Cost (Rs.)'))),
      ]),
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:TextFormField(controller:_unit,decoration:const InputDecoration(labelText:'Unit (e.g. piece, kg)'))),
        const SizedBox(width:10),
        Expanded(child:TextFormField(controller:_count,decoration:const InputDecoration(labelText:'Count per Pack'),keyboardType:TextInputType.number)),
      ]),
      const SizedBox(height:10),
      // Category & Supplier
      if (_categories.isNotEmpty) DropdownButtonFormField<String>(
        value:_selectedCat, decoration:const InputDecoration(labelText:'Category'),
        items:_categories.map((c)=>DropdownMenuItem<String>(value:c['_id']?.toString(),child:Text(c['name']?.toString()??''))).toList(),
        onChanged:(v)=>setState(()=>_selectedCat=v)),
      const SizedBox(height:10),
      if (_suppliers.isNotEmpty) DropdownButtonFormField<String>(
        value:_selectedSup, decoration:const InputDecoration(labelText:'Supplier'),
        items:_suppliers.map((s)=>DropdownMenuItem<String>(value:s['_id']?.toString(),child:Text(s['name']?.toString()??''))).toList(),
        onChanged:(v)=>setState(()=>_selectedSup=v)),
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:DropdownButtonFormField<String>(value:_origin,decoration:const InputDecoration(labelText:'Origin'),
          items:const [DropdownMenuItem(value:'domestic',child:Text('Domestic')),DropdownMenuItem(value:'international',child:Text('International'))],
          onChanged:(v)=>setState(()=>_origin=v!))),
        const SizedBox(width:10),
        Expanded(child:DropdownButtonFormField<String>(value:_status,decoration:const InputDecoration(labelText:'Status'),
          items:const [DropdownMenuItem(value:'active',child:Text('Active')),DropdownMenuItem(value:'inactive',child:Text('Inactive')),DropdownMenuItem(value:'draft',child:Text('Draft'))],
          onChanged:(v)=>setState(()=>_status=v!))),
      ]),
      const SizedBox(height:10),
      // Physical attributes
      Row(children:[
        Expanded(child:TextFormField(controller:_color,decoration:const InputDecoration(labelText:'Color'))),
        const SizedBox(width:10),
        Expanded(child:TextFormField(controller:_size,decoration:const InputDecoration(labelText:'Size'))),
      ]),
      const SizedBox(height:10),
      Row(children:[
        Expanded(child:TextFormField(controller:_material,decoration:const InputDecoration(labelText:'Material'))),
        const SizedBox(width:10),
        Expanded(child:TextFormField(controller:_capacity,decoration:const InputDecoration(labelText:'Capacity (e.g. 500ml)'))),
      ]),
      const SizedBox(height:10),
      // Weight
      Row(children:[
        Expanded(flex:3,child:TextFormField(controller:_wtVal,decoration:const InputDecoration(labelText:'Weight'),keyboardType:TextInputType.number)),
        const SizedBox(width:8),
        Expanded(child:DropdownButtonFormField<String>(value:_wtUnit,decoration:const InputDecoration(labelText:'Unit'),
          items:const [DropdownMenuItem(value:'g',child:Text('g')),DropdownMenuItem(value:'kg',child:Text('kg')),DropdownMenuItem(value:'lb',child:Text('lb')),DropdownMenuItem(value:'oz',child:Text('oz'))],
          onChanged:(v)=>setState(()=>_wtUnit=v!))),
      ]),
      const SizedBox(height:10),
      // Dimensions
      Row(children:[
        Expanded(child:TextFormField(controller:_dimL,decoration:const InputDecoration(labelText:'Length'),keyboardType:TextInputType.number)),
        const Padding(padding:EdgeInsets.symmetric(horizontal:4),child:Text('×',style:TextStyle(fontSize:18,color:AppColors.textHint))),
        Expanded(child:TextFormField(controller:_dimW,decoration:const InputDecoration(labelText:'Width'),keyboardType:TextInputType.number)),
        const Padding(padding:EdgeInsets.symmetric(horizontal:4),child:Text('×',style:TextStyle(fontSize:18,color:AppColors.textHint))),
        Expanded(child:TextFormField(controller:_dimH,decoration:const InputDecoration(labelText:'Height'),keyboardType:TextInputType.number)),
        const SizedBox(width:8),
        Expanded(child:DropdownButtonFormField<String>(value:_dimUnit,decoration:const InputDecoration(labelText:'Unit'),
          items:const [DropdownMenuItem(value:'cm',child:Text('cm')),DropdownMenuItem(value:'mm',child:Text('mm')),DropdownMenuItem(value:'m',child:Text('m')),DropdownMenuItem(value:'in',child:Text('in')),DropdownMenuItem(value:'ft',child:Text('ft'))],
          onChanged:(v)=>setState(()=>_dimUnit=v!))),
      ]),
      const SizedBox(height:12),
      // Target audience
      Align(alignment:Alignment.centerLeft,child:Text('Target Audience',style:AppText.caption())),
      const SizedBox(height:6),
      Wrap(spacing:8,runSpacing:6,children:_audiences.map((a)=>FilterChip(
        label:Text(a,style:const TextStyle(fontSize:12)),
        selected:_targetAudience.contains(a),
        onSelected:(v){setState((){v?_targetAudience.add(a):_targetAudience.remove(a);});},
        selectedColor:AppColors.primary.withAlpha(25),
        checkmarkColor:AppColors.primary,
      )).toList()),
      const SizedBox(height:10),
      TextFormField(controller:_desc,decoration:const InputDecoration(labelText:'Description'),maxLines:3),
    ])))),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),
      ElevatedButton(
        onPressed:_loading?null:_save,
        child: _uploadingImages
            ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2, color: Colors.white))
            : Text(widget.product==null?'Create':'Update')),
    ],
  );
}