import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:danger_zone_alert/blocs/application_bloc.dart';
import 'package:danger_zone_alert/constants/app_constants.dart';
import 'package:danger_zone_alert/map/screens/address_activity_box.dart';
import 'package:danger_zone_alert/map/screens/address_box.dart';
import 'package:danger_zone_alert/map/util/animate_location.dart';
import 'package:danger_zone_alert/map/util/area_notification.dart';
import 'package:danger_zone_alert/map/util/calculate_distance.dart';
import 'package:danger_zone_alert/map/util/location_validation.dart';
import 'package:danger_zone_alert/map/util/reverse_geocoding.dart';
import 'package:danger_zone_alert/map/util/update_markers.dart';
import 'package:danger_zone_alert/map/widgets/bottom_tab_bar.dart';
import 'package:danger_zone_alert/map/widgets/search_bar.dart';
import 'package:danger_zone_alert/models/area.dart';
import 'package:danger_zone_alert/models/user.dart';
import 'package:danger_zone_alert/services/database.dart';
import 'package:danger_zone_alert/services/geolocator_service.dart';
import 'package:danger_zone_alert/shared/error_snackbar.dart';
import 'package:danger_zone_alert/widget_view/widget_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:provider/provider.dart';

class FireMapScreen extends StatefulWidget {
  static String id = "fire_map_screen";
  final UserModel user;
  final Position? userPosition;

  const FireMapScreen({Key? key, required this.user, this.userPosition})
      : super(key: key);

  @override
  _FireMapScreenController createState() => _FireMapScreenController();

  BuildContext getContext() {
    return _FireMapScreenController().context;
  }
}

class _FireMapScreenController extends State<FireMapScreen> {
  final notifications = FlutterLocalNotificationsPlugin();
  final Completer<GoogleMapController> _googleMapController = Completer();
  bool isUserInCircle = false;

  StreamSubscription? locationSubscription;
  final _searchBarController = FloatingSearchBarController();

  @override
  void initState() {
    super.initState();
    _initializeNotificationsSettings();
  }

  // TODO: The notification isn't popping up in the app but the notification section
  // Set up android & ios notification
  _initializeNotificationsSettings() {
    const settingsAndroid = AndroidInitializationSettings('ic_launcher');
    final settingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: (id, title, body, payload) {});

