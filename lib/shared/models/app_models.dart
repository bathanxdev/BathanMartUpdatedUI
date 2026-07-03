// Bathan Mart — Shared data models
// Flutter 3.41.6 / Dart 3.11.4

class UserModel {
  final String id, name, role, status;
  final String? email, phone;
  const UserModel({required this.id, required this.name, required this.role, required this.status, this.email, this.phone});
  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(id: j['_id']??j['id'], name: j['name'], role: j['role']??'customer', status: j['status']??'active', email: j['email'], phone: j['phone']);
  bool get isAdmin      => role == 'admin';
  bool get isOperations => role == 'operations';
  bool get isWarehouse  => role == 'warehouse';
  bool get isRider      => role == 'rider';
  bool get isCustomer   => role == 'customer';
  bool get isStaff      => ['admin','operations','warehouse','sourcing'].contains(role);
}

class ProductModel {
  final String id, name, status;
  final String? description, categoryId, categoryName, supplierId, originType, skuCode, unit, thumbnail;
  final double price;
  final double? landedCost;
  final List<String> images, tags;
  final int totalAvailable;
  final bool inStock, expiryTracked;
  final List<StockTierModel> stockByTier;
  const ProductModel({
    required this.id, required this.name, required this.price, required this.status,
    this.description, this.categoryId, this.categoryName, this.supplierId,
    this.originType = 'domestic', this.skuCode, this.unit = 'piece', this.thumbnail,
    this.landedCost, this.images = const [], this.tags = const [],
    this.totalAvailable = 0, this.inStock = false, this.expiryTracked = false,
    this.stockByTier = const [],
  });
  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
    id:             j['_id'] ?? j['id'] ?? '',
    name:           j['name'] ?? '',
    price:          double.tryParse(j['price'].toString()) ?? 0,
    status:         j['status'] ?? 'active',
    description:    j['description'],
    categoryId:     (j['category_id'] is Map ? j['category_id']['_id'] : j['category_id'])?.toString(),
    categoryName:   j['category_id'] is Map ? j['category_id']['name'] : null,
    supplierId:     (j['supplier_id'] is Map ? j['supplier_id']['_id'] : j['supplier_id'])?.toString(),
    originType:     j['origin_type'] ?? 'domestic',
    skuCode:        j['sku_code'],
    unit:           j['unit'] ?? 'piece',
    thumbnail:      j['thumbnail']?.toString(),
    landedCost:     j['landed_cost'] != null ? double.tryParse(j['landed_cost'].toString()) : null,
    totalAvailable: j['total_available'] ?? 0,
    inStock:        (j['in_stock'] as bool?) ?? (j['total_available'] as int? ?? 0) > 0,
    expiryTracked:  j['expiry_tracked'] as bool? ?? false,
    images: List<String>.from(j['images'] ?? []),
    tags:   List<String>.from(j['tags'] ?? []),
    stockByTier: (j['stock_by_tier'] as List?)?.map((s) => StockTierModel.fromJson(s)).toList() ?? [],
  );
  bool get isImported => originType == 'international';
}

class StockTierModel {
  final String? warehouseId, warehouseName, warehouseType, city;
  final int qtyAvailable;
  final String? stockStatus, binLocation;
  const StockTierModel({this.warehouseId, this.warehouseName, this.warehouseType, this.city, required this.qtyAvailable, this.stockStatus, this.binLocation});
  factory StockTierModel.fromJson(Map<String, dynamic> j) => StockTierModel(
    warehouseId:   j['warehouse_id']?.toString(),
    warehouseName: j['warehouse_name'],
    warehouseType: j['warehouse_type'],
    city:          j['city'],
    qtyAvailable:  j['qty_available'] ?? 0,
    stockStatus:   j['stock_status'],
    binLocation:   j['bin_location'],
  );
}

class CartModel {
  final List<CartItemModel> items;
  final double subtotal;
  final int itemCount;
  const CartModel({required this.items, required this.subtotal, required this.itemCount});
  factory CartModel.fromJson(Map<String, dynamic> j) => CartModel(
    items:     (j['items'] as List? ?? []).map((i) => CartItemModel.fromJson(i)).toList(),
    subtotal:  double.tryParse(j['subtotal'].toString()) ?? 0,
    itemCount: j['item_count'] ?? 0,
  );
  CartModel get empty => const CartModel(items: [], subtotal: 0, itemCount: 0);
}

