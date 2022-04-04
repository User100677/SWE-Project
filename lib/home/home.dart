import 'package:danger_zone_alert/home/state_card.dart';
import 'package:danger_zone_alert/home/state_pie_chart.dart';
import 'package:danger_zone_alert/models/state.dart';
import 'package:danger_zone_alert/models/user.dart';
import 'package:danger_zone_alert/services/auth.dart';
import 'package:danger_zone_alert/services/database.dart';
import 'package:danger_zone_alert/shared/loading_widget.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  List<StateInfo>? sortedStates = [];

  void cardCallback(state) {
    setState(
      () {
        showDialog(
            context: context, builder: (context) => buildCard(context, state));
      },
    );
  }

  handleLogOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Do you wish to log out?'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
              onPressed: () async {
                await _authService.signOut();
                Navigator.pop(context);
              },
              child: const Text('Yes')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StateInfo>>(
        stream: DatabaseService(uid: widget.user.uid).getStateData(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<StateInfo>? states = snapshot.data;
            int totalCrimeCount = 0;

            // Calculate the total crime across Malaysia
            for (StateInfo state in states!) {
              totalCrimeCount += state.totalCrime;
            }

            return Scaffold(
              backgroundColor: const Color(0xffDAE0E6),
              appBar: AppBar(
                title: const Text(
                  'Crime Statistics',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25.0,
                      fontWeight: FontWeight.w800),
                ),
                actions: [
                  TextButton.icon(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('Logout',
                        style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      handleLogOut();
                    },
                  ),
                ],
              ),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      flex: 5,
                      child: Stack(
                        children: [
                          Center(
                            child: Container(
                                padding: EdgeInsets.zero,
                                margin: EdgeInsets.zero,
                                width: 315.0,
                                height: 315.0,
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white)),
                          ),
                          StatePieChart(
                              states: states,
                              totalCrimeCount: totalCrimeCount,
                              isBackground: false),
                          // Background effect pie chart
                          StatePieChart(
                              states: states,
                              totalCrimeCount: totalCrimeCount,
                              isBackground: true),
                          Center(
                            child: SizedBox(
                              width: 100.0,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: 'Total crime\n',
                                  style: const TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18.0),
                                  children: [
                                    TextSpan(
                                      text: totalCrimeCount.toString(),
                                      style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 17.0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )),
                  Row(
                    children: const [
                      Padding(
                        // padding: EdgeInsets.symmetric(horizontal: 24.0),
                        padding: EdgeInsets.only(left: 24.0, top: 8.0),
                        child: Text(
                          'Crime cases:',
                          style: TextStyle(
                              fontSize: 20.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                      flex: 3,
                      child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 16.0),
                          itemCount: 13,
                          itemBuilder: (context, index) {
                            sortedStates = states;
                            sortedStates?.sort(
                                (a, b) => b.totalCrime.compareTo(a.totalCrime));
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                buildStateCard(
                                    context,
                                    totalCrimeCount,
                                    sortedStates![index],
                                    index + 1,
                                    cardCallback),
                              ],
                            );
                          })),
                  const SizedBox(height: 16.0),
                  // buildBottomTabBar(context, null, true),
                ],
              ),
            );
          } else {
            return const Loading();
          }
        });
  }
}
