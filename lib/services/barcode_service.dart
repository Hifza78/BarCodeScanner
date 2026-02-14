import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';


/// Result from barcode scanning containing the scanned value
class BarcodeScanResult {
  final String value;
  final String? formatName;

  BarcodeScanResult({required this.value, this.formatName});
}

/// Service for barcode scanning functionality
class BarcodeService {
  /// Show barcode scanner and return the scanned value and image
  /// Returns null if cancelled or failed
  static Future<BarcodeScanResult?> scanBarcode(BuildContext context) async {
    try {
      return await Navigator.of(context).push<BarcodeScanResult>(
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerView(),
        ),
      );
    } catch (e) {
      debugPrint('Error in scanBarcode: $e');
      return null;
    }
  }

  /// Supported 1D barcode formats (linear barcodes only)
  static const List<BarcodeFormat> supportedFormats = [
    BarcodeFormat.code39,
    BarcodeFormat.code93,
    BarcodeFormat.code128,
    BarcodeFormat.ean8,
    BarcodeFormat.ean13,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.itf,
    BarcodeFormat.codabar,
  ];
}

/// Professional full-screen barcode scanner view
class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView>
    with TickerProviderStateMixin {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  bool _torchOn = false;
  bool _isInitialized = false;
  bool _scanningEnabled = false;

  // Zoom control
  double _zoomLevel = 0.0;

  // Stability check - require consistent reads for accuracy
  String? _lastDetectedValue;
  int _stabilityCount = 0;
  static const int _requiredStabilityCount = 3; // Require 3 consistent reads for accuracy
  DateTime? _firstDetectionTime;
  static const Duration _minimumScanDuration = Duration(milliseconds: 800); // Fast scan with confirmation dialog as safety net

  // Timer for smooth progress updates during hold
  Timer? _holdProgressTimer;
  double _holdProgress = 0.0;

  // Audio player for beep sound
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Animation controllers
  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _successController;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initController();
  }

  void _initAnimations() {
    // Scan line animation (moves up and down like a laser - faster for professional feel)
    _scanLineController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    // Pulse animation for when barcode is detected
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // Success animation - flash green on successful scan
    _successController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );
  }

  /// Play beep sound on successful scan (like professional scanners)
  Future<void> _playBeepSound() async {
    try {
      // Try to play beep sound from assets
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      // Fallback: Use system click sound via platform channel
      debugPrint('Using system sound fallback');
      SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _initController() async {
    if (!mounted) return;

    setState(() {
      _isInitialized = false;
    });

    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!mounted) return;

      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera permission is required to scan barcodes'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }

      // Safely dispose old controller
      try {
        await _controller?.dispose();
      } catch (e) {
        debugPrint('Error disposing old controller: $e');
      }
      _controller = null;

      // Configure controller for fast, professional 1D barcode scanning
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.unrestricted, // Fastest scanning mode
        facing: CameraFacing.back,
        torchEnabled: false,
        returnImage: false,
        formats: BarcodeService.supportedFormats, // 1D formats only
      );

      await _controller!.start();
      if (!mounted) return;

      setState(() {
        _isInitialized = true;
        _scanningEnabled = false;
        _lastDetectedValue = null;
        _stabilityCount = 0;
        _zoomLevel = 0.0;
        _firstDetectionTime = null;
      });

      // Brief delay for camera to focus
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _scanningEnabled = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to initialize camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initialize camera. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _toggleTorch() {
    if (!_isInitialized || _controller == null) return;
    HapticFeedback.lightImpact();
    _controller!.toggleTorch();
    setState(() {
      _torchOn = !_torchOn;
    });
  }

  void _adjustZoom(double delta) {
    if (!_isInitialized || _controller == null) return;
    final newZoom = (_zoomLevel + delta).clamp(0.0, 1.0);
    _controller!.setZoomScale(newZoom);
    setState(() {
      _zoomLevel = newZoom;
    });
  }

  @override
  void dispose() {
    _holdProgressTimer?.cancel();
    _scanLineController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    try {
      _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }
    try {
      _controller?.dispose();
    } catch (e) {
      debugPrint('Error disposing camera controller: $e');
    }
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    try {
      if (!_scanningEnabled || _hasScanned || !mounted) return;

      final List<Barcode> barcodes = capture.barcodes;
      if (barcodes.isEmpty) return;

      final barcode = barcodes.first;
      final value = barcode.displayValue ?? barcode.rawValue;
      if (value == null || value.isEmpty) return;

      final format = barcode.format;

      // Filter - only allow 1D barcode formats
      if (!_isFormatAllowed(format)) {
        return;
      }

      // Validate barcode
      if (!_isValidBarcode(value, format)) {
        return;
      }

      // Stability check: require same barcode to be read multiple times
      if (_lastDetectedValue == value) {
        _stabilityCount++;
      } else {
        // New barcode detected - reset everything and start fresh
        _lastDetectedValue = value;
        _stabilityCount = 1;
        _firstDetectionTime = DateTime.now();
        _holdProgress = 0.0;
        _holdProgressTimer?.cancel();

        // Start timer for smooth progress updates
        _holdProgressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
          if (!mounted || _firstDetectionTime == null) {
            timer.cancel();
            return;
          }
          final elapsed = DateTime.now().difference(_firstDetectionTime!);
          final progress = (elapsed.inMilliseconds / _minimumScanDuration.inMilliseconds).clamp(0.0, 1.0);
          if (mounted) {
            setState(() {
              _holdProgress = progress;
            });
          }
          if (progress >= 1.0) {
            timer.cancel();
          }
        });
      }

      // Trigger pulse animation on each detection
      _pulseController.forward().then((_) {
        if (mounted) _pulseController.reverse();
      });

      if (mounted) setState(() {});

      // Check minimum hold duration
      final holdDuration = DateTime.now().difference(_firstDetectionTime ?? DateTime.now());
      final hasHeldLongEnough = holdDuration >= _minimumScanDuration;

      // Accept after consistent reads AND minimum hold time
      if (_stabilityCount >= _requiredStabilityCount && hasHeldLongEnough) {
        _hasScanned = true;
        _holdProgressTimer?.cancel();

        // Professional scanner feedback - beep + haptic
        _playBeepSound();
        HapticFeedback.heavyImpact();

        // Success animation flash
        _successController.forward().then((_) {
          if (mounted) _successController.reverse();
        });

        // Stop scanning
        try {
          _controller?.stop();
        } catch (e) {
          debugPrint('Error stopping controller: $e');
        }
        _scanLineController.stop();

        // Show confirmation immediately
        _showConfirmationDialog(value, format);
      }
    } catch (e) {
      debugPrint('Error in barcode detection: $e');
    }
  }

  bool _isFormatAllowed(BarcodeFormat format) {
    return BarcodeService.supportedFormats.contains(format);
  }

  /// Simple barcode validation - trust the scanner library
  bool _isValidBarcode(String value, BarcodeFormat format) {
    return value.isNotEmpty;
  }

  Future<void> _showConfirmationDialog(String value, BarcodeFormat format) async {
    // Show quick confirmation with auto-accept option
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProfessionalScanDialog(
        value: value,
        format: format,
        formatName: _formatName(format),
        is1DFormat: _is1DFormat(format),
        modeColor: _getScannerColor(),
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        Navigator.of(context).pop(BarcodeScanResult(
          value: value,
          formatName: _formatName(format),
        ));
      }
    } else {
      // Reset for new scan
      if (!mounted) return;

      _holdProgressTimer?.cancel();
      setState(() {
        _hasScanned = false;
        _scanningEnabled = false;
        _lastDetectedValue = null;
        _stabilityCount = 0;
        _firstDetectionTime = null;
        _holdProgress = 0.0;
      });

      try {
        if (mounted) {
          _scanLineController.repeat(reverse: true);
          await _controller?.start();
        }

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          setState(() {
            _scanningEnabled = true;
          });
        }
      } catch (e) {
        debugPrint('Failed to restart scanner: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to restart scanner. Please go back and try again.'),
            ),
          );
        }
      }
    }
  }

  bool _is1DFormat(BarcodeFormat format) {
    return BarcodeService.supportedFormats.contains(format);
  }

  String _formatName(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.qrCode:
        return 'QR Code';
      case BarcodeFormat.dataMatrix:
        return 'Data Matrix';
      case BarcodeFormat.pdf417:
        return 'PDF417';
      case BarcodeFormat.aztec:
        return 'Aztec';
      case BarcodeFormat.code39:
        return 'Code 39';
      case BarcodeFormat.code93:
        return 'Code 93';
      case BarcodeFormat.code128:
        return 'Code 128';
      case BarcodeFormat.ean8:
        return 'EAN-8';
      case BarcodeFormat.ean13:
        return 'EAN-13';
      case BarcodeFormat.upcA:
        return 'UPC-A';
      case BarcodeFormat.upcE:
        return 'UPC-E';
      case BarcodeFormat.itf:
        return 'ITF';
      case BarcodeFormat.codabar:
        return 'Codabar';
      default:
        return 'Barcode';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Barcode Scanner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0B1957),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Zoom out
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: _isInitialized ? () => _adjustZoom(-0.1) : null,
            tooltip: 'Zoom Out',
          ),
          // Zoom in
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: _isInitialized ? () => _adjustZoom(0.1) : null,
            tooltip: 'Zoom In',
          ),
          // Flashlight toggle
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: _torchOn ? Colors.amber : Colors.white,
            ),
            onPressed: _isInitialized ? _toggleTorch : null,
            tooltip: 'Toggle Flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          if (_controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onBarcodeDetected,
            ),

          // Dark overlay with cutout
          _buildScannerOverlay(),

          // Success flash overlay
          AnimatedBuilder(
            animation: _successAnimation,
            builder: (context, child) {
              if (_successAnimation.value == 0) return const SizedBox.shrink();
              return Container(
                color: Colors.green.withValues(alpha: _successAnimation.value * 0.3),
              );
            },
          ),

          // Zoom indicator
          if (_zoomLevel > 0)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Zoom: ${(_zoomLevel * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),

          // Detection indicator with progress bar
          if (_stabilityCount > 0 && _scanningEnabled)
            Positioned(
              bottom: 180,
              left: 24,
              right: 24,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.qr_code_scanner, color: Colors.green, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              _lastDetectedValue ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                fontFamily: 'monospace',
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Progress bar - time-based for precise targeting
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _holdProgress,
                            backgroundColor: Colors.grey.shade800,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade500),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _holdProgress >= 1.0
                              ? 'Processing...'
                              : 'Hold steady - ${((_minimumScanDuration.inMilliseconds * (1 - _holdProgress)) / 1000).toStringAsFixed(1)}s remaining',
                          style: TextStyle(
                            color: Colors.green.shade300,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Instructions / Status bar
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _scanningEnabled ? Icons.search : Icons.hourglass_top,
                        color: _scanningEnabled ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusText(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (!_scanningEnabled) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade400),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Manual entry button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showManualEntryDialog(context);
                },
                icon: const Icon(Icons.keyboard, color: Colors.white),
                label: const Text(
                  'Enter Manually',
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build scanner overlay with laser line for 1D barcodes
  Widget _buildScannerOverlay() {
    const scanAreaWidth = 320.0;
    const scanAreaHeight = 140.0;
    const borderRadius = 12.0;

    return Stack(
      children: [
        // Dark overlay
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: scanAreaWidth,
                  height: scanAreaHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scan area border with corners
        Center(
          child: SizedBox(
            width: scanAreaWidth,
            height: scanAreaHeight,
            child: Stack(
              children: [
                // Main border
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _scanningEnabled
                          ? (_stabilityCount > 0 ? Colors.green : _getScannerColor())
                          : Colors.orange,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),

                // Corner decorations
                ..._buildCornerDecorations(scanAreaWidth, scanAreaHeight),

                // Laser scan line for 1D barcodes
                if (_scanningEnabled)
                  AnimatedBuilder(
                    animation: _scanLineAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: 10 + (_scanLineAnimation.value * (scanAreaHeight - 24)),
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.withValues(alpha: 0.0),
                                Colors.red,
                                Colors.red,
                                Colors.red.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.2, 0.8, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCornerDecorations(double width, double height) {
    final color = _scanningEnabled
        ? (_stabilityCount > 0 ? Colors.green : _getScannerColor())
        : Colors.orange;
    const size = 30.0;
    const thickness = 4.0;

    return [
      Positioned(top: 0, left: 0, child: _buildCorner(color, size, thickness, topLeft: true)),
      Positioned(top: 0, right: 0, child: _buildCorner(color, size, thickness, topRight: true)),
      Positioned(bottom: 0, left: 0, child: _buildCorner(color, size, thickness, bottomLeft: true)),
      Positioned(bottom: 0, right: 0, child: _buildCorner(color, size, thickness, bottomRight: true)),
    ];
  }

  /// Returns the scanner accent color (green for 1D barcodes)
  Color _getScannerColor() => const Color(0xFF4CAF50);

  String _getStatusText() {
    if (!_scanningEnabled) {
      return 'Focusing camera...';
    }
    if (_stabilityCount > 0 && _holdProgress > 0) {
      final remainingSeconds = (_minimumScanDuration.inMilliseconds * (1 - _holdProgress)) / 1000;
      if (_holdProgress >= 1.0) {
        return 'Processing scan...';
      }
      return 'Hold steady... ${remainingSeconds.toStringAsFixed(1)}s';
    }
    return 'Point at barcode and hold steady';
  }

  Widget _buildCorner(
    Color color,
    double size,
    double thickness, {
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CornerPainter(
          color: color,
          thickness: thickness,
          topLeft: topLeft,
          topRight: topRight,
          bottomLeft: bottomLeft,
          bottomRight: bottomRight,
        ),
      ),
    );
  }

  Future<void> _showManualEntryDialog(BuildContext context) async {
    final TextEditingController textController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.keyboard, color: _getScannerColor()),
            const SizedBox(width: 8),
            const Text('Enter Barcode'),
          ],
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'monospace',
            letterSpacing: 2,
          ),
          decoration: InputDecoration(
            hintText: 'Enter barcode number',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getScannerColor(), width: 2),
            ),
            prefixIcon: const Icon(Icons.numbers),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.of(context).pop(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                Navigator.of(context).pop(textController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getScannerColor(),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      if (!mounted) return;
      Navigator.of(this.context).pop(BarcodeScanResult(
        value: result,
        formatName: 'Manual Entry',
      ));
    }
  }
}

/// Professional scan confirmation dialog with auto-confirm countdown
class _ProfessionalScanDialog extends StatefulWidget {
  final String value;
  final BarcodeFormat format;
  final String formatName;
  final bool is1DFormat;
  final Color modeColor;

  const _ProfessionalScanDialog({
    required this.value,
    required this.format,
    required this.formatName,
    required this.is1DFormat,
    required this.modeColor,
  });

  @override
  State<_ProfessionalScanDialog> createState() => _ProfessionalScanDialogState();
}

class _ProfessionalScanDialogState extends State<_ProfessionalScanDialog> {
  @override
  void initState() {
    super.initState();
    // No auto-confirm - user must manually confirm
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.green, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Barcode Captured!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Format badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.modeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.modeColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.is1DFormat ? Icons.view_week : Icons.qr_code_2,
                  size: 16,
                  color: widget.modeColor,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.formatName,
                  style: TextStyle(
                    color: widget.modeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Barcode value display - large and prominent
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.modeColor.withValues(alpha: 0.1),
                  widget.modeColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: widget.modeColor, width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  'BCN NUMBER',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  widget.value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    letterSpacing: 3,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop(false);
          },
          child: const Text('Scan Again', style: TextStyle(fontSize: 16)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(true);
          },
          icon: const Icon(Icons.check_circle, size: 20),
          label: const Text('Confirm', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for corner decorations
class CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool topLeft;
  final bool topRight;
  final bool bottomLeft;
  final bool bottomRight;

  CornerPainter({
    required this.color,
    required this.thickness,
    this.topLeft = false,
    this.topRight = false,
    this.bottomLeft = false,
    this.bottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (topLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (topRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (bottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else if (bottomRight) {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
