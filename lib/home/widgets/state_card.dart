import 'package:danger_zone_alert/home/widgets/state_bar_chart.dart';
import 'package:danger_zone_alert/models/state.dart';
import 'package:flutter/material.dart';

// This is used to display a list card about crime cases in each state
Widget buildCard(BuildContext context, StateInfo state) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 80.0),
    decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10.0))),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, right: 16.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Align(
              alignment: Alignment.topRight,
              child: CircleAvatar(
                  radius: 16.0,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.close, color: Color(0xff838383))),
            ),
          ),
        ),
        Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80.0,
                    height: 80.0,
                    decoration: BoxDecoration(
                      color: const Color(0xff7c94b6),
                      image: DecorationImage(
                          image: AssetImage("assets/images/" +
                              state.state.toLowerCase() +
                              '.png')),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(50.0)),
                      border: Border.all(
                        color: const Color(0xffDAE0E6),
                        width: 4.0,
                      ),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: DefaultTextStyle(
                          style: const TextStyle(
                              fontFamily: 'Agne',
                              fontSize: 30.0,
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                          child: Text(state.state))),
                ],
              ),
            )),
        const SizedBox(height: 24.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF5758FA), Colors.blueAccent])),
                  child: const DefaultTextStyle(
                      style: TextStyle(
                          fontFamily: 'Agne',
                          fontSize: 16.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                      child: Text('Total cases from 2015-2018'))),
            ],
          ),
        ),
        const Divider(thickness: 2.0),
        const SizedBox(height: 16.0),
        Expanded(
            flex: 4,
            child: Card(
                elevation: 0.0,
                margin: const EdgeInsets.only(
                    left: 16.0, right: 16.0, bottom: 24.0),
                child: StateBarChart(state: state))),
      ],
    ),
  );
}

// Vertical List View card
Widget buildStateCard(context, totalCrimeCount, state, index, callback) {
  return GestureDetector(
    onTap: () => callback(state),
    child: Card(
      elevation: 5.0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              children: [
                SizedBox(
                  width: 40.0,
                  height: 40.0,
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 50.0,
                          height: 50.0,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: state.color,
                              width: 8.0,
                              style: BorderStyle.solid,
                            ),
                          ),
                        ),
                      ),
                      Center(
                          child: Text(index.toString(),
                              style: TextStyle(
                                  color: state.color,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                Expanded(
                    child: Column(
                  children: [
                    ListTile(
                        title: Text(state.state,
                            style: const TextStyle(
                                fontSize: 21.0,
                                color: Colors.black,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          (state.totalCrime / totalCrimeCount * 100)
                                  .round()
                                  .toString() +
                              '%',
                          style: const TextStyle(color: Color(0xff6E7CA8)),
                        )),
                  ],
                )),
                Row(
                  children: [
                    Text(state.totalCrime.toString() + ' case',
                        style: const TextStyle(
                            fontSize: 16.0, color: Color(0xff6E7CA8))),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