class CartItemModel {
  final String id, skuId, name;
  final int qty;
  final double price, lineTotal;
  final List<String> images;
  const CartItemModel({required this.id, required this.skuId, required this.name, required this.qty, required this.price, required this.lineTotal, this.images = const []});
  factory CartItemModel.fromJson(Map<String, dynamic> j) => CartItemModel(
    id:        j['_id'] ?? j['id'] ?? '',
    skuId:     (j['sku_id'] is Map ? j['sku_id']['_id'] : j['sku_id'])?.toString() ?? '',
    name:      j['name'] ?? (j['sku_id'] is Map ? j['sku_id']['name'] : '') ?? '',
    qty:       j['qty'] ?? 1,
    price:     double.tryParse(j['price'].toString()) ?? 0,
    lineTotal: double.tryParse(j['line_total'].toString()) ?? 0,
    images:    List<String>.from(j['images'] ?? (j['sku_id'] is Map ? j['sku_id']['images'] ?? [] : [])),
  );
}

class OrderModel {
  final String id, status, paymentStatus, channel;
  final double subtotal, deliveryFee, totalAmount;
  final String? fulfillmentTier, deliverySla, paymentMethod;
  final DateTime createdAt;
  final List<OrderItemModel> items;
  final List<OrderEventModel> tracking;
  final Map<String, dynamic>? deliveryAddress;

  const OrderModel({
    required this.id, required this.status, required this.paymentStatus, required this.channel,
    required this.subtotal, required this.deliveryFee, required this.totalAmount, required this.createdAt,
    this.fulfillmentTier, this.deliverySla, this.paymentMethod, this.deliveryAddress,
    this.items = const [], this.tracking = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id:              j['_id'] ?? j['id'] ?? '',
    status:          j['status'] ?? 'confirmed',
    paymentStatus:   j['payment_status'] ?? 'pending',
    channel:         j['channel'] ?? 'app',
    subtotal:        double.tryParse(j['subtotal'].toString()) ?? 0,
    deliveryFee:     double.tryParse(j['delivery_fee'].toString()) ?? 0,
    totalAmount:     double.tryParse(j['total_amount'].toString()) ?? 0,
    fulfillmentTier: j['fulfillment_tier'],
    deliverySla:     j['delivery_sla'],
    paymentMethod:   j['payment_method'],
    deliveryAddress: j['delivery_address'] is Map ? Map<String, dynamic>.from(j['delivery_address']) : null,
    createdAt:       DateTime.tryParse(j['createdAt'] ?? j['created_at'] ?? '') ?? DateTime.now(),
    items:    (j['items']    as List? ?? []).map((i) => OrderItemModel.fromJson(i)).toList(),
    tracking: (j['tracking'] as List? ?? []).map((e) => OrderEventModel.fromJson(e)).toList(),
  );
}

class OrderItemModel {
  final String? id, skuId, productName, fulfillmentTier, deliverySla;
  final int qty;
  final double unitPrice, lineTotal;
  const OrderItemModel({this.id, this.skuId, this.productName, required this.qty, required this.unitPrice, required this.lineTotal, this.fulfillmentTier, this.deliverySla});
  factory OrderItemModel.fromJson(Map<String, dynamic> j) => OrderItemModel(
    id: j['_id']?.toString(), skuId: j['sku_id']?.toString(), productName: j['product_name'],
    qty: j['qty'] ?? 1, unitPrice: double.tryParse(j['unit_price'].toString()) ?? 0, lineTotal: double.tryParse(j['line_total'].toString()) ?? 0,
    fulfillmentTier: j['fulfillment_tier'], deliverySla: j['delivery_sla'],
  );
}

class OrderEventModel {
  final String? id, eventType, description;
  final DateTime createdAt;
  const OrderEventModel({this.id, this.eventType, this.description, required this.createdAt});
  factory OrderEventModel.fromJson(Map<String, dynamic> j) => OrderEventModel(
    id: j['_id']?.toString(), eventType: j['event_type'], description: j['description'],
    createdAt: DateTime.tryParse(j['createdAt'] ?? j['created_at'] ?? '') ?? DateTime.now(),
  );
}

class SubscriptionModel {
  final String id, status, paymentMethod;
  final String? skuId, productName, notes, skipReason;
  final int qty, frequencyDays;
  final double price;
  final DateTime nextRunAt;
  final DateTime? resumeAt;

