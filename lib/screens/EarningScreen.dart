import 'package:flutter/material.dart';

import '../components/EarningReportWidget.dart';
import '../components/EarningTodayWidget.dart';
import '../components/EarningWeekWidget.dart';
import '../main.dart';
import '../model/EarningListModelWeek.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';

class EarningScreen extends StatefulWidget {
  @override
  EarningScreenState createState() => EarningScreenState();
}

class EarningScreenState extends State<EarningScreen> {
  EarningListModelWeek? earningListModelWeek;
  List<WeekReport> weekReport = [];

  num totalRideCount = 0;
  num totalCashRide = 0;
  num totalWalletRide = 0;
  num totalCardRide = 0;
  num totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    appStore.setLoading(true);
    Map req = {
      "type": "week",
    };
    await earningList(req: req).then((value) {
      appStore.setLoading(false);

      totalRideCount = value.totalRideCount!;
      totalCashRide = value.totalCashRide!;
      totalWalletRide = value.totalWalletRide!;
      totalCardRide = value.totalCardRide!;
      totalEarnings = value.totalEarnings!;

      weekReport.addAll(value.weekReport!);
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: neonBackground,
        appBar: AppBar(
          title: Text(language.earnings, style: boldTextStyle(color: appTextPrimaryColorWhite)),
        ),
        body: SafeArea(
          top: false,
          bottom: true,
          maintainBottomViewPadding: true,
          child: Column(
            children: [
              Container(
                height: 40,
                margin: EdgeInsets.only(right: 16, left: 16, top: 16),
                decoration: BoxDecoration(
                  color: neonSurfaceCard,
                  border: Border.all(color: neonAccent.withOpacity(0.4)),
                  borderRadius: radius(defaultRadius + 2),
                ),
                child: TabBar(
                  dividerHeight: 0,
                  padding: EdgeInsets.all(2),
                  indicator: BoxDecoration(borderRadius: radius(), color: neonAccent),
                  labelColor: neonOnAccent,
                  unselectedLabelColor: neonHighlight,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: boldTextStyle(color: neonOnAccent, size: 14),
                  unselectedLabelStyle: boldTextStyle(color: neonHighlight, size: 14),
                  tabs: [
                    Text(language.today),
                    Text(language.weekly),
                    Text(language.report),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    EarningTodayWidget(),
                    EarningWeekWidget(),
                    EarningReportWidget(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
