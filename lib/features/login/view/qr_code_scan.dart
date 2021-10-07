import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smalltalk/features/login/providers/login_notifier.dart';
import 'package:smalltalk/utils/commons_widgets/app_bar.dart';

import '../../../providers.dart';

class QRCodeScan extends StatefulWidget {
  const QRCodeScan({
    Key key,
  }) : super(key: key);

  @override
  _QRCodeScanState createState() => _QRCodeScanState();
}

class _QRCodeScanState extends State<QRCodeScan> {
  QRViewController controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(context, "Scan QR", null, isLeading: true),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: <Widget>[
                Expanded(
                  child: Consumer(builder: (context, watch, child) {
                    final state = watch(loginNotifierProvider.state);
                    if (state is LoginInitial) {
                      return _buildQrView(context);
                    } else if (state is LoginLoading) {
                      return buildLoading();
                    } else if (state is LoginError) {
                      return PlatformAlertDialog(
                        title: Text(
                          "Error",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        // content: Text(state.message),
                        content: Text("Unable to login, try again later"),
                        actions: <Widget>[
                          PlatformDialogAction(
                              child: Text(
                                "OK",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => context
                                  .read(loginNotifierProvider)
                                  .state = LoginInitial()),
                        ],
                      );
                    } else {
                      return _buildQrView(context);
                    }
                  }),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (notification) {
          Future.microtask(() => controller?.updateDimensions(qrKey));
          return false;
        },
        child: SizeChangedLayoutNotifier(
            key: const Key('qr-size-notifier'),
            child: Stack(
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.red,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 300,
                  ),
                ),
              ],
            )));
  }

  Widget buildLoading() {
    return Center(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Signing In...",
            style: TextStyle(
              color: Colors.black26,
            )),
        PlatformCircularProgressIndicator(),
      ],
    ));
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      this.controller.dispose();
      context.read(loginNotifierProvider).getLoginDetails(scanData, context);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
