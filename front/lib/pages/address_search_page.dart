import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
// auto-completion
import 'package:flutter_typeahead/flutter_typeahead.dart';

//--------------------------------------- PICKED LOCATION MODEL ----------------------------------
class PickedLocation {
  final String address;
  final LatLng latLng;
  final bool isCurrentPosition;

  PickedLocation(
    this.address,
    this.latLng,
    {this.isCurrentPosition = false}
    );
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

  const AddressSearchPage({
    super.key,
    required this.currentPosition,
    });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher une adresse')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TypeAheadField<AddressSuggestion>(
          controller: _controller,
          //  waits 300 ms after last typing before calling API
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
            // waits for 3 char before launching API call
            if (pattern.length < 3) return [];
            
            try {
              final response = await http.get(
                Uri.parse(
                    'https://nominatim.openstreetmap.org/search?q=$pattern&format=json&addressdetails=1&limit=5'),
                headers: {'User-Agent': 'com.example.front'},
              ).timeout(const Duration(seconds: 5));
              
              if (response.statusCode != 200) return [];
              
              final List data = jsonDecode(response.body);
              return data
                  .cast<Map<String, dynamic>>()
                  .map((json) => AddressSuggestion.fromJson(json))
                  .toList();
            } catch (e) {
              print('Erreur de recherche: $e');
              return [];
            }
          },
          itemBuilder: (context, suggestion) {
            return ListTile(
              leading: const Icon(Icons.place),
              title: Text(suggestion.label),
            );
          },
          onSelected: (suggestion) {
            // wait for widget to be stable before poping
            Future.microtask(() {
              if (mounted) {
                Navigator.pop(
                  context,
                  PickedLocation(
                    suggestion.label,
                    LatLng(suggestion.lat, suggestion.lon),
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