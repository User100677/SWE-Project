import 'dart:async';

import 'package:danger_zone_alert/blocs/application_bloc.dart';
import 'package:danger_zone_alert/constants/app_constants.dart';
import 'package:danger_zone_alert/google_map/all_google_map.dart';
import 'package:danger_zone_alert/google_map/widgets/search_bar.dart';
import 'package:danger_zone_alert/models/area.dart';
import 'package:danger_zone_alert/models/user.dart';
import 'package:danger_zone_alert/services/database.dart';
import 'package:danger_zone_alert/services/geolocator_service.dart';
import 'package:danger_zone_alert/shared/widgets/error_snackbar.dart';
import 'package:danger_zone_alert/widget_view/widget_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';
import 'package:provider/provider.dart';

class GoogleMapScreen extends StatefulWidget {
  static String id = "google_map_screen";
  final Position? position;

  const GoogleMapScreen({Key? key, this.position}) : super(key: key);

  @override
  _GoogleMapScreenController createState() => _GoogleMapScreenController();

  BuildContext getContext() {
    return _GoogleMapScreenController().context;
  }
}

class _GoogleMapScreenController extends State<GoogleMapScreen> {
  final notifications = FlutterLocalNotificationsPlugin();
  final Completer<GoogleMapController> _googleMapController = Completer();

  // AreaCircle areaCircle = AreaCircle();
  AreaMarker areaMarker = AreaMarker();
  bool isUserInCircle = false;

  StreamSubscription? locationSubscription;
  final _searchBarController = FloatingSearchBarController();

  @override
  void initState() {
    super.initState();

    const settingsAndroid = AndroidInitializationSettings('app_icon');
    final settingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: (id, title, body, payload) => null);

    // initialize local notifications
    notifications.initialize(
        InitializationSettings(android: settingsAndroid, iOS: settingsIOS));

    final applicationBloc =
        Provider.of<ApplicationBloc>(context, listen: false);

    //Listen for selected Location
    locationSubscription =
        applicationBloc.selectedLocation?.stream.listen((place) {
      if (place != null) {
        _searchBarController.query = place.name;
        navigateToLocation(
            place.geometry.location.latLng, _googleMapController);
        _searchBarController.close();
      } else {
        _searchBarController.clear();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();

    _searchBarController.dispose();
    locationSubscription?.cancel();
  }

  // Callback method to clear markers
  void boxCallback() {
    setState(() {
      areaMarker.markers.clear();
    });
  }

  handleGoogleMapTap(tapLatLng, UserModel user) async {
    // Get the description of the tapped position
    var address = await getAddress(latLng: tapLatLng);

    if (address != kInvalidAddress) {
      setState(
        () {
          bool isWithinAnyCircle = false;

          areaMarker.addMarker(tapLatLng);
          navigateToLocation(tapLatLng, _googleMapController);

          // TODO: Database testing
          DatabaseService(uid: user.uid).getUserData(user);
          print("User num of rated area: " + user.ratedAreas.length.toString());

          // Check if tapLatLng is within any circles
          if (areaCircles.isNotEmpty) {
            for (Circle circle in areaCircles) {
              double distance = calculateDistance(circle.center, tapLatLng);

              if (isWithinCircle(distance)) {
                showDialog(
                    context: context,
                    builder: (context) => AreaRatingBox(
                        areaDescription: address,
                        areaLatLng: circle.center,
                        user: user,
                        boxCallback: boxCallback));
                isWithinAnyCircle = true;
                break;
              }
            }
          }

          if (!isWithinAnyCircle) {
            showDialog(
                context: context,
                builder: (context) => AreaDescriptionBox(
                    areaDescription: address,
                    areaLatLng: tapLatLng,
                    user: user,
                    boxCallback: boxCallback));
            isWithinAnyCircle = false;
          }
        },
      );
    }
  }

  // Contain the logic of notification alert using user GPS
  void _notificationLogic(UserModel user) {
    if (areaCircles.isNotEmpty) {
      for (Circle circle in areaCircles) {
        double userDistance = calculateDistance(circle.center, user.latLng);

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

  List<Area> areas = [];
  // Called when the google map is created
  _onMapCreated(GoogleMapController controller, UserModel user) async {
    _googleMapController.complete(controller);

    try {
      user.setLatLng(await validateLocation(widget.position));
      user.setAccess = true;
    } catch (e) {
      errorSnackBar(context, e.toString());
      user.setAccess = false;
    }

    // TODO: Database
    DatabaseService(uid: user.uid).areas.listen((areas) {
      setState(() {
        this.areas = areas;
      });
    });

    print("Logic areas' length " + areas.length.toString());

    // DatabaseService(uid: user.uid).userRatedArea.listen((userRatedAreas) {
    //   setState(() {
    //     user.ratedAreas = userRatedAreas;
    //   });
    // });
    //
    // print(
    //     "Logic user ratedAreas' length: " + user.ratedAreas.length.toString());

    // Navigate and set stream for user location
    if (user.latLng != null) {
      navigateToLocation(user.latLng, _googleMapController);

      GeolocatorService.getCurrentLocation().listen((position) {
        user.setLatLng(LatLng(position.latitude, position.longitude));

        _notificationLogic(user);
      });
    }
  }

  @override
  Widget build(BuildContext context) => _GoogleMapScreenView(this);
}

// GoogleMapScreenView
class _GoogleMapScreenView
    extends WidgetView<GoogleMapScreen, _GoogleMapScreenController> {
  const _GoogleMapScreenView(_GoogleMapScreenController state) : super(state);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);
    // final user = context.watch<UserModel?>();
    // TODO: Database user ratedAreas always 0 the first click
    user.ratedAreas = Provider.of<List<RatedArea>>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: (GoogleMapController controller) =>
                  state._onMapCreated(controller, user),
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
              markers: Set.from(state.areaMarker.markers),
              // circles: Set.from(state.areaCircle.circles),
              circles: Set.from(areaCircles),
              onTap: (tapLatLng) => state.handleGoogleMapTap(tapLatLng, user),
            ),
            buildBottomTabBar(context, state._googleMapController),
            buildFloatingSearchBar(
                context, state._searchBarController, state.areaMarker),
          ],
        ),
      ),
    );
  }
}
