import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smalltalk/features/home/view/home_screen.dart';
import 'package:smalltalk/features/login/model/login_config_response.dart';
import 'package:smalltalk/features/login/repository/login_repository.dart';
import 'package:smalltalk/providers.dart';
import 'package:smalltalk/utils/commons/navigations.dart';

abstract class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginLoaded extends LoginState {
  const LoginLoaded();
}

class LoginError extends LoginState {
  final String message;
  const LoginError(this.message);

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is LoginError && o.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}

class LoginNotifier extends StateNotifier<LoginState> {
  final LoginRepository _loginRepository;
 LoginNotifier(this._loginRepository) : super(LoginInitial());

  Future<void> getLoginDetails(String qrData, BuildContext context) async {
    try {
      state = LoginLoading();
      LoginConfigResponse loginConfigResponse =
          await _loginRepository.fetchLoginDetails(qrData , context);
      context.read(configProvider).setConfigState(loginConfigResponse);
      navigateWithPopAllAndPush(context: context, pageName: HomeScreen());
    } catch (_) {
      state = LoginError(_.toString());
    }
  }
}
