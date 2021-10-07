import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smalltalk/features/login/model/login_config_response.dart';

class ConfigStateNotifier extends StateNotifier<LoginConfigResponse> {
  ConfigStateNotifier([LoginConfigResponse loginConfigResponse])
      : super(loginConfigResponse ?? LoginConfigResponse());

  void setConfigState(LoginConfigResponse loginConfigResponse) {
    state = loginConfigResponse;
  }
}
