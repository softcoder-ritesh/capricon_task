
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_onLoginEvent);
  }

  Future<void> _onLoginEvent(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await http.post(
        Uri.parse('https://illuminate-production.up.railway.app/api/auth/local'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "identifier": event.email,
          "password": event.password,
        }),
      );

      print("API Response: ${response.body}"); // Debug print
      print("Response Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        emit(AuthSuccess()); // Ensure this state is emitted
        print("AuthSuccess emitted!");
      } else {
        emit(AuthFailure("Invalid credentials"));
        print("AuthFailure emitted!");
      }
    } catch (e) {
      emit(AuthFailure("Error: ${e.toString()}"));
    }
  }
}
