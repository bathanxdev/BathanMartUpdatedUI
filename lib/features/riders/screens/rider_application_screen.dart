import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/bloc/auth_bloc.dart';

class RiderApplicationScreen extends StatefulWidget {
  const RiderApplicationScreen({super.key});

  @override
  State<RiderApplicationScreen> createState() => _RiderApplicationScreenState();
}

class _RiderApplicationScreenState extends State<RiderApplicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // TODO: Replace with your Bloc/API call
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Application submitted! Await approval."),
          backgroundColor: Colors.green,
        ),
      );

      context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Rider Application"),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),

              Text(
                "Join as Rider",
                style: AppText.h1(),
              ),

              const SizedBox(height: 20),

              // NAME
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter your name" : null,
              ),

              const SizedBox(height: 16),

              // ADDRESS
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                  labelText: "Address",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter your address" : null,
              ),

              const SizedBox(height: 16),

              // VEHICLE
              TextFormField(
                controller: _vehicleCtrl,
                decoration: const InputDecoration(
                  labelText: "Vehicle Type (Bike/Scooter)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter vehicle type" : null,
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit Application"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}