import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../../../core/api/api_client.dart';

class AdminRFQFormPage extends StatefulWidget {
  final Map? rfq;
  const AdminRFQFormPage({super.key, this.rfq});

  @override
  State<AdminRFQFormPage> createState() => _AdminRFQFormPageState();
}

class _AdminRFQFormPageState extends State<AdminRFQFormPage> {

  final _fk = GlobalKey<FormState>();

  List<dynamic> _products = [];
  List<dynamic> _suppliers = [];

  // ✅ MULTI SUPPLIER
  List<Map<String, dynamic>> _selectedSuppliers = [];

  // PRODUCT ROWS
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _loadData();

    _items.add({
      'product_name': '',
      'qty': 1,
      'unit': 'piece'
    });
  }

  Future<void> _loadData() async {
    final p = await ApiClient.instance.get('/products');
    final s = await ApiClient.instance.get('/suppliers');

    setState(() {
      _products = p['data'] ?? [];
      _suppliers = s['data'] ?? [];
    });
  }

  // ===============================
  // ✅ ADD SUPPLIER (EMAIL STYLE)
  // ===============================
  void _addSupplier(Map supplier) {
    final exists = _selectedSuppliers.any((s) => s['_id'] == supplier['_id']);
    if (!exists) {
      setState(() {
        _selectedSuppliers.add({
          '_id': supplier['_id'],
          'name': supplier['name'],
          'email': supplier['email']
        });
      });
    }
  }

  void _removeSupplier(String id) {
    setState(() {
      _selectedSuppliers.removeWhere((s) => s['_id'] == id);
    });
  }

  // ===============================
  // SAVE
  // ===============================
  void _save() {

    if (_selectedSuppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one supplier"))
      );
      return;
    }

    final data = {
      'supplier_ids': _selectedSuppliers.map((e) => e['_id']).toList(),
      'supplier_emails': _selectedSuppliers.map((e) => e['email']).toList(),
      'items': _items
    };

    context.read<AdminBloc>().add(AdminCreateRFQEvent(data));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create RFQ"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _fk,
          child: Column(
            children: [

              // ===============================
              // ✅ PRODUCT FIRST
              // ===============================
              Expanded(
                child: ListView(
                  children: [

                    const Text("Products", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                    ..._items.asMap().entries.map((e) {
                      int i = e.key;
                      var item = e.value;

                      return Row(
                        children: [

                          Expanded(
                            child: DropdownButtonFormField<String>(
                              hint: const Text("Select Product"),
                              items: _products.map((p) {
                                return DropdownMenuItem(
                                  value: p['_id'].toString(),
                                  child: Text(p['name']),
                                );
                              }).toList(),
                              onChanged: (v) {
                                final p = _products.firstWhere((p) => p['_id'].toString() == v);
                                item['product_name'] = p['name'];
                              },
                            ),
                          ),

                          const SizedBox(width: 10),

                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              initialValue: "1",
                              onChanged: (v) => item['qty'] = int.tryParse(v) ?? 1,
                              decoration: const InputDecoration(labelText: "Qty"),
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() => _items.removeAt(i));
                            },
                          )
                        ],
                      );
                    }),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          _items.add({'product_name': '', 'qty': 1});
                        });
                      },
                      child: const Text("+ Add Product"),
                    ),

                    const SizedBox(height: 20),

                    // ===============================
                    // ✅ MULTI SUPPLIER (EMAIL STYLE)
                    // ===============================
                    const Text("Suppliers"),

                    Wrap(
                      spacing: 8,
                      children: _selectedSuppliers.map((s) {
                        return Chip(
                          label: Text(s['name']),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () => _removeSupplier(s['_id']),
                        );
                      }).toList(),
                    ),

                    DropdownButtonFormField(
                      hint: const Text("Add Supplier"),
                      items: _suppliers.map((s) {
                        return DropdownMenuItem(
                          value: s['_id'],
                          child: Text(s['name']),
                        );
                      }).toList(),
                      onChanged: (v) {
                        final sup = _suppliers.firstWhere((s) => s['_id'] == v);
                        _addSupplier(sup);
                      },
                    ),
                  ],
                ),
              ),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text("Create RFQ"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}