import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:knightassist/src/core/core.dart';
import 'package:knightassist/src/features/qr/providers/qr_provider.codegen.dart';
import 'package:knightassist/src/global/states/future_state.codegen.dart';
import 'package:knightassist/src/global/widgets/custom_text_button.dart';
import 'package:knightassist/src/helpers/constants/app_colors.dart';

import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../../../global/providers/all_providers.dart';
import '../../../global/widgets/custom_dialog.dart';

class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> {
  Barcode? result;
  bool checkIn = true;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FutureState<String>>(qrStateProvider, (previous, qrState) async {
      qrState.maybeWhen(
        data: (message) async {
          await showDialog<bool>(
              context: context,
              builder: (ctx) => CustomDialog.alert(
                  title: 'QR Code Scanned', body: message, buttonText: 'OK'));
        },
        failed: (reason) async => await showDialog<bool>(
          context: context,
          builder: (ctx) => CustomDialog.alert(
            title: 'Check In/Out Failed',
            body: reason,
            buttonText: 'Retry',
          ),
        ),
        orElse: () {},
      );
    });

    Widget _buildCheckInOutButton() {
      String text = 'Check In';
      if (result!.code!.substring(result!.code!.length - 3) == 'out') {
        text = 'Check Out';
      }
      return CustomTextButton(
        color: AppColors.primaryColor,
        onPressed: () async {
          final qrProv = ref.read(qrProvider);
          try {
            if (text == 'Check Out') {
              await qrProv.checkOut(
                  eventId:
                      result!.code!.substring(0, result!.code!.length - 3));
            } else {
              await qrProv.checkIn(eventId: result!.code!);
            }
          } on CustomException catch (ex) {
            showDialog(
              context: context,
              builder: (ctx) {
                return CustomDialog.alert(
                    title: 'QR Scan Failed',
                    body: ex.message,
                    buttonText: 'Retry');
              },
            );
          }
        },
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: _buildQrView(context)),
          Expanded(
              flex: 1,
              child: Center(
                child: (result != null)
                    ? _buildCheckInOutButton()
                    : const Text('Scan a code'),
              ))
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: AppColors.primaryColor,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) async {
      setState(() {
        result = scanData;
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
