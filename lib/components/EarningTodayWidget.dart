import 'package:flutter/material.dart';

import '../main.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Extensions/extension.dart';
import '../utils/utils.dart';

class EarningTodayWidget extends StatefulWidget {
  @override
  EarningTodayWidgetState createState() => EarningTodayWidgetState();
}

class EarningTodayWidgetState extends State<EarningTodayWidget> {
  num totalCashRide = 0;
  num totalWalletRide = 0;
  num todayEarnings = 0;
  num todayRideRequest = 0;

  @override
  void initState() {
    super.initState();
    afterBuildCreated(() {
      appStore.setLoading(true);
    });
    init();
  }

  void init() async {
    Map req = {
      "type": "today",
    };
    await earningList(req: req).then((value) {
      totalCashRide = value.totalCashRide!;
      totalWalletRide = value.totalWalletRide!;
      todayEarnings = value.todayEarnings!;
      todayRideRequest = value.todayRideRequest!;
      appStore.setLoading(false);
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);

      log(error.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: neonBackground,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(top: 24, bottom: 24, right: 16, left: 16),
            child: Column(
              children: [
                earningText(title: language.rides, amount: todayRideRequest, isRides: true),
                SizedBox(height: 16),
                earningText(title: language.cash, amount: totalCashRide),
                SizedBox(height: 16),
                earningText(title: language.wallet, amount: totalWalletRide),
                SizedBox(height: 16),
                Divider(color: neonAccent.withOpacity(0.28), thickness: 1),
                earningText(title: language.todayEarning, amount: todayEarnings, isTotal: true),
                SizedBox(height: 16),
              ],
            ),
          ),
          Visibility(
            visible: appStore.isLoading,
            child: loaderWidget(),
          )
        ],
      ),
    );
  }
}
