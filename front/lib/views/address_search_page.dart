import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../models/picked_location_model.dart';
import '../models/address_suggestion_model.dart';
import '../controllers/address_search_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    final searchController = context.read<AddressSearchController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Rechercher une adresse')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TypeAheadField<AddressSuggestion>(
          controller: _controller,
          debounceDuration: const Duration(milliseconds: 300),
          
          // ---------------------- TEXT FIELD ----------------------
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
          
          // ------------------- SUGGESTIONS : calls controller -------------------
          suggestionsCallback: (pattern) async {
            return await searchController.searchAddresses(
              pattern,
              widget.currentPosition,
            );
          },
          
          // ------------------- SUGGESTIONS : displays -------------------
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
          
          // ------------------- SELECTION : back to previous screen -------------------
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