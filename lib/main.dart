import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/api/api_client.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/cart/bloc/cart_bloc.dart';
import 'features/products/bloc/product_bloc.dart';
import 'features/orders/bloc/order_bloc.dart';
import 'features/subscriptions/bloc/subscription_bloc.dart';
import 'features/inventory/bloc/inventory_bloc.dart';
import 'features/admin/bloc/admin_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.instance.init();
  runApp(const BathanMartApp());
}

class BathanMartApp extends StatelessWidget {
  const BathanMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()..add(const AuthCheckEvent())),
        BlocProvider(create: (_) => CartBloc()),
        BlocProvider(create: (_) => ProductBloc()),
        BlocProvider(create: (_) => OrderBloc()),
        BlocProvider(create: (_) => SubscriptionBloc()),
        BlocProvider(create: (_) => InventoryBloc()),
        BlocProvider(create: (_) => AdminBloc()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // When user logs out, force navigation to landing page
          if (state is AuthUnauthenticatedState) {
            AppRouter.router.go('/');
          }
        },
        child: MaterialApp.router(
          title: 'Bathan Mart',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          themeMode: ThemeMode.light,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
