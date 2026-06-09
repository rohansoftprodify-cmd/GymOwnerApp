import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gym_owner_app/src/core/data/repository_providers.dart';
import 'package:gym_owner_app/src/core/theme/app_theme_extensions.dart';
import 'package:gym_owner_app/src/core/ui/app_dialogs.dart';

class GymCheckInLocationPage extends ConsumerStatefulWidget {
  const GymCheckInLocationPage({super.key, required this.gymId});

  final String gymId;

  @override
  ConsumerState<GymCheckInLocationPage> createState() => _GymCheckInLocationPageState();
}

class _GymCheckInLocationPageState extends ConsumerState<GymCheckInLocationPage> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: '150');

  bool _loading = true;
  bool _saving = false;
  bool _locating = false;

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final gym = await ref.read(gymRepositoryProvider).gymById(widget.gymId);
      if (!mounted) return;

      final lat = gym?['latitude'] as num?;
      final lng = gym?['longitude'] as num?;
      final radius = gym?['check_in_radius_meters'] as num?;

      _latController.text = lat?.toString() ?? '';
      _lngController.text = lng?.toString() ?? '';
      _radiusController.text = (radius?.toInt() ?? 150).toString();
    } catch (error) {
      if (!mounted) return;
      await showAppErrorDialog(context, title: 'Load failed', error: error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _useCurrentLocation() async {
    if (kIsWeb) {
      await showAppErrorDialog(
        context,
        title: 'Not supported',
        error: 'Use the mobile app to capture GPS coordinates, or enter latitude and longitude manually.',
      );
      return;
    }

    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        await showAppErrorDialog(
          context,
          title: 'Location off',
          error: 'Turn on location services to capture gym coordinates.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        await showAppErrorDialog(
          context,
          title: 'Permission required',
          error: 'Allow location access to set gym coordinates.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });
    } on MissingPluginException {
      if (!mounted) return;
      await showAppErrorDialog(
        context,
        title: 'Restart required',
        error:
            'Location services are not loaded. Fully stop the app, then run it again '
            '(flutter run). Hot reload does not register new native plugins.',
      );
    } catch (error) {
      if (!mounted) return;
      await showAppErrorDialog(context, title: 'Location failed', error: error);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    final radius = int.tryParse(_radiusController.text.trim());

    if (lat == null || lng == null) {
      await showAppErrorDialog(
        context,
        title: 'Invalid coordinates',
        error: 'Enter valid latitude and longitude.',
      );
      return;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      await showAppErrorDialog(
        context,
        title: 'Invalid coordinates',
        error: 'Latitude must be between -90 and 90. Longitude between -180 and 180.',
      );
      return;
    }
    if (radius == null || radius < 50 || radius > 5000) {
      await showAppErrorDialog(
        context,
        title: 'Invalid radius',
        error: 'Check-in radius must be between 50 and 5000 meters.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(gymRepositoryProvider).updateGymCheckInLocation(
            gymId: widget.gymId,
            latitude: lat,
            longitude: lng,
            checkInRadiusMeters: radius,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in location saved')),
      );
    } catch (error) {
      if (!mounted) return;
      await showAppErrorDialog(context, title: 'Save failed', error: error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = context.appColors;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasCoords =
        _latController.text.trim().isNotEmpty && _lngController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in location'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasCoords
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
                  : theme.colorScheme.errorContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasCoords ? Icons.verified_user_outlined : Icons.warning_amber_rounded,
                  color: hasCoords ? theme.colorScheme.primary : theme.colorScheme.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasCoords
                        ? 'Members must be within the check-in radius to mark attendance via QR or GPS.'
                        : 'Set gym coordinates to enable member QR and location check-in.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Gym coordinates',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Stand at your gym entrance and tap “Use current location”, or enter coordinates manually.',
            style: theme.textTheme.labelSmall?.copyWith(color: semantics.mutedText),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _locating ? null : _useCurrentLocation,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(_locating ? 'Getting location…' : 'Use current location'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _latController,
            decoration: const InputDecoration(
              labelText: 'Latitude',
              hintText: 'e.g. 26.9124',
              prefixIcon: Icon(Icons.north_rounded, size: 20),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lngController,
            decoration: const InputDecoration(
              labelText: 'Longitude',
              hintText: 'e.g. 75.7873',
              prefixIcon: Icon(Icons.east_rounded, size: 20),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _radiusController,
            decoration: const InputDecoration(
              labelText: 'Check-in radius (meters)',
              hintText: '150',
              prefixIcon: Icon(Icons.radar_rounded, size: 20),
              helperText: 'Members must be within this distance (50–5000 m)',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Saving…' : 'Save location'),
          ),
        ],
      ),
    );
  }
}
