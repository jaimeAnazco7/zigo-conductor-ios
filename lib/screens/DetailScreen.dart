import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Constants.dart';
import 'package:taxi_driver/utils/Extensions/AppButtonWidget.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:taxi_driver/utils/Extensions/context_extensions.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Services/RideService.dart';
import '../model/CurrentRequestModel.dart';
import '../model/FRideBookingModel.dart';
import '../model/RideHistory.dart';
import '../model/RiderModel.dart';
import '../network/RestApis.dart';
import '../utils/Common.dart';
import '../utils/Extensions/ConformationDialog.dart';
import '../utils/Images.dart';
import 'DashboardScreen.dart';
import 'RideHistoryScreen.dart';

class DetailScreen extends StatefulWidget {
  @override
  DetailScreenState createState() => DetailScreenState();
}

class DetailScreenState extends State<DetailScreen> {
  RideService rideService = RideService();

  CurrentRequestModel? currentData;
  RiderModel? riderModel;
  Payment? payment;
  List<RideHistory> rideHistory = [];
  bool isPaymentDone = false;
  bool paymentSuccessShown = false;

  int? isStreamCallApi = 0;

  bool currentScreen = true;
  bool paymentPressed = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    currentRideRequest();
  }

  Future<void> currentRideRequest() async {
    isStreamCallApi = 1;
    appStore.setLoading(true);
    await getCurrentRideRequest().then((value) async {
      appStore.setLoading(false);
      currentData = value;
      await orderDetailApi();
    }).catchError((error, s) {
      log(error.toString() + "ekrha::$s");
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  bool _isPaidStatus(String? s) => s != null && s.toLowerCase() == PAYMENT_PAID;

  Future<void> savePaymentApi() async {
    if (paymentPressed) return;
    paymentPressed = true;
    appStore.setLoading(true);
    final Map req = {
      "id": currentData!.payment!.id,
      "rider_id": currentData!.payment!.riderId,
      "ride_request_id": currentData!.payment!.rideRequestId,
      "datetime": DateTime.now().toString(),
      "total_amount": riderModel!.totalAmount,
      "payment_type": currentData!.payment!.paymentType,
      "txn_id": "",
      "payment_status": PAYMENT_PAID,
      "transaction_detail": ""
    };
    log('Payment req---' + req.toString());
    try {
      await savePayment(req);
      appStore.setLoading(false);
      // Sincronizar Firestore para que el StreamBuilder detecte pago y el pasajero reciba el estado.
      try {
        await rideService.updateStatusOfRide(rideID: currentData!.payment!.rideRequestId, req: {
          'payment_status': PAYMENT_PAID,
          'on_stream_api_call': 0,
          'on_rider_stream_api_call': 0,
        });
      } catch (_) {}
      await orderDetailApi();
    } catch (error) {
      appStore.setLoading(false);
      log(error.toString());
      toast(error.toString());
    } finally {
      paymentPressed = false;
    }
  }

  Future<void> orderDetailApi() async {
    if (currentData == null) return;
    final int? rideId = currentData!.payment != null ? currentData!.payment!.rideRequestId : currentData!.onRideRequest?.id;
    if (rideId == null) return;
    appStore.setLoading(true);
    try {
      final value = await rideDetail(rideId: rideId);
      appStore.setLoading(false);
      riderModel = value.data;
      if (value.ride_has_bids != null && riderModel != null) {
        riderModel!.ride_has_bids = value.ride_has_bids;
      }
      if (value.payment != null) {
        payment = value.payment!;
      }
      if (currentData!.payment == null && value.payment != null) {
        currentData!.payment = value.payment;
      }
      rideHistory = value.rideHistory ?? [];
      if (!mounted) return;
      setState(() {});
      if (paymentSuccessShown == false && payment != null && _isPaidStatus(payment!.paymentStatus)) {
        if (isPaymentDone != true) {
          isPaymentDone = true;
          paymentSuccessShown = true;
          Future.delayed(
            Duration(seconds: 3),
            () {
              if (!mounted) return;
              launchScreen(context, DashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
              isPaymentDone = false;
            },
          );
        }
      }
    } catch (error, s) {
      appStore.setLoading(false);
      log('${error.toString()}::::$s');
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  BoxDecoration _neonCardDec() => BoxDecoration(
        color: neonSurfaceCard,
        borderRadius: radius(),
        border: Border.all(color: neonAccent.withOpacity(0.35)),
      );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: neonBackground,
      appBar: AppBar(
        title: Text(language.detailScreen, style: boldTextStyle(color: Colors.white)),
      ),
      body: StreamBuilder(
          stream: rideService.fetchRide(userId: sharedPref.getInt(USER_ID)),
          builder: (context, snap) {
            if (snap.hasData) {
              if (snap.data != null && snap.data!.size == 0) {
                Future.delayed(
                  Duration(seconds: 2),
                  () {
                    if (currentScreen == false) return;
                    currentScreen = false;
                    orderDetailApi();
                    if (context != null) {
                      // launchScreen(context, DashboardScreen(), isNewTask: true);
                    }
                  },
                );
              }

              List<FRideBookingModel> data = snap.data!.docs.map((e) => FRideBookingModel.fromJson(e.data() as Map<String, dynamic>)).toList();
              if (data.length != 0) {
                if (data[0].paymentType == CASH && currentData != null && currentData!.payment != null && currentData!.payment!.paymentType != CASH) {
                  currentData!.payment!.paymentType = CASH;
                  currentRideRequest();
                }
                if (data[0].tips == 1 && data[0].onStreamApiCall == 0) {
                  rideService.updateStatusOfRide(rideID: data[0].rideId, req: {"on_stream_api_call": 1});
                  currentRideRequest();
                }
                if (_isPaidStatus(data[0].paymentStatus) && data[0].status == COMPLETED) {
                  if (isPaymentDone != true) {
                    isPaymentDone = true;
                    paymentSuccessShown = true;
                    Future.delayed(
                      Duration(seconds: 3),
                      () {
                        isPaymentDone = false;
                        launchScreen(context, DashboardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                      },
                    );
                  }
                }
              }
              return currentData != null && riderModel != null
                  ? Stack(
                      children: [
                        SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              addressComponent(),
                              if (riderModel!.otherRiderData != null) SizedBox(height: 12),
                              if (riderModel!.otherRiderData != null) riderDataComponent(),
                              SizedBox(height: 12),
                              paymentDetail(),
                              SizedBox(height: 12),
                              priceWidget(),
                            ],
                          ),
                        ),
                        Visibility(
                            visible: isPaymentDone,
                            child: Center(
                              child: Container(
                                  width: context.width(),
                                  margin: EdgeInsets.symmetric(horizontal: 40),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: neonSurfaceCard,
                                    borderRadius: BorderRadius.circular(defaultRadius),
                                    border: Border.all(color: neonAccent.withOpacity(0.45)),
                                    boxShadow: [
                                      BoxShadow(color: neonAccent.withOpacity(0.25), blurRadius: 16, spreadRadius: 0, offset: Offset(0.0, 4.0)),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Lottie.asset(paymentSuccessful, width: 120, height: 120, fit: BoxFit.contain),
                                      Text(
                                        "${language.paymentSuccess}",
                                        style: boldTextStyle(color: neonAccent, size: 24),
                                      )
                                    ],
                                  )),
                            )),
                      ],
                    )
                  : Observer(builder: (context) {
                      return Visibility(
                        visible: appStore.isLoading,
                        child: loaderWidget(),
                      );
                    });
            } else {
              return SizedBox();
            }
          }),
      bottomNavigationBar: currentData != null && currentData!.payment != null
          ? SafeScaffoldBottomBar(
              child: Container(
                width: context.width(),
                color: neonBackground,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: currentData!.payment!.paymentType == CASH
                      ? AppButtonWidget(
                          text: language.cashCollected,
                          onTap: () {
                            showConfirmDialogCustom(
                                primaryColor: primaryColor,
                                positiveText: language.yes,
                                negativeText: language.no,
                                dialogType: DialogType.CONFIRMATION,
                                title: language.areYouSureCollectThisPayment,
                                context, onAccept: (v) {
                              savePaymentApi();
                            });
                          },
                        )
                      : AppButtonWidget(
                          text: language.waitingForDriverConformation,
                          textStyle: boldTextStyle(color: neonOnAccent, size: 12),
                          onTap: () {
                            if (currentData!.payment!.paymentStatus == COMPLETED) {
                              orderDetailApi();
                            } else {
                              toast(language.waitingForDriverConformation);
                            }
                          },
                        ),
                ),
              ),
            )
          : SizedBox(),
    );
  }

  Widget addressComponent() {
    return Container(
      decoration: _neonCardDec(),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Ionicons.calendar, color: neonAccent, size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          '${printDate(riderModel!.createdAt.validate())}',
                          style: primaryTextStyle(size: 14, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Row(
                children: [
                  Text(language.rideId, style: boldTextStyle(size: 16, color: neonHighlight)),
                  SizedBox(width: 8),
                  Text('#${riderModel!.id}', style: boldTextStyle(size: 16, color: Colors.white)),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          riderModel!.distance != null
              ? Text('${language.distance}: ${riderModel!.distance!.toStringAsFixed(2)} ${riderModel!.distanceUnit.toString()}',
                  style: boldTextStyle(size: 14, color: Colors.white))
              : Text('${language.distance}: -- ${riderModel!.distanceUnit.toString()}', style: boldTextStyle(size: 14, color: Colors.white)),
          SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.near_me, color: neonAccent, size: 18),
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (riderModel!.startTime != null)
                          Text(riderModel!.startTime != null ? printDate(riderModel!.startTime!) : '',
                              style: secondaryTextStyle(size: 12, color: neonHighlight)),
                        if (riderModel!.startTime != null) SizedBox(height: 4),
                        Text(riderModel!.startAddress.validate(), style: primaryTextStyle(size: 14, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 10),
                  SizedBox(
                    height: 30,
                    child: DottedLine(
                      direction: Axis.vertical,
                      lineLength: double.infinity,
                      lineThickness: 1,
                      dashLength: 2,
                      dashColor: neonAccent.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.location_on, color: neonError, size: 18),
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (riderModel!.endTime != null)
                          Text(riderModel!.endTime != null ? printDate(riderModel!.endTime!) : '', style: secondaryTextStyle(size: 12, color: neonHighlight)),
                        if (riderModel!.endTime != null) SizedBox(height: 4),
                        Text(riderModel!.endAddress.validate(), style: primaryTextStyle(size: 14, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              if (riderModel != null && riderModel!.multiDropLocation != null && riderModel!.multiDropLocation!.isNotEmpty)
                Row(
                  children: [
                    SizedBox(width: 8),
                    SizedBox(
                      height: 24,
                      child: DottedLine(
                        direction: Axis.vertical,
                        lineLength: double.infinity,
                        lineThickness: 1,
                        dashLength: 2,
                        dashColor: neonAccent.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              if (riderModel != null && riderModel!.multiDropLocation != null && riderModel!.multiDropLocation!.isNotEmpty)
                AppButtonWidget(
                  textColor: neonAccent,
                  color: neonSurfaceCard,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  height: 30,
                  shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(defaultRadius), side: BorderSide(color: neonAccent.withOpacity(0.8))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: neonAccent, size: 12),
                      Text(language.viewMore, style: primaryTextStyle(size: 14, color: neonAccent)),
                    ],
                  ),
                  onTap: () {
                    showOnlyDropLocationsDialog(context: context, multiDropData: riderModel!.multiDropLocation!);
                  },
                )
            ],
          ),
          SizedBox(height: 16),
          inkWellWidget(
            onTap: () {
              launchScreen(context, RideHistoryScreen(rideHistory: rideHistory), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(language.viewHistory, style: secondaryTextStyle(color: neonHighlight)),
                Icon(Entypo.chevron_right, color: neonAccent, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget chargesWidget({String? name, String? amount}) {
    return Padding(
      padding: EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name!, style: primaryTextStyle(color: neonHighlight)),
          Text(amount!, style: primaryTextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget paymentDetail() {
    return Container(
      decoration: _neonCardDec(),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.paymentDetails, style: boldTextStyle(size: 16, color: Colors.white)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.via, style: secondaryTextStyle(color: neonHighlight)),
              Text(paymentStatus(riderModel!.paymentType.validate()), style: boldTextStyle(color: Colors.white)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.status, style: secondaryTextStyle(color: neonHighlight)),
              Text(paymentStatus(riderModel!.paymentStatus.validate()),
                  style: boldTextStyle(color: paymentStatusColorNeon(riderModel!.paymentStatus.validate()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget priceWidget() {
    return Container(
      decoration: _neonCardDec(),
      padding: EdgeInsets.all(12),
      child: riderModel!.ride_has_bids == 1
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.priceDetail, style: boldTextStyle(size: 16, color: Colors.white)),
                SizedBox(height: 12),
                // riderModel!.surgeCharge != null && riderModel!.surgeCharge! > 0?
                // totalCount(title: language.total, amount: riderModel!.subtotal! + riderModel!.tips! + riderModel!.extraChargesAmount!+riderModel!.surgeCharge!, isTotal: true):
                totalCount(
                  title: language.amount,
                  amount:
                      // riderModel!.surgeCharge != null && riderModel!.surgeCharge! > 0?
                      // riderModel!.subtotal!-riderModel!.surgeCharge!:
                      riderModel!.subtotal!,
                  styleNeon: true,
                ),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.couponDiscount, style: secondaryTextStyle(color: neonHighlight)),
                      Row(
                        children: [
                          Text("-", style: boldTextStyle(color: neonAccent, size: 14)),
                          printAmountWidget(
                              amount: '${riderModel!.couponDiscount!.toStringAsFixed(digitAfterDecimal)}',
                              color: neonAccent,
                              size: 14,
                              weight: FontWeight.normal)
                        ],
                      ),
                    ],
                  ),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0) SizedBox(height: 8),
                if (riderModel!.tips != null) totalCount(title: language.tips, amount: riderModel!.tips, styleNeon: true),
                // if(riderModel!.surgeCharge != 0)
                //   SizedBox(height: 8,),
                // if (riderModel!.surgeCharge != null && riderModel!.surgeCharge! > 0) totalCount(title: language.fixedPrice, amount: riderModel!.surgeCharge, space: 0),
                if (riderModel!.extraCharges!.isNotEmpty)
                  SizedBox(
                    height: 8,
                  ),
                if (riderModel!.extraCharges!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(language.additionalFees, style: boldTextStyle(color: Colors.white)),
                      ...riderModel!.extraCharges!.map((e) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key.validate().capitalizeFirstLetter(), style: secondaryTextStyle(color: neonHighlight)),
                              printAmountWidget(amount: e.value!.toStringAsFixed(digitAfterDecimal), size: 14, color: Colors.white)
                            ],
                          ),
                        );
                      }).toList()
                    ],
                  ),
                // if (riderModel!.tips != null || riderModel!.extraCharges!.isNotEmpty)
                Divider(height: 16, thickness: 1, color: neonAccent.withOpacity(0.25)),

                riderModel!.tips != null
                    ?
                    // riderModel!.extraChargesAmount != null
                    //     ?
                    // totalCount(title: language.total, amount: riderModel!.subtotal! + riderModel!.tips! + riderModel!.extraChargesAmount!, isTotal: true)
                    //     :
                    totalCount(title: language.total, amount: riderModel!.totalAmount! + riderModel!.tips!, isTotal: true, styleNeon: true)
                    :
                    // riderModel!.extraChargesAmount != null
                    //     ?
                    // totalCount(title: language.total, amount: riderModel!.subtotal! + riderModel!.extraChargesAmount!, isTotal: true)
                    //     :
                    totalCount(title: language.total, amount: riderModel!.totalAmount, isTotal: true, styleNeon: true),
                // riderModel!.tips != null
                //     ? riderModel!.extraChargesAmount!=null?totalCount(title: language.total, amount: riderModel!.subtotal! + riderModel!.tips!+riderModel!.extraChargesAmount!, isTotal: true):totalCount(title: language.total, amount:
                // riderModel!.subtotal! + riderModel!.tips!, isTotal: true)
                //     :
                // riderModel!.extraChargesAmount!=null?totalCount(title: language.total, amount: riderModel!.subtotal!+riderModel!.extraChargesAmount!, isTotal: true):totalCount(title: language.total, amount: riderModel!.subtotal,
                //     isTotal: true),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.priceDetail, style: boldTextStyle(size: 16, color: Colors.white)),
                SizedBox(height: 12),
                riderModel!.subtotal! <= riderModel!.minimumFare!
                    ? totalCount(title: language.minimumFees, amount: riderModel!.minimumFare, styleNeon: true)
                    : Column(
                        children: [
                          totalCount(title: language.basePrice, amount: riderModel!.baseFare, space: 8, styleNeon: true),
                          totalCount(title: language.distancePrice, amount: riderModel!.perDistanceCharge, space: 8, styleNeon: true),
                          totalCount(
                              title: language.minutePrice,
                              amount: riderModel!.perMinuteDriveCharge,
                              space: riderModel!.perMinuteWaitingCharge != 0
                                  ? 8
                                  : riderModel!.surgeCharge != 0
                                      ? 8
                                      : 0,
                              styleNeon: true),
                          totalCount(
                              title: language.waitingTimePrice,
                              amount: riderModel!.perMinuteWaitingCharge,
                              space: riderModel!.surgeCharge != 0 ? 8 : 0,
                              styleNeon: true),
                        ],
                      ),
                if (riderModel!.surgeCharge != null && riderModel!.surgeCharge! > 0)
                  totalCount(title: language.fixedPrice, amount: riderModel!.surgeCharge, space: 0, styleNeon: true),
                SizedBox(height: 8),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.couponDiscount, style: secondaryTextStyle(color: neonHighlight)),
                      Row(
                        children: [
                          Text("-", style: boldTextStyle(color: neonAccent, size: 14)),
                          printAmountWidget(
                              amount: '${riderModel!.couponDiscount!.toStringAsFixed(digitAfterDecimal)}',
                              color: neonAccent,
                              size: 14,
                              weight: FontWeight.normal)
                        ],
                      ),
                    ],
                  ),
                if (riderModel!.couponData != null && riderModel!.couponDiscount != 0) SizedBox(height: 8),
                if (riderModel!.tips != null) totalCount(title: language.tips, amount: riderModel!.tips, styleNeon: true),
                if (riderModel!.tips != null) SizedBox(height: 8),
                if (riderModel!.extraCharges!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(language.additionalFees, style: boldTextStyle(color: Colors.white)),
                      ...riderModel!.extraCharges!.map((e) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key.validate().capitalizeFirstLetter(), style: secondaryTextStyle(color: neonHighlight)),
                              printAmountWidget(amount: e.value!.toStringAsFixed(digitAfterDecimal), size: 14, color: Colors.white)
                            ],
                          ),
                        );
                      }).toList()
                    ],
                  ),
                Divider(height: 16, thickness: 1, color: neonAccent.withOpacity(0.25)),
                riderModel!.tips != null
                    ? totalCount(title: language.total, amount: riderModel!.totalAmount! + riderModel!.tips!, isTotal: true, styleNeon: true)
                    : totalCount(title: language.total, amount: riderModel!.totalAmount, isTotal: true, styleNeon: true),
                // riderModel!.tips != null
                //     ? totalCount(title: language.total, amount: riderModel!.subtotal! + riderModel!.tips!, isTotal: true)
                //     : totalCount(title: language.total, amount: riderModel!.subtotal, isTotal: true),
              ],
            ),
    );
  }

  Widget riderDataComponent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SizedBox(height: 12),
        Container(
          width: MediaQuery.of(context).size.width,
          decoration: _neonCardDec(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(language.riderInformation.capitalizeFirstLetter(), style: boldTextStyle(color: Colors.white)),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Ionicons.person_outline, size: 18, color: neonAccent),
                  SizedBox(width: 8),
                  Text(riderModel!.otherRiderData!.name.validate(), style: primaryTextStyle(color: Colors.white)),
                ],
              ),
              SizedBox(height: 10),
              InkWell(
                onTap: () {
                  launchUrl(Uri.parse('tel:${riderModel!.otherRiderData!.conatctNumber.validate()}'), mode: LaunchMode.externalApplication);
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.call_sharp, size: 18, color: neonAccent),
                    SizedBox(width: 8),
                    Text(riderModel!.otherRiderData!.conatctNumber.validate(), style: primaryTextStyle(color: neonHighlight))
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
