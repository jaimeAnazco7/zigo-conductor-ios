import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi_driver/model/FRideBookingModel.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';

import '../utils/Constants.dart';
import 'BaseServices.dart';

class RideService extends BaseService {
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  late CollectionReference rideRef;

  RideService() {
    rideRef = fireStore.collection(RIDE_COLLECTION);
  }

  Stream<QuerySnapshot> fetchRide({int? userId}) {
    print("CheckRid FOR Driver::$userId");
    return rideRef.where('driver_ids', arrayContains: userId).snapshots();
  }

  Future addRide(FRideBookingModel rideBookingModel, int? rideID) {
    return rideRef.doc("ride_$rideID").set(rideBookingModel.toJson());
  }

  Future<QuerySnapshot<Object?>> checkIsRideExist({required int rideId}) async {
    return await rideRef.where('ride_id', isEqualTo: rideId).get();
  }

  Future<bool> removeOldRideEntry({int? userId}) async {
    try {
      QuerySnapshot<Object?> b = await rideRef.where('driver_id', isEqualTo: userId).get();
      if (b.docs.isEmpty) return false;
      List<FRideBookingModel> x = b.docs.map((e) => FRideBookingModel.fromJson(e.data() as Map<String, dynamic>)).toList();
      FRideBookingModel? y;
      try {
        y = x.where((element) => element.status == COMPLETED || element.status == CANCELED).first;
      } catch (e) {
        return false;
      }
      await rideRef.doc("ride_${y.rideId}").delete();
      return true;
    } catch (e) {
      log(e);
      return false;
    }
  }

  Future<List<FRideBookingModel>> fetchRideData({int? userId}) {
    return rideRef.where('driver_id', isEqualTo: userId).get().then((value) {
      return value.docs.map((e) => FRideBookingModel.fromJson(e.data() as Map<String, dynamic>)).toList();
    });
  }

  Future<void> updateStatusOfRide({int? rideID, req}) {
    log(' status updated $rideID');
    return rideRef.doc("ride_$rideID").update(req).then((value) {}).catchError((e) {
      log('Error status update $e');
    });
  }

  /// Quita el documento del viaje para que el stream del conductor deje de recibir un ride cancelado en bucle.
  Future<void> deleteRideDocument({int? rideID}) async {
    try {
      await rideRef.doc("ride_$rideID").delete();
    } catch (e) {
      log('deleteRideDocument $e');
    }
  }
}
