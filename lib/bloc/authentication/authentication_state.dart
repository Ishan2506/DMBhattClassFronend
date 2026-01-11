part of 'authentication_cubit.dart';

enum UserRole { admin,student, assistant ,guest}

final class AuthenticationState extends Equatable {
  final AuthenticationFormState formState;

  const AuthenticationState({this.formState = const AuthenticationFormState()});

  AuthenticationState copyWith({AuthenticationFormState? formState}) {
    return AuthenticationState(formState: formState ?? this.formState);
  }

  @override
  List<Object?> get props => [formState];
}

final class AuthenticationFormState extends Equatable {
  final UserRole selectedUserRole;
  final UserRole selectedRegistrationUserRole;
  final bool isPasswordVisible;

  const AuthenticationFormState({
    this.selectedUserRole = UserRole.student,
    this.selectedRegistrationUserRole = UserRole.student,
    this.isPasswordVisible = false,
  });

  AuthenticationFormState copyWith({
    UserRole? selectedUserRole,
    UserRole? selectedRegistrationUserRole,
    bool? isPasswordVisible,
  }) {
    return AuthenticationFormState(
      selectedUserRole: selectedUserRole ?? this.selectedUserRole,
      selectedRegistrationUserRole:
          selectedRegistrationUserRole ?? this.selectedRegistrationUserRole,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
    );
  }

  @override
  List<Object?> get props => [
    selectedUserRole,
    isPasswordVisible,
    selectedRegistrationUserRole,
  ];
}