  const SubscriptionModel({
    required this.id, required this.status, required this.qty, required this.frequencyDays,
    required this.price, required this.nextRunAt, required this.paymentMethod,
    this.skuId, this.productName, this.notes, this.skipReason, this.resumeAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> j) {
    final skuData = j['sku_id'];
    return SubscriptionModel(
      id:            j['_id'] ?? j['id'] ?? '',
      status:        j['status'] ?? 'active',
      qty:           j['qty'] ?? 1,
      frequencyDays: j['frequency_days'] ?? 7,
      paymentMethod: j['payment_method'] ?? 'cod',
      price:         skuData is Map ? double.tryParse(skuData['price'].toString()) ?? 0 : double.tryParse(j['price']?.toString() ?? '0') ?? 0,
      nextRunAt:     DateTime.tryParse(j['next_run_at'] ?? '') ?? DateTime.now(),
      resumeAt:      j['resume_at'] != null ? DateTime.tryParse(j['resume_at']) : null,
      skuId:         skuData is Map ? skuData['_id']?.toString() : skuData?.toString(),
      productName:   skuData is Map ? skuData['name'] : j['product_name'],
      notes:         j['notes'],
      skipReason:    j['skip_reason'],
    );
  }
  double get estimatedMonthlySpend => (price * qty * 30) / frequencyDays;
  bool get isActive  => status == 'active';
  bool get isPaused  => status == 'paused';
}

class InventoryItemModel {
  final String? warehouseId, warehouseName, skuId, productName, skuCode, stockStatus, binLocation;
  final String tier, city;
  final int qtyOnHand, qtyReserved, qtyAvailable, qtyInTransit, rop, msq, roq, maxsq;

  const InventoryItemModel({
    this.warehouseId, this.warehouseName, this.skuId, this.productName, this.skuCode, this.stockStatus, this.binLocation,
    required this.tier, required this.city, required this.qtyOnHand, required this.qtyReserved,
    required this.qtyAvailable, required this.qtyInTransit, required this.rop, required this.msq, required this.roq, required this.maxsq,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> j) {
    final wh   = j['warehouse_id'];
    final prod = j['sku_id'];
    return InventoryItemModel(
      warehouseId:   wh is Map ? wh['_id']?.toString()  : wh?.toString(),
      warehouseName: wh is Map ? wh['name']             : j['warehouse_name'],
      tier:          wh is Map ? (wh['type'] ?? 'MCW')  : (j['tier'] ?? 'MCW'),
      city:          wh is Map ? (wh['city'] ?? '')     : (j['city'] ?? ''),
      skuId:         prod is Map ? prod['_id']?.toString() : prod?.toString(),
      productName:   prod is Map ? prod['name'] : j['product_name'],
      skuCode:       prod is Map ? prod['sku_code'] : j['sku_code'],
      stockStatus:   j['stock_status'] ?? 'Healthy',
      binLocation:   j['bin_location'],
      qtyOnHand:     j['qty_on_hand']    ?? 0,
      qtyReserved:   j['qty_reserved']   ?? 0,
      qtyAvailable:  j['qty_available']  ?? 0,
      qtyInTransit:  j['qty_in_transit'] ?? 0,
      rop:           j['rop']   ?? 10,
      msq:           j['msq']   ?? 5,
      roq:           j['roq']   ?? 20,
      maxsq:         j['maxsq'] ?? 100,
    );
  }
}

class InventoryAlertModel {
  final String id, alertType;
  final String? skuId, productName, warehouseId, warehouseName, tier, actionTaken;
  final int? currentQty, thresholdQty;
  final DateTime triggeredAt;
  final DateTime? resolvedAt;

  const InventoryAlertModel({
    required this.id, required this.alertType, required this.triggeredAt,
    this.skuId, this.productName, this.warehouseId, this.warehouseName, this.tier,
    this.actionTaken, this.currentQty, this.thresholdQty, this.resolvedAt,
  });

  factory InventoryAlertModel.fromJson(Map<String, dynamic> j) {
    final sku = j['sku_id']; final wh = j['warehouse_id'];
    return InventoryAlertModel(
      id:            j['_id'] ?? '',
      alertType:     j['alert_type'] ?? 'ROP',
      skuId:         sku is Map ? sku['_id']?.toString() : sku?.toString(),
      productName:   sku is Map ? sku['name'] : j['product_name'],
      warehouseId:   wh is Map ? wh['_id']?.toString()  : wh?.toString(),
      warehouseName: wh is Map ? wh['name']              : j['warehouse_name'],
      tier:          wh is Map ? wh['type']              : j['tier'],
      currentQty:    j['current_qty'],
      thresholdQty:  j['threshold_qty'],
      actionTaken:   j['action_taken'],
      triggeredAt:   DateTime.tryParse(j['triggered_at'] ?? '') ?? DateTime.now(),
      resolvedAt:    j['resolved_at'] != null ? DateTime.tryParse(j['resolved_at']) : null,
    );
  }
  bool get isCritical => alertType == 'MSQ';
}
