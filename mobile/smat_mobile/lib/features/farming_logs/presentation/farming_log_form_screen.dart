import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../data/farming_log_photo_model.dart';
import '../data/farming_log_photo_storage.dart';

import '../../../core/security/token_storage.dart';
import '../data/farming_log_local_repository.dart';
import '../data/farming_log_model.dart';

import '../data/farming_log_location_model.dart';
import '../service/farming_log_location_service.dart';

class FarmingLogFormScreen extends StatefulWidget {
  final Session session;
  final Map<String, dynamic> plot;
  final FarmingLogLocalRepository repository;

  //

  final int plantingId;
  final int productionCycleId;

  const FarmingLogFormScreen({
    super.key,
    required this.session,
    required this.plot,
    required this.repository,
    required this.plantingId,
    required this.productionCycleId,
  });

  @override
  State<FarmingLogFormScreen> createState() => _FarmingLogFormScreenState();
}

class _FarmingLogFormScreenState extends State<FarmingLogFormScreen> {
  final formKey = GlobalKey<FormState>();

  final notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  final FarmingLogPhotoStorage _photoStorage = FarmingLogPhotoStorage();

  final List<XFile> _selectedPhotos = [];

  bool pickingPhoto = false;

  String activityType = 'WATERING';
  DateTime activityDate = DateTime.now();
  bool saving = false;

  // Dịch vụ vị trí
  final FarmingLogLocationService _locationService =
      FarmingLogLocationService();

  GpsReading? _gpsReading;

  bool _loadingGps = false;

  String? _gpsMessage;

  final activities = const {
    'WATERING': 'Tưới nước',
    'FERTILIZING': 'Bón phân',
    'SPRAYING': 'Phun thuốc',
    'WEEDING': 'Làm cỏ',
    'PRUNING': 'Tỉa cành',
    'OTHER': 'Công việc khác',
  };

