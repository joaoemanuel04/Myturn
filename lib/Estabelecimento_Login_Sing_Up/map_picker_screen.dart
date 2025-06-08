// novo arquivo: lib/Estabelecimento_Login_Sing_Up/map_picker_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // Posição inicial do mapa (centro de Teresina, PI)
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(-5.08921, -42.8016),
    zoom: 14.0,
  );

  GoogleMapController? _mapController;
  LatLng _pickedLocation = _initialCameraPosition.target;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _centerMapOnUserLocation();
  }

  // Tenta centralizar o mapa na localização atual do dispositivo do usuário
  Future<void> _centerMapOnUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (e) {
      print("Erro ao obter localização atual do dispositivo: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecione a Localização'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Confirmar Localização',
            onPressed: () {
              // Retorna a localização selecionada para a tela anterior
              Navigator.of(context).pop(_pickedLocation);
            },
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) => _mapController = controller,
            // Atualiza a localização do pino conforme o usuário move o mapa
            onCameraMove: (position) {
              _pickedLocation = position.target;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          // Indicador visual fixo no centro do mapa
          const IgnorePointer(
            // Para não interferir com os gestos do mapa
            child: Icon(Icons.location_pin, color: Colors.red, size: 50),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
