import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

class QRScanner extends StatefulWidget {
  final Function(String) onScan;
  final String? title;
  
  const QRScanner({
    Key? key,
    required this.onScan,
    this.title,
  }) : super(key: key);

  @override
  _QRScannerState createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> with WidgetsBindingObserver {
  late MobileScannerController _controller;
  bool _hasPermission = false;
  bool _isInitialized = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      if (_hasPermission && !_controller.isStarting) {
        _controller.start();
      } else if (!_hasPermission) {
        _checkPermission();
      }
    } else if (state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  Future<void> _checkPermission() async {
    try {
      // Start scanner directly without permission check
      // This is a simplified approach since we're not using permission_handler
      setState(() {
        _hasPermission = true;
        _isInitialized = true;
      });
      _startScanner();
    } catch (e) {
      setState(() {
        _hasPermission = false;
        _isInitialized = true;
        _errorMessage = 'Camera permission is required to scan QR codes. Please enable it in app settings.';
      });
    }
  }

  void _startScanner() {
    try {
      _controller.start();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start camera: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.neonGreen),
        ),
      );
    }

    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? 'QR Scanner'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                AppTheme.darkBackgroundSecondary,
                Colors.black,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonGreen,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'QR Scanner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  widget.onScan(barcode.rawValue!);
                  return;
                }
              }
            },
          ),
          // Scanner overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppTheme.neonGreen,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: ValueListenableBuilder(
                      valueListenable: _controller.torchState,
                      builder: (context, state, child) {
                        return Icon(
                          state == TorchState.off ? Icons.flash_off : Icons.flash_on,
                          color: Colors.white,
                        );
                      },
                    ),
                    onPressed: () => _controller.toggleTorch(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: ValueListenableBuilder(
                      valueListenable: _controller.cameraFacingState,
                      builder: (context, state, child) {
                        return Icon(
                          state == CameraFacing.front ? Icons.camera_front : Icons.camera_rear,
                          color: Colors.white,
                        );
                      },
                    ),
                    onPressed: () => _controller.switchCamera(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// QR Scanner overlay shape
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 10,
    this.overlayColor = const Color(0x88000000),
    this.borderRadius = 10,
    this.borderLength = 30,
    this.cutOutSize = 300,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Paint paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect), paint);

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final RRect cutOutRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: rect.center,
        width: cutOutSize,
        height: cutOutSize,
      ),
      Radius.circular(borderRadius),
    );

    // Draw top left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left - borderWidth / 2, cutOutRect.top + borderLength)
        ..lineTo(cutOutRect.left - borderWidth / 2, cutOutRect.top - borderWidth / 2)
        ..lineTo(cutOutRect.left + borderLength, cutOutRect.top - borderWidth / 2),
      borderPaint,
    );

    // Draw top right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right + borderWidth / 2, cutOutRect.top + borderLength)
        ..lineTo(cutOutRect.right + borderWidth / 2, cutOutRect.top - borderWidth / 2)
        ..lineTo(cutOutRect.right - borderLength, cutOutRect.top - borderWidth / 2),
      borderPaint,
    );

    // Draw bottom left corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.left - borderWidth / 2, cutOutRect.bottom - borderLength)
        ..lineTo(cutOutRect.left - borderWidth / 2, cutOutRect.bottom + borderWidth / 2)
        ..lineTo(cutOutRect.left + borderLength, cutOutRect.bottom + borderWidth / 2),
      borderPaint,
    );

    // Draw bottom right corner
    canvas.drawPath(
      Path()
        ..moveTo(cutOutRect.right + borderWidth / 2, cutOutRect.bottom - borderLength)
        ..lineTo(cutOutRect.right + borderWidth / 2, cutOutRect.bottom + borderWidth / 2)
        ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom + borderWidth / 2),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
