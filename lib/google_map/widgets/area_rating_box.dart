import 'package:danger_zone_alert/comment/comment.dart';
import 'package:danger_zone_alert/constants/app_constants.dart';
import 'package:danger_zone_alert/models/user.dart';
import 'package:danger_zone_alert/rating/new_rating.dart';
import 'package:danger_zone_alert/shared/widgets/rounded_rectangle_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../util/calculate_distance.dart';
import 'alert_dialog_box.dart';

class AreaRatingBox extends StatelessWidget {
  final String areaDescription;
  final LatLng areaLatLng;
  final UserModel user;
  final Function boxCallback;

  final int numberRating;
  final double dangerRating;

  final ratingColor = Colors.redAccent;
  final dangerLevelColor = const Color(0xffFF6666);
  final primaryColor = Colors.white;
  final locationTextColor = const Color(0xff6E7CA8);
  final iconColor = const Color(0xffAAB1C9);
  final containerButtonColor = const Color(0xffF2F4F5);
  final textColor = Colors.white;

  AreaRatingBox(
      {required this.areaDescription,
      required this.areaLatLng,
      required this.user,
      required this.boxCallback,
      this.numberRating = 10,
      this.dangerRating = 4.5});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 24.0),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          ),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Text('$dangerRating',
                    style: Theme.of(context).textTheme.bodyText2?.copyWith(
                        fontSize: 50.0,
                        // TODO: Text Color base on rating Danger Level: Red, Orange, Yellow, Green, Grey
                        color: ratingColor,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'RobotoMono'),
                    textAlign: TextAlign.center),
              ),
              Text('Danger Level',
                  style: Theme.of(context).textTheme.bodyText2?.copyWith(
                      fontSize: 18.0,
                      color: dangerLevelColor,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              // Rating Bar
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: RatingBarIndicator(
                    rating: dangerRating,
                    itemBuilder: (BuildContext context, int index) =>
                        const Icon(Icons.star_border, color: Color(0xffFEBC48)),
                    itemCount: 5,
                    itemSize: 18.0,
                    direction: Axis.horizontal),
              ),
              // People Rated
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text('$numberRating People Rated',
                    style: Theme.of(context)
                        .textTheme
                        .bodyText2
                        ?.copyWith(fontSize: 10.0, color: locationTextColor),
                    textAlign: TextAlign.center),
              ),
              // Container for location icon and description
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Icon(Icons.location_on_outlined,
                          size: 24.0, color: iconColor),
                    ),
                    Flexible(
                      child: Text(
                        areaDescription,
                        style: Theme.of(context).textTheme.bodyText2?.copyWith(
                            fontSize: 14.0, color: locationTextColor),
                        textAlign: TextAlign.left,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Container for 'Rate' and 'Comment' button
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: containerButtonColor,
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10.0),
                      bottomRight: Radius.circular(10.0)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RoundedRectangleButton(
                        buttonText: 'Rate',
                        buttonStyle: kBlueButtonStyle,
                        textColor: textColor,
                        onPressed: () {
                          if (user.access == false) {
                            showAlertDialog(context, kLocationDenied);
                          } else {
                            if (calculateDistance(user.latLng, areaLatLng) <
                                1) {
                              Navigator.popAndPushNamed(
                                  context, RatingQuestionsList.id);
                              boxCallback();
                            } else {
                              showAlertDialog(context, kAlertRateText);
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 12.0,
                    ),
                    Expanded(
                      child: RoundedRectangleButton(
                        buttonText: 'Comment',
                        buttonStyle: kBlueButtonStyle,
                        textColor: textColor,
                        onPressed: () {
                          if (user.access == false) {
                            showAlertDialog(context, kLocationDenied);
                          } else {
                            if (calculateDistance(user.latLng, areaLatLng) <
                                1) {
                              Navigator.popAndPushNamed(context, Comment.id);
                              boxCallback();
                            } else {
                              showAlertDialog(context, kAlertCommentText);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
