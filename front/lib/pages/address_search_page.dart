import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
// auto-completion
import 'package:flutter_typeahead/flutter_typeahead.dart';
//import for logger
import 'package:logger/logger.dart';

//variable for use logger in catch
final logger = Logger();

//--------------------------------------- PICKED LOCATION MODEL ----------------------------------
class PickedLocation {
  final String address;
  final LatLng latLng;
  final bool isCurrentPosition;

  PickedLocation(this.address, this.latLng, {this.isCurrentPosition = false});
}
// -------------------------------------

class AddressSuggestion {
  final String label;
  final double lat;
  final double lon;
  final bool isCurrentPosition;

  AddressSuggestion({
    required this.label,
    required this.lat,
    required this.lon,
    this.isCurrentPosition = false,
  });

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      label: json['display_name'] as String,
      lat: double.parse(json['lat'] as String),
      lon: double.parse(json['lon'] as String),
    );
  }
}

//--------------------------------------- ADDRESS SEARCH PAGE ----------------------------------
class AddressSearchPage extends StatefulWidget {
  final LatLng currentPosition;

  const AddressSearchPage({super.key, required this.currentPosition});

  @override
  State<AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<AddressSuggestion?> _getCurrentLocationSuggestion() async {
    try {
      // Pas besoin de permissions ni de Geolocator !
      // On utilise directement la position passée en paramètre

      String address = "Ma position actuelle";

      // Géocodage inversé pour obtenir l'adresse
      try {
        final response = await http
            .get(
              Uri.parse(
                'https://nominatim.openstreetmap.org/reverse?lat=${widget.currentPosition.latitude}&lon=${widget.currentPosition.longitude}&format=json',
              ),
              headers: {'User-Agent': 'com.example.front'},
            )
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          address = data['display_name'] ?? "Ma position actuelle";
        }
      } catch (e) {
        // Garde "Ma position actuelle" par défaut
      }

      return AddressSuggestion(
        label: "Ma position",
        lat: widget.currentPosition.latitude,
        lon: widget.currentPosition.longitude,
        isCurrentPosition: true,
      );
    } catch (e) {
      logger.e('Erreur', error: e);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher une adresse')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TypeAheadField<AddressSuggestion>(
          controller: _controller,
          debounceDuration: const Duration(milliseconds: 300),
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Entrer une adresse',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            );
          },
          suggestionsCallback: (pattern) async {
            List<AddressSuggestion> suggestions = [];

            // Toujours ajouter "Ma position actuelle" en premier
            final currentLocation = await _getCurrentLocationSuggestion();
            if (currentLocation != null) {
              suggestions.add(currentLocation);
            }

            // Si moins de 3 caractères, retourne seulement la position actuelle
            if (pattern.length < 3) return suggestions;

            // Sinon, ajoute les résultats de recherche
            try {
              final response = await http
                  .get(
                    Uri.parse(
                      'https://nominatim.openstreetmap.org/search?q=$pattern&format=json&addressdetails=1&limit=5',
                    ),
                    headers: {'User-Agent': 'com.example.front'},
                  )
                  .timeout(const Duration(seconds: 5));

              if (response.statusCode == 200) {
                final List data = jsonDecode(response.body);
                suggestions.addAll(
                  data
                      .cast<Map<String, dynamic>>()
                      .map((json) => AddressSuggestion.fromJson(json))
                      .toList(),
                );
              }
            } catch (e) {
              logger.e('Erreur de recherche', error: e);
            }

            return suggestions;
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              leading: Icon(
                suggestion.isCurrentPosition ? Icons.my_location : Icons.place,
                color: suggestion.isCurrentPosition ? Colors.blue : null,
              ),
              title: Text(
                suggestion.label,
                style: TextStyle(
                  fontWeight: suggestion.isCurrentPosition
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          },
          onSelected: (suggestion) {
            Future.microtask(() {
              if (mounted) {
                Navigator.pop(
                  context,
                  PickedLocation(
                    suggestion.label,
                    LatLng(suggestion.lat, suggestion.lon),
                    isCurrentPosition: suggestion.isCurrentPosition,
                  ),
                );
              }
            });
          },
        ),
      ),
    );
  }
}
