import 'package:nestling/features/auth/data/models/auth_account_model.dart';

class AuthFakeDataSource {
  const new();

  List<AuthAccountModel> getItems() {
    return const <AuthAccountModel>[
      AuthAccountModel(
        id: 'auth-apple',
        title: 'Continue with Apple',
        detail: 'Sarah family account',
      ),
      AuthAccountModel(
        id: 'auth-email',
        title: 'Email and password',
        detail: 'At least 8 characters',
      ),
    ];
  }
}
