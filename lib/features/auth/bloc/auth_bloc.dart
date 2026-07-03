import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/models/app_models.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckEvent extends AuthEvent {
  const AuthCheckEvent();
}

class AuthLoginEvent extends AuthEvent {
  final String identifier, password;
  const AuthLoginEvent(this.identifier, this.password);
  @override
  List<Object?> get props => [identifier];
}

class AuthRegisterEvent extends AuthEvent {
  final String name, email, phone, password;
  const AuthRegisterEvent(this.name, this.email, this.phone, this.password);
}

class AuthOtpVerifyEvent extends AuthEvent {
  final String phone, otp;
  const AuthOtpVerifyEvent(this.phone, this.otp);
}

class AuthSendOtpEvent extends AuthEvent {
  final String phone;
  const AuthSendOtpEvent(this.phone);
  @override
  List<Object?> get props => [phone];
}

class AuthForgotPasswordEvent extends AuthEvent {
  final String email;
  const AuthForgotPasswordEvent(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthResetPasswordEvent extends AuthEvent {
  final String email, otp, newPassword;
  const AuthResetPasswordEvent(this.email, this.otp, this.newPassword);
}

class AuthLogoutEvent extends AuthEvent {
  const AuthLogoutEvent();
}

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {
  const AuthInitialState();
}

class AuthLoadingState extends AuthState {
  const AuthLoadingState();
}

class AuthAuthenticatedState extends AuthState {
  final UserModel user;
  const AuthAuthenticatedState(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticatedState extends AuthState {
  const AuthUnauthenticatedState();
}

class AuthErrorState extends AuthState {
  final String message;
  const AuthErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthOtpSentState extends AuthState {
  const AuthOtpSentState();
}

class AuthOtpNewUserState extends AuthState {
  const AuthOtpNewUserState();
}

class AuthForgotPasswordSentState extends AuthState {
  const AuthForgotPasswordSentState();
}

class AuthPasswordResetSuccess extends AuthState {
  const AuthPasswordResetSuccess();
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitialState()) {
    on<AuthCheckEvent>(_check);
    on<AuthSendOtpEvent>(_sendOtp);
    on<AuthLoginEvent>(_login);
    on<AuthRegisterEvent>(_register);
    on<AuthOtpVerifyEvent>(_verifyOtp);
    on<AuthForgotPasswordEvent>(_forgotPassword);
    on<AuthResetPasswordEvent>(_resetPassword);
    on<AuthLogoutEvent>(_logout);
  }

  String _getErrorMessage(Object err) {
    if (err is DioException) {
      return err.message ?? 'Something went wrong';
    }
    return 'Unexpected error occurred';
  }

  Future<void> _check(AuthCheckEvent e, Emitter<AuthState> em) async {
    final token = await ApiClient.instance.getToken();
    if (token == null) {
      em(const AuthUnauthenticatedState());
      return;
    }
    try {
      final r = await ApiClient.instance.get('/auth/me');
      em(AuthAuthenticatedState(UserModel.fromJson(r['data'])));
    } catch (_) {
      await ApiClient.instance.clearToken();
      em(const AuthUnauthenticatedState());
    }
  }

  Future<void> _login(AuthLoginEvent e, Emitter<AuthState> em) async {
    em(const AuthLoadingState());
    try {
      final key = e.identifier.contains('@') ? 'email' : 'phone';
      final r = await ApiClient.instance.post('/auth/login',
          data: {key: e.identifier, 'password': e.password});
      await ApiClient.instance.saveToken(r['data']['token'] as String);
      em(AuthAuthenticatedState(UserModel.fromJson(r['data']['user'])));
    } catch (err) {
      em(AuthErrorState(_getErrorMessage(err)));
    }
  }

  Future<void> _register(AuthRegisterEvent e, Emitter<AuthState> em) async {
    em(const AuthLoadingState());
    try {
      final r = await ApiClient.instance.post('/auth/register', data: {
        'name': e.name,
        'email': e.email,
        'phone': e.phone,
        'password': e.password
      });
      await ApiClient.instance.saveToken(r['data']['token'] as String);
      em(AuthAuthenticatedState(UserModel.fromJson(r['data']['user'])));
    } catch (err) {
      em(AuthErrorState(_getErrorMessage(err)));
    }
  }

  Future<void> _verifyOtp(AuthOtpVerifyEvent e, Emitter<AuthState> em) async {
    em(const AuthLoadingState());
    try {
      final r = await ApiClient.instance
          .post('/auth/verify-otp', data: {'email': e.phone, 'otp': e.otp});

      final data = r['data'];

      // ✅ Check is_new_user FIRST (no token in this case)
      if (data['is_new_user'] == true) {
        em(const AuthOtpNewUserState());
        return;
      }

      // ✅ Existing user — has token and user object
      if (data['token'] != null && data['user'] != null) {
        await ApiClient.instance.saveToken(data['token'] as String);
        em(AuthAuthenticatedState(UserModel.fromJson(data['user'])));
        return;
      }

      // Fallback
      em(const AuthUnauthenticatedState());
    } catch (err) {
      em(AuthErrorState(_getErrorMessage(err)));
    }
  }

  Future<void> _logout(AuthLogoutEvent e, Emitter<AuthState> em) async {
    await ApiClient.instance.clearToken();
    em(const AuthUnauthenticatedState());
  }

  Future<void> _sendOtp(AuthSendOtpEvent e, Emitter<AuthState> em) async {
    em(const AuthLoadingState());
    try {
      await ApiClient.instance.post('/auth/send-otp', data: {'email': e.phone});
      em(const AuthOtpSentState());
    } catch (err) {
      em(AuthErrorState(_getErrorMessage(err)));
    }
  }

  Future<void> _forgotPassword(
      AuthForgotPasswordEvent e, Emitter<AuthState> em) async {
    em(const AuthLoadingState());
    try {
      await ApiClient.instance
          .post('/auth/forgot-password', data: {'email': e.email});
      em(const AuthForgotPasswordSentState());
    } catch (err) {
      em(AuthErrorState(_getErrorMessage(err)));
    }
  }

  Future<void> _resetPassword(
      AuthResetPasswordEvent e, Emitter<AuthState> em) async {
    em(const AuthLoadingState());
    try {
      await ApiClient.instance.post('/auth/reset-password', data: {
        'email': e.email,
        'otp': e.otp,
        'new_password': e.newPassword
      });
      em(const AuthPasswordResetSuccess());
    } catch (err) {
      em(AuthErrorState(err.toString()));
    }
  }
}
