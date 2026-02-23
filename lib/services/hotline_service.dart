import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hotline_area.dart';

class HotlineService {
  static Future<List<HotlineArea>> fetchHotlines() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('flood_hotlines')
        .get();

    return snapshot.docs.map((doc) {
      return HotlineArea.fromFirestore(doc.id, doc.data());
    }).toList();
  }
}