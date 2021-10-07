import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smalltalk/features/home/providers/group_change_provider.dart';
import 'package:smalltalk/features/home/providers/bluetooth_provider.dart';
import 'package:smalltalk/features/login/model/qr_details.dart';
import 'package:smalltalk/features/login/repository/login_repository.dart';
import 'package:smalltalk/utils/commons/enums.dart';
import 'package:smalltalk/utils/constants/global_constants.dart';
import 'features/home/model/user_contract.dart';
import 'features/home/model/user_model.dart';
import 'features/home/providers/config_provider.dart';
import 'features/login/providers/login_notifier.dart';

final loginRepositoryProvider = Provider.autoDispose<LoginRepository>(
  (ref) => LoginDataRepository(),
);

final loginNotifierProvider = StateNotifierProvider.autoDispose(
  (ref) => LoginNotifier(ref.watch(loginRepositoryProvider)),
);

final configProvider = StateNotifierProvider<ConfigStateNotifier>((ref) {
  return ConfigStateNotifier();
});

final qrDetailsProvider = StateProvider<QRDetails>((ref) => new QRDetails());

final showDebugProvider = StateProvider<bool>((ref) => GlobalConstants.showDebug);

// final contactListProvider = StateProvider<List<User>>((ref) => new List<User>());

final groupChangeProvider = ChangeNotifierProvider((ref) => GroupChangeNotifier());
final bluetoothProvider = ChangeNotifierProvider((ref) => BluetoothProvider());

final isPTTDeviceConnectedProvider = StateProvider<bool>((ref) => false);

final muteBeepSounds = StateProvider<bool>((ref) => false);
