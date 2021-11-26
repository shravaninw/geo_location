import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire/geoflutterfire.dart';

class NearByLocations extends StatefulWidget {
  NearByLocations({Key? key, required this.geohash, required this.postion})
      : super(key: key);
  final String geohash;
  final GeoPoint postion;

  @override
  State<NearByLocations> createState() => _NearByLocationsState();
}

class _NearByLocationsState extends State<NearByLocations> {
  Geoflutterfire geo = Geoflutterfire();

  final hasher = GeoHasher();

  late Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream;

  @override
  void initState() {
    super.initState();
    geo = Geoflutterfire();

    GeoFirePoint center = geo.point(
        latitude: widget.postion.latitude, longitude: widget.postion.longitude);

    var collectionReference =
        FirebaseFirestore.instance.collection('randomLocations');
    stream = geo
        .collection(collectionRef: collectionReference)
        .within(center: center, radius: 1, field: 'position', strictMode: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.geohash),
        ),
        body: StreamBuilder(
          stream: stream,
          builder: (_, snapshot) {
            if (snapshot.hasError) {
              return Text('Error = ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              print('has no data');
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              children: snapshot.data!.docs
                  .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) {
                print('has data');
                Map<String, dynamic> data = doc.data();
                final GeoPoint lo = data['position'];
                final String geo = data['geoHash'];
                return ListTile(
                  title: Text(geo),
                  subtitle: Text('${lo.longitude},${lo.latitude}'),
                );
              }).toList(),
            );
          },
        ));
  }
}
