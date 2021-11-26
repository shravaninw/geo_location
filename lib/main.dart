import 'dart:math' as math;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/near_by.dart';
import 'package:vector_math/vector_math.dart' as vector;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class Location {
  Location(this.name, this.locate);

  final String name;
  final GeoPoint locate;
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Position locat;

  TextEditingController text = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool init = false;
  var geoHasher = GeoHasher();
  String ghash = '';

  @override
  void initState() {
    super.initState();

    getUserLocation();
  }

  getLocation(double x0, double y0, int radius) {
    Random random = Random();

    // Convert radius from meters to degrees
    double radiusInDegrees = radius / 111000;

    double u = random.nextDouble();
    double v = random.nextDouble();
    double w = radiusInDegrees * math.sqrt(u);
    double t = 2 * math.pi * v;
    double x = w * math.cos(t);
    double y = w * math.sin(t);

    // Adjust the x-coordinate for the shrinking of the east-west distances
    double new_x = x / math.cos(vector.radians(y0));

    double foundLongitude = new_x + x0;
    double foundLatitude = y + y0;
    print('Longitude: ${foundLongitude} Latitude:  ${foundLatitude}');
    createLocation(foundLongitude, foundLatitude);
  }

  getUserLocation() async {
    bool enabled = false;
    LocationPermission permission;
    enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return Future.error('Location Service is not Enabled');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    GeolocatorPlatform.instance
        .getPositionStream(desiredAccuracy: LocationAccuracy.high)
        .listen((event) {
      setState(() {
        locat = event;
        ghash = geoHasher.encode(locat.longitude, locat.latitude, precision: 8);
        init = true;
      });
    });
  }

  Future<void> createLocation(double longitude, double latitude) async {
    final DocumentReference<Map<String, dynamic>> ref =
        FirebaseFirestore.instance.collection('randomLocations').doc();
    ref
        .set(<String, dynamic>{
          'position': GeoPoint(latitude, longitude),
          'geoHash': geoHasher.encode(longitude, latitude, precision: 8),
          'active': true
        })
        .then((value) => print('Location Created'))
        .catchError((error) => print(error.toString()));
  }

  final key = GlobalKey();
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Location $ghash  '),
          // actions: [
          //   TextButton(
          //       onPressed: () {
          //         for (int i = 0; i < 300; i++) {
          //           getLocation(80.2707, 13.0827, 50000);
          //         }
          //       },
          //       child: Text('Add'))
          // ],
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('randomLocations')
                .where('active', isEqualTo: true)
                .snapshots(),
            builder: (_, snapshot) {
              if (snapshot.hasError) {
                return Text('Error = ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return ListView(
                shrinkWrap: true,
                children: snapshot.data!.docs
                    .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
                  Map<String, dynamic> data = doc.data();
                  final GeoPoint lo = data['position'];
                  final String geo = data['geoHash'];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => NearByLocations(
                                    geohash: geo,
                                    postion: lo,
                                  )));
                    },
                    child: ListTile(
                      key: UniqueKey(),
                      tileColor:
                          ghash == geo ? Colors.green : Colors.transparent,
                      title: Text(geo),
                      subtitle: Text('${lo.longitude},${lo.latitude}'),
                    ),
                  );
                }).toList(),
              );
            }));
  }
// Widget build(BuildContext context) {
//   print('build');
//   return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: init == true
//           ? Column(
//               children: [
//                 Text(
//                     'current location:${locat.longitude},${locat.latitude} geohash: $ghash '),
//                 TextButton(
//                   onPressed: () {
//                     showModalBottomSheet<void>(
//                       enableDrag: true,
//                       isScrollControlled: true,
//                       backgroundColor: Colors.transparent,
//                       shape: const RoundedRectangleBorder(
//                         borderRadius: BorderRadius.vertical(
//                           top: Radius.circular(24),
//                         ),
//                       ),
//                       clipBehavior: Clip.antiAliasWithSaveLayer,
//                       builder: (BuildContext context) {
//                         return Container(
//                           height: 500,
//                           color: Colors.white,
//                           child: Padding(
//                             padding: const EdgeInsets.all(8.0),
//                             child: Form(
//                               key: formKey,
//                               child: Column(
//                                 children: [
//                                   const Text('Add Name'),
//                                   TextFormField(
//                                     controller: text,
//                                     validator: (String? value) {
//                                       if (value == null || value.isEmpty) {
//                                         return 'Enter Valid Details';
//                                       }
//
//                                       return null;
//                                     },
//                                     decoration: InputDecoration(
//                                       hintText: 'Add Name',
//                                       border: OutlineInputBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(8)),
//                                     ),
//                                   ),
//                                   ElevatedButton(
//                                       onPressed: () {
//                                         if (formKey.currentState!
//                                             .validate()) {
//                                           createLocation(
//                                               text.text, ghash, locat);
//                                           Navigator.pop(context);
//                                         }
//                                       },
//                                       child: const Text('Add'))
//                                 ],
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                       context: context,
//                     );
//                   },
//                   child: const Text('ADD'),
//                 ),
//                 StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                     stream: FirebaseFirestore.instance
//                         .collection('location')
//                         .where('active', isEqualTo: true)
//                         .snapshots(),
//                     builder: (_, snapshot) {
//                       print('stream builder');
//                       if (snapshot.hasError) {
//                         return Text('Error = ${snapshot.error}');
//                       }
//                       if (!snapshot.hasData) {
//                         print('has no data');
//                         return const Center(
//                             child: CircularProgressIndicator());
//                       }
//                       return ListView(
//                         shrinkWrap: true,
//                         children: snapshot.data!.docs.map(
//                             (QueryDocumentSnapshot<Map<String, dynamic>>
//                                 doc) {
//                           print('has data');
//                           Map<String, dynamic> data = doc.data();
//                           final GeoPoint lo = data['position'];
//                           final String geo = data['geoHash'];
//                           return ListTile(
//                             key: UniqueKey(),
//                             tileColor: ghash == geo
//                                 ? Colors.green
//                                 : Colors.transparent,
//                             title: Text(data['name']),
//                             subtitle:
//                                 Text('${lo.longitude},${lo.latitude},$geo'),
//                           );
//                         }).toList(),
//                       );
//                     })
//               ],
//             )
//           : const Center(child: CircularProgressIndicator()));
// }
}
