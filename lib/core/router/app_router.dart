import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/landing/screens/customer_landing_page.dart';
import '../../features/landing/screens/admin_landing_page.dart';
import '../../features/landing/screens/rider_landing_page.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/products/screens/product_list_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/orders/screens/order_list_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/checkout_screen.dart';
import '../../features/subscriptions/screens/subscription_list_screen.dart';
import '../../features/subscriptions/screens/create_subscription_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_products_screen.dart';
import '../../features/admin/screens/admin_orders_screen.dart';
import '../../features/admin/screens/admin_inventory_screen.dart';
import '../../features/admin/screens/admin_categories_screen.dart';
import '../../features/admin/screens/admin_locations_screen.dart';
import '../../features/admin/screens/admin_suppliers_screen.dart';
import '../../features/admin/screens/admin_reports_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_roles_screen.dart';
import '../../features/admin/screens/admin_audit_log_screen.dart';
import '../../features/admin/screens/admin_rfq_screen.dart';
import '../../features/admin/screens/admin_rfq_form_page.dart';
import '../../features/admin/screens/admin_purchase_orders_screen.dart';
import '../../features/admin/screens/admin_purchase_screen.dart';
import '../../features/admin/screens/admin_customers_screen.dart';
import '../../features/admin/screens/admin_accounting_screen.dart';
import '../../features/riders/screens/rider_screen.dart';
import '../../features/riders/screens/rider_intro_screen.dart';
import '../../shared/widgets/main_shell.dart';

class AppRouter {
  AppRouter._();
  static final _rootKey  = GlobalKey<NavigatorState>();
  static final _shellKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootKey, initialLocation: '/',
    redirect: (ctx, state) {
      final auth   = ctx.read<AuthBloc>().state;
      final isAuth = auth is AuthAuthenticatedState;
      final loc    = state.matchedLocation;
      if (!isAuth) {
        final protected = ['/cart','/checkout','/orders','/subscriptions','/admin','/admin-home','/rider-home','/inventory','/home','/welcome'];
        if (protected.any((r) => loc.startsWith(r))) return '/';
      }
      if (isAuth && (loc == '/login' || loc == '/register' || loc == '/'))
        return _landing((auth as AuthAuthenticatedState).user.role);
      return null;
    },
    routes: [
      GoRoute(path:'/',                   builder:(_,__)=>const CustomerLandingPage()),
      GoRoute(path:'/login',              builder:(_,__)=>const LoginScreen()),
      GoRoute(path:'/register',           builder:(_,__)=>const RegisterScreen()),
      GoRoute(path:'/otp',                builder:(_,s) =>OtpScreen(phone:s.extra as String?)),
      GoRoute(path:'/forgot-password',    builder:(_,__)=>const ForgotPasswordScreen()),
      GoRoute(path:'/welcome',            builder:(_,__)=>const CustomerLandingPage()),
      GoRoute(path:'/admin-home',         builder:(_,__)=>const AdminLandingPage()),
      GoRoute(path:'/rider-home',         builder:(_,__)=>const RiderScreen()),
      GoRoute(path:'/rider-intro',        builder:(_,__)=>const RiderIntroScreen()),
      GoRoute(path:'/admin',              builder:(_,__)=>const AdminDashboardScreen()),
      GoRoute(path:'/admin/products',     builder:(_,__)=>const AdminProductsScreen()),
      GoRoute(path:'/admin/orders',       builder:(_,__)=>const AdminOrdersScreen()),
      GoRoute(path:'/admin/inventory',    builder:(_,__)=>const AdminInventoryScreen()),
      GoRoute(path:'/admin/categories',   builder:(_,__)=>const AdminCategoriesScreen()),
      GoRoute(path:'/admin/locations',    builder:(_,__)=>const AdminLocationsScreen()),
      GoRoute(path:'/admin/warehouses',   builder:(_,__)=>const AdminLocationsScreen()),
      GoRoute(path:'/admin/suppliers',    builder:(_,__)=>const AdminSuppliersScreen()),
      GoRoute(path:'/admin/rfq',          builder:(_,__)=>const AdminRFQScreen()),
      GoRoute(path: '/admin/rfq/create',  builder: (_, s) => const AdminRFQFormPage()),
      GoRoute(path:'/admin/purchase-orders', builder:(_,__)=>const AdminPurchaseOrdersScreen()),
      GoRoute(path:'/admin/purchases',    builder:(_,__)=>const AdminPurchaseScreen()),
      GoRoute(path:'/admin/customers',    builder:(_,__)=>const AdminCustomersScreen()),
      GoRoute(path:'/admin/accounting',   builder:(_,__)=>const AdminAccountingScreen()),
      GoRoute(path:'/admin/reports',      builder:(_,__)=>const AdminReportsScreen()),
      GoRoute(path:'/admin/users',        builder:(_,__)=>const AdminUsersScreen()),
      GoRoute(path:'/admin/roles',        builder:(_,__)=>const AdminRolesScreen()),
      GoRoute(path:'/admin/audit-logs',   builder:(_,__)=>const AdminAuditLogScreen()),
      GoRoute(path:'/admin/alerts',       builder:(_,__)=>const AdminInventoryScreen()),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path:'/home', builder:(_,__)=>const HomeScreen()),
          GoRoute(path:'/products',
            builder:(_,s)=>ProductListScreen(categoryId:s.uri.queryParameters['category_id'],search:s.uri.queryParameters['search'],originType:s.uri.queryParameters['origin_type']),
            routes:[GoRoute(path:':id',builder:(_,s)=>ProductDetailScreen(productId:s.pathParameters['id']!))]),
          GoRoute(path:'/cart',         builder:(_,__)=>const CartScreen()),
          GoRoute(path:'/checkout',     builder:(_,__)=>const CheckoutScreen()),
          GoRoute(path:'/orders',       builder:(_,__)=>const OrderListScreen(),
            routes:[GoRoute(path:':id',builder:(_,s)=>OrderDetailScreen(orderId:s.pathParameters['id']!))]),
          GoRoute(path:'/subscriptions',builder:(_,__)=>const SubscriptionListScreen(),
            routes:[GoRoute(path:'create',builder:(_,s)=>CreateSubscriptionScreen(skuId:s.extra as String?))]),
          GoRoute(path:'/inventory',    builder:(_,__)=>const InventoryScreen()),
        ],
      ),
    ],
    errorBuilder:(_,s)=>Scaffold(body:Center(child:Text('Not found: ${s.error}'))),
  );

  static String _landing(String role) {
    switch(role){
      case 'admin':case 'operations':case 'warehouse':case 'sourcing': return '/admin-home';
      case 'rider': return '/rider-home';
      default: return '/welcome';
    }
  }
}