    notifications.initialize(
        InitializationSettings(android: settingsAndroid, iOS: settingsIOS));
  }

  // Called when the google map is created
  _onMapCreated(GoogleMapController controller) async {
    _googleMapController.complete(controller);

    try {
      widget.user.setLatLng(await validateLocation(widget.userPosition));
      widget.user.setAccess = true;
    } catch (e) {
      errorSnackBar(context, e.toString());
      widget.user.setAccess = false;
    }

    _initializeUserLocation();
    _initializeAreaList();
    _initializeLocationSubscription();
  }

  // Navigate and set stream for user location
  _initializeUserLocation() {
    if (widget.user.latLng != null) {
      animateToLocation(widget.user.latLng, _googleMapController);

      GeolocatorService.getCurrentLocation().listen((position) {
        if (mounted) {
          setState(() {
            widget.user
                .setLatLng(LatLng(position.latitude, position.longitude));
          });
        }
        _initializeNotificationLogic();
      });
    }
  }

  // local_notification logic
  _initializeNotificationLogic() {
    if (areaCircles.isNotEmpty) {
      for (Circle circle in areaCircles) {
        double userDistance =
            calculateDistance(circle.center, widget.user.latLng);

        if (isWithinCircle(userDistance) && isUserInCircle == false) {
          isUserInCircle = true;
          showOngoingNotification(notifications,
              title: 'You entered a Red Zone', body: 'Stay cautious!');
          break;
        }

        !isWithinCircle(userDistance) ? isUserInCircle = false : null;
      }
    }
  }

  // Assign the database value into an areaList for display purposes
  _initializeAreaList() {
    DatabaseService(uid: widget.user.uid)
        .getAreasData(_googleMapController, context)
        .listen((List<DocumentSnapshot> documentList) {
      widget.user.ratedAreas.clear();
      areaCircles.clear();
      areaList.clear();

      if (mounted) {
        for (DocumentSnapshot document in documentList) {
          LatLng latLng = LatLng(document.get('geoData')['geopoint'].latitude,
              document.get('geoData')['geopoint'].longitude);
          double rating = document.get('rating');
          var totalUsers = document.get('totalUsers');
          int color = document.get('color');

          setState(() {
            areaList.add(Area(
                latLng: latLng,
                rating: rating,
                totalUsers: totalUsers,
                color: Color(color).withOpacity(0.8)));
          });
        }
      }
    });
  }

  // listen for searched location
  _initializeLocationSubscription() {
    final applicationBloc =
        Provider.of<ApplicationBloc>(context, listen: false);

    locationSubscription =
        applicationBloc.selectedLocation?.stream.listen((place) {
      if (place != null) {
        _searchBarController.query = place.name;
        animateToLocation(place.geometry.location.latLng, _googleMapController);
        _searchBarController.close();
      } else {
        _searchBarController.clear();
      }
    });
  }

  _handleMapTap(tapLatLng) async {
    // Get the description of the tapped position
    var address = await getAddress(tapLatLng);

    // TODO: Database testing
    // if (widget.user.ratedAreas.isNotEmpty) {
    //   print(widget.user.ratedAreas.first.latLng);
    // } else {
    //   print("The current user didn't rate that area before!");
    // }

    if (address != kInvalidAddress) {
      bool isWithinAnyCircle = false;

      updateMarkers(tapLatLng);
      animateToLocation(tapLatLng, _googleMapController);

      // Check if tapLatLng is within any circles
      if (areaCircles.isNotEmpty) {
        for (Circle circle in areaCircles) {
          double distance = calculateDistance(circle.center, tapLatLng);

          if (isWithinCircle(distance)) {
            isWithinAnyCircle = true;
            Area area = areaList[areaCircles.indexOf(circle)];
            setState(() {
              showDialog(
                  context: context,
                  builder: (context) => AddressActivityBox(
                      area: area,
                      description: address,
                      user: widget.user,
                      boxCallback: boxCallback));
            });

            _handleUserRatedArea(circle);
            break;
          }
        }
      }

      if (!isWithinAnyCircle) {
        isWithinAnyCircle = false;
        setState(() {
          showDialog(
              context: context,
              builder: (context) => AddressBox(
                  description: address,
                  latLng: tapLatLng,
                  user: widget.user,
                  boxCallback: boxCallback));
        });
      }
    }
  }

  _handleUserRatedArea(circle) async {
    widget.user.ratedAreas.clear();

    DocumentSnapshot docSnapshot = await DatabaseService(uid: widget.user.uid)
        .getUserRatingData(circle.center);

    if (docSnapshot.exists) {
      widget.user.ratedAreas.add(RatedArea(
          latLng: LatLng(docSnapshot.get('geopoint').latitude,
              docSnapshot.get('geopoint').longitude),
          rating: docSnapshot.get('rating')));

      print("User already rated this rated area!");
    }

    // TODO: Do stuff when current user didn't rate the area before
    // If the document doesn't exist this method will instant terminate for some reason
  }

  // Callback method to clear markers
  void boxCallback() {
    setState(() {
      markers.clear();
    });
  }

  @override
  void dispose() {
    super.dispose();
    cancelNotification();
    markers.clear();
    areaList.clear();
    areaCircles.clear();
    _searchBarController.dispose();
    locationSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) => _FireMapScreenView(this);
}

// GoogleMapScreenView
class _FireMapScreenView
    extends WidgetView<FireMapScreen, _FireMapScreenController> {
  const _FireMapScreenView(_FireMapScreenController state) : super(state);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: (GoogleMapController controller) =>
                  state._onMapCreated(controller),
              minMaxZoomPreference: const MinMaxZoomPreference(7, 19),
              initialCameraPosition: kInitialCameraPosition,
              cameraTargetBounds: CameraTargetBounds(kMalaysiaBounds),
              mapType: MapType.hybrid,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              trafficEnabled: false,
              zoomControlsEnabled: false,
              markers: Set.from(markers),
              circles: Set.from(areaCircles),
              onTap: (tapLatLng) => state._handleMapTap(tapLatLng),
            ),
            buildBottomTabBar(context, state._googleMapController),
            buildSearchBar(context, state._searchBarController),
          ],
        ),
      ),
    );
  }
}