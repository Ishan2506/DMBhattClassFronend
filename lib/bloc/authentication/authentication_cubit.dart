import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'authentication_state.dart';

class AuthenticationCubit extends Cubit<AuthenticationState> {
  AuthenticationCubit() : super(AuthenticationState());

  /// TOGGLE USER ROLES
  void toggleUserRoles(UserRole role) {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(selectedUserRole: role),
      ),
    );
  }

  /// TOGGLE REGISTER USER ROLES
  void toggleRegisterUserRoles(UserRole role) {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(selectedRegistrationUserRole: role),
      ),
    );
  }

  /// UPDATE STUDENT STANDARD
  void updateStudentStandard(String standard) {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          studentStandard: standard,
        ),
      ),
    );
  }

  /// TOGGLE PASSWORD VISIBILITY
  void togglePasswordVisibility() {
    emit(
      state.copyWith(
        formState: state.formState.copyWith(
          isPasswordVisible: !state.formState.isPasswordVisible,
        ),
      ),
    );
  }
}
