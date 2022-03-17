import 'package:google_maps_flutter/google_maps_flutter.dart';

List<Marker> markers = [];

updateMarker(latLng) async {
  markers.clear();

  markers.add(Marker(
    markerId: MarkerId(latLng.toString()),
    position: latLng,
    icon: BitmapDescriptor.defaultMarker,
  ));
}
