import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../services/language_service.dart';
import '../utils/ui_utils.dart';

/// Screen for capturing multiple photos using the in-app camera.
/// Uses the camera package directly to avoid process death when launching
/// the external camera app via image_picker.
class CameraCaptureScreen extends StatefulWidget {
  final int maxPhotos;
  final int currentPhotoCount;

  const CameraCaptureScreen({
    super.key,
    required this.maxPhotos,
    this.currentPhotoCount = 0,
  });

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final List<File> _capturedPhotos = [];
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isFinishing = false;
  String? _errorMessage;
  bool _isFlashOn = false;
  bool _isRearCamera = true;
  List<CameraDescription> _cameras = [];

  int get _remainingSlots =>
      widget.maxPhotos - widget.currentPhotoCount - _capturedPhotos.length;
  int get _availableSlots => widget.maxPhotos - widget.currentPhotoCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'no_cameras';
          _isInitializing = false;
        });
        return;
      }

      final camera = _isRearCamera
          ? _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.back,
              orElse: () => _cameras.first,
            )
          : _cameras.firstWhere(
              (c) => c.lensDirection == CameraLensDirection.front,
              orElse: () => _cameras.first,
            );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;

      await controller.initialize();
      if (_isFlashOn) {
        await controller.setFlashMode(FlashMode.torch);
      } else {
        await controller.setFlashMode(FlashMode.off);
      }

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'camera_init_failed';
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isCapturing ||
        _remainingSlots <= 0 ||
        _isFinishing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final xFile = await controller.takePicture();

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'photo_$timestamp.jpg';
      final savedPath = path.join(tempDir.path, fileName);

      final savedFile = await File(xFile.path).copy(savedPath);

      // Clean up the original camera file
      try {
        await File(xFile.path).delete();
      } catch (_) {}

      if (mounted && !_isFinishing) {
        setState(() {
          _capturedPhotos.add(savedFile);
        });
      }
    } catch (e) {
      debugPrint('Failed to capture photo: $e');
      if (mounted) {
        UIUtils.showSnackBar(context, context.read<LanguageService>().translate('capture_failed'));
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      _isFlashOn = !_isFlashOn;
      await controller.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    setState(() => _isInitializing = true);
    _isRearCamera = !_isRearCamera;

    await _controller?.dispose();
    _controller = null;

    await _initializeCamera();
  }

  void _removePhoto(int index) {
    if (_isFinishing) return;
    final photo = _capturedPhotos.removeAt(index);
    setState(() {});
    // Delete temp file in background
    photo.delete().catchError((_) => File(''));
  }

  void _finishCapture() {
    if (_isFinishing || !mounted) return;
    setState(() => _isFinishing = true);
    Navigator.of(context).pop(List<File>.from(_capturedPhotos));
  }

  void _cancelCapture() {
    if (_isFinishing || !mounted) return;
    setState(() => _isFinishing = true);
    Navigator.of(context).pop(<File>[]);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageService>();
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(lang),
            Expanded(child: _buildCameraOrPhotos(lang)),
            _buildBottomControls(lang),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(LanguageService lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: AppTheme.primaryNavy,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _cancelCapture,
          ),
          const SizedBox(width: 8),
          Text(
            '${lang.translate('photos')} (${_capturedPhotos.length}/$_availableSlots)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_capturedPhotos.isNotEmpty)
            TextButton(
              onPressed: _finishCapture,
              child: Text(
                lang.translate('save'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraOrPhotos(LanguageService lang) {
    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              lang.translate('starting_camera'),
              style: const TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                lang.translate(_errorMessage!),
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isInitializing = true;
                    _errorMessage = null;
                  });
                  _initializeCamera();
                },
                child: Text(lang.translate('retry_button')),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Center(
        child: Text(
          lang.translate('camera_not_available'),
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return Column(
      children: [
        // Camera preview
        Expanded(
          flex: 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.previewSize?.height ?? 1,
                    height: controller.value.previewSize?.width ?? 1,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
              // Flash & switch camera buttons
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  children: [
                    _buildCameraActionButton(
                      icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                      onTap: _toggleFlash,
                    ),
                    if (_cameras.length > 1) ...[
                      const SizedBox(height: 8),
                      _buildCameraActionButton(
                        icon: Icons.flip_camera_android,
                        onTap: _switchCamera,
                      ),
                    ],
                  ],
                ),
              ),
              // Capturing indicator
              if (_isCapturing)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            ],
          ),
        ),
        // Photo thumbnails strip
        if (_capturedPhotos.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: _capturedPhotos.length,
              itemBuilder: (context, index) => _buildThumbnail(index),
            ),
          ),
      ],
    );
  }

  Widget _buildCameraActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white30),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildThumbnail(int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _capturedPhotos[index],
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              cacheWidth: 140,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: Colors.grey[800],
                child: const Icon(Icons.broken_image, color: Colors.white54),
              ),
            ),
          ),
          Positioned(
            top: 2,
            left: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.primaryNavy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _removePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(LanguageService lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _remainingSlots > 0
                ? '$_remainingSlots ${lang.translate('remaining_photos')}'
                : lang.translate('max_photos_reached'),
            style: TextStyle(
              color: _remainingSlots > 0 ? Colors.white70 : AppTheme.warning,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Done/Save button - always visible when photos exist
              if (_capturedPhotos.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isFinishing ? null : _finishCapture,
                    icon: const Icon(Icons.check),
                    label: Text('${lang.translate('save')} (${_capturedPhotos.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.cardBorderRadius),
                      ),
                    ),
                  ),
                ),
              if (_capturedPhotos.isNotEmpty && _remainingSlots > 0)
                const SizedBox(width: 16),
              // Capture button
              if (_remainingSlots > 0 && _errorMessage == null)
                GestureDetector(
                  onTap: _isCapturing || _isFinishing ? null : _capturePhoto,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCapturing ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
