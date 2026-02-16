import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/address_suggestion_model.dart';
import '../services/geocoding_service.dart';

class AddressSearchController extends ChangeNotifier {
  final GeocodingService _geocodingService = GeocodingService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ------------------- SUGGESTION "MA POSITION" -------------------
AddressSuggestion getCurrentLocationSuggestion(LatLng currentPosition) {
      return AddressSuggestion(
        label: "Ma position",
        lat: currentPosition.latitude,
        lon: currentPosition.longitude,
        isCurrentPosition: true,
      );
  }

  // ------------------- SEARCH FOR ADRESSES -------------------
  Future<List<AddressSuggestion>> searchAddresses(
    String query,
    LatLng currentPosition,
  ) async {
    List<AddressSuggestion> suggestions = [];


    // First suggestion = "Ma position"
    final currentLocation = getCurrentLocationSuggestion(currentPosition);
      suggestions.add(currentLocation);

    // if less than 3 char typed, no search launched yet
    if (query.length < 3) return suggestions;

    // else, adds results to suggestions
    final searchResults = await _geocodingService.searchAddresses(query);
    suggestions.addAll(searchResults);

    return suggestions;
  }
}