import 'package:latlong2/latlong.dart';

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