  String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> captureGps() async {
    if (_loadingGps || saving || pickingPhoto) return;

    setState(() {
      _loadingGps = true;
      _gpsMessage = null;

      // Không dùng lại GPS cũ nếu lần
      // lấy mới thất bại.
      _gpsReading = null;
    });

    try {
      final reading = await _locationService.getCurrentLocation();

      if (!mounted) return;

      setState(() {
        _gpsReading = reading;
        _gpsMessage = 'Đã lấy vị trí thành công';
      });
    } on GpsException catch (error) {
      if (!mounted) return;

      setState(() {
        _gpsMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _gpsMessage = 'Không lấy được GPS: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingGps = false;
        });
      }
    }
  }

  // Chọn ảnh từ camera hoặc thư viện
  Future<void> pickPhoto(ImageSource source) async {
    if (saving || pickingPhoto || _loadingGps) return;
    if (_selectedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 3 ảnh cho một nhật ký')),
      );
      return;
    }

    setState(() => pickingPhoto = true);
    try {
      final photo = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
      );

      // Farmer nhấn Back trong camera.
      if (photo == null) return;

      if (!mounted) return;

      setState(() {
        _selectedPhotos.add(photo);
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không lấy được ảnh: $error')));
    } finally {
      if (mounted) setState(() => pickingPhoto = false);
    }
  }

  // Chọn ngày thực hiện công việc
  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: activityDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (mounted && picked != null) {
      setState(() => activityDate = picked);
    }
  }

  Future<void> saveLog() async {
    if (!formKey.currentState!.validate()) return;
    if (saving || pickingPhoto || _loadingGps) return;

    final organizationId = widget.plot['organizationId'] as int;
    final plotId = widget.plot['plotId'] as int;

    final log = FarmingLogModel(
      localId: const Uuid().v4(),
      userId: widget.session.userId,
      organizationId: organizationId,
      plotId: plotId,
      plantingId: widget.plantingId,
      productionCycleId: widget.productionCycleId,
      activityType: activityType,
      activityDate: formatDate(activityDate),
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      clientCreatedAt: DateTime.now().toUtc().toIso8601String(),
    );

    setState(() => saving = true);

    final photos = <FarmingLogPhotoModel>[];
    try {
      final reading = _gpsReading;
      final location = reading == null
          ? null
          : FarmingLogLocationModel(
              farmingLogLocalId: log.localId,
              userId: log.userId,
              latitude: reading.latitude,
              longitude: reading.longitude,
              accuracyMeters: reading.accuracyMeters,
              capturedAt: reading.capturedAt,
            );
      if (_selectedPhotos.isEmpty && location == null) {
        await widget.repository.createLog(log);
      } else {
        for (final source in _selectedPhotos) {
          final path = await _photoStorage.savePhoto(source);
          photos.add(
            FarmingLogPhotoModel(
              localPhotoId: const Uuid().v4(),
              farmingLogLocalId: log.localId,
              userId: log.userId,
              localPath: path,
              createdAt: DateTime.now().toUtc().toIso8601String(),
            ),
          );
        }
        await widget.repository.createLogWithPhotos(
          log: log,
          photos: photos,
          location: location,
        );
      }
    } catch (error) {
      for (final photo in photos) {
        try {
          await _photoStorage.deletePhoto(photo.localPath);
        } catch (_) {
          // Keep the save error even if cleanup fails.
        }
      }
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể lưu nhật ký: $error')));
      return;
    }
    if (!mounted) return;
    setState(() => saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã lưu offline nhật ký và ${photos.length} ảnh.'),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoActionsLocked = saving || pickingPhoto || _loadingGps;
    final reading = _gpsReading;
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Ghi nhật ký canh tác')),
        body: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.grass),
                  title: Text('${widget.plot['plotName']}'),
                  subtitle: Text('Mã Plot: ${widget.plot['plotCode']}'),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Thông tin cây trồng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.eco),
                      title: const Text('Planting đã chọn'),
                      subtitle: Text('ID: ${widget.plantingId}'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Production Cycle đã chọn'),
                      subtitle: Text('ID: ${widget.productionCycleId}'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: activityType,
                decoration: const InputDecoration(
                  labelText: 'Công việc canh tác',
                  border: OutlineInputBorder(),
                ),
                items: activities.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => activityType = value);
                  }
                },
              ),

              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Ngày thực hiện'),
                subtitle: Text(formatDate(activityDate)),
                trailing: const Icon(Icons.edit_calendar),
                onTap: selectDate,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: notesController,
                maxLines: 4,
                maxLength: 5000,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  border: OutlineInputBorder(),
                  hintText: 'Ví dụ: Tưới nước buổi sáng',
                ),
              ),

              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: photoActionsLocked ? null : captureGps,
                icon: const Icon(Icons.my_location),
                label: Text(
                  _loadingGps ? 'Đang lấy vị trí…' : 'Lấy vị trí GPS',
                ),
              ),
              if (_gpsMessage != null) Text(_gpsMessage!),
              if (reading != null)
                Text(
                  '${reading.latitude.toStringAsFixed(6)}, '
                  '${reading.longitude.toStringAsFixed(6)} · '
                  'Sai số ${reading.accuracyMeters.toStringAsFixed(1)} m',
                ),
              if (reading != null)
                TextButton(
                  onPressed: photoActionsLocked
                      ? null
                      : () {
                          setState(() {
                            _gpsReading = null;
                            _gpsMessage = null;
                          });
                        },
                  child: const Text('Bỏ vị trí'),
                ),
              const SizedBox(height: 16),
              const Text('Ảnh minh chứng (tối đa 3)'),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: photoActionsLocked
                        ? null
                        : () => pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Chụp ảnh'),
                  ),
                  OutlinedButton.icon(
                    onPressed: photoActionsLocked
                        ? null
                        : () => pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Thư viện'),
                  ),
                ],
              ),
              for (final (index, photo) in _selectedPhotos.indexed)
                ListTile(
                  leading: Image.file(
                    File(photo.path),
                    width: 64,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
                  ),
                  title: Text('Ảnh ${index + 1}'),
                  trailing: IconButton(
                    tooltip: 'Bỏ ảnh',
                    onPressed: photoActionsLocked
                        ? null
                        : () => setState(() => _selectedPhotos.removeAt(index)),
                    icon: const Icon(Icons.close),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: photoActionsLocked ? null : saveLog,
                icon: const Icon(Icons.save),
                label: Text(saving ? 'Đang lưu...' : 'Lưu offline'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
