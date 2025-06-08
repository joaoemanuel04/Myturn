// novo arquivo: lib/pages/cliente/map_view_screen.dart

import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:myturn/models/estabelecimento_model.dart';
import 'package:geolocator/geolocator.dart';

class MapViewScreen extends StatefulWidget {
  final String establishmentId;

  const MapViewScreen({super.key, required this.establishmentId});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  // Controller para manipular o mapa após ele ser criado
  Completer<GoogleMapController> _controller = Completer();
  // Conjunto (Set) para armazenar os marcadores (pinos) no mapa
  final Set<Marker> _markers = {};
  // Posição inicial padrão do mapa (Teresina, PI)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-5.08921, -42.8016), // Teresina, PI
    zoom: 5, // Zoom mais distante inicialmente
  );

  @override
  void initState() {
    super.initState();
    _fetchEstablishmentAndSetMarker();
    _centerMapOnUserLocation();
  }

  // Busca a localização atual do usuário e move a câmera do mapa para lá
  Future<void> _centerMapOnUserLocation() async {
    try {
      // Pede permissão e obtém a posição atual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final GoogleMapController controller = await _controller.future;
      // Anima a câmera para a nova posição
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14.0,
          ),
        ),
      );
    } catch (e) {
      print("Erro ao obter localização para centrar o mapa: $e");
    }
  }

  // Busca os estabelecimentos no Firebase e cria os marcadores
  Future<void> _fetchEstablishmentAndSetMarker() async {
    try {
      final ref = FirebaseDatabase.instance.ref(
        'estabelecimentos/${widget.establishmentId}',
      );
      final snapshot = await ref.get();

      if (!snapshot.exists || snapshot.value == null || !mounted) return;

      final estabelecimento = EstabelecimentoModel.fromMap(
        Map<String, dynamic>.from(snapshot.value as Map),
      );

      // Verifica se o estabelecimento tem coordenadas
      if (estabelecimento.latitude != null &&
          estabelecimento.longitude != null) {
        final LatLng establishmentLocation = LatLng(
          estabelecimento.latitude!,
          estabelecimento.longitude!,
        );

        // Cria o único marcador para o estabelecimento
        final marker = Marker(
          markerId: MarkerId(estabelecimento.uid),
          position: establishmentLocation,
          infoWindow: InfoWindow(
            title: estabelecimento.name,
            snippet: estabelecimento.categoria,
          ),
        );

        // Move a câmera do mapa para a localização do estabelecimento
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: establishmentLocation, zoom: 16.0),
          ),
        );

        // Adiciona o marcador ao mapa
        setState(() {
          _markers.add(marker);
        });
      }
    } catch (e) {
      print("Erro ao buscar localização do estabelecimento: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estabelecimentos no Mapa')),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialPosition,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _markers, // O conjunto de marcadores a ser exibido
        myLocationEnabled:
            true, // Mostra o ponto azul da localização do usuário
        myLocationButtonEnabled:
            true, // Habilita o botão para centralizar no usuário
      ),
    );
  }
}
