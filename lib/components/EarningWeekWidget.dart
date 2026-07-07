import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../main.dart';
import '../model/EarningListModelWeek.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Extensions/dataTypeExtensions.dart';
import '../utils/Extensions/extension.dart';
import '../utils/utils.dart';

class EarningWeekWidget extends StatefulWidget {
  @override
  EarningWeekWidgetState createState() => EarningWeekWidgetState();
}

class EarningWeekWidgetState extends State<EarningWeekWidget> {
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

      if (value.totalRideCount != null) totalRideCount = value.totalRideCount!;
      if (value.totalCashRide != null) totalCashRide = value.totalCashRide!;
      if (value.totalWalletRide != null) totalWalletRide = value.totalWalletRide!;
      if (value.totalCardRide != null) totalCardRide = value.totalCardRide!;
      if (value.totalEarnings != null) totalEarnings = value.totalEarnings!;

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

  /// El API manda `day` en inglés (PHP `date('l')`). Mostramos el día según el locale de la app usando `date`.
  String _weekdayLabel(BuildContext context, WeekReport exp) {
    final raw = exp.date?.trim();
    if (raw != null && raw.isNotEmpty) {
      try {
        final dt = DateTime.parse(raw);
        final loc = Localizations.localeOf(context);
        return DateFormat('EEE', loc.toString()).format(dt);
      } catch (_) {}
    }
    return exp.day.validate();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return ColoredBox(
          color: neonBackground,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      height: 350,
                      decoration: BoxDecoration(
                        color: neonSurfaceCard,
                        border: Border.all(color: neonAccent.withOpacity(0.38)),
                        borderRadius: radius(),
                      ),
                      child: SfCartesianChart(
                        backgroundColor: Colors.transparent,
                        plotAreaBackgroundColor: Colors.transparent,
                        plotAreaBorderWidth: 0,
                        title: ChartTitle(
                          text: language.weeklyOrderCount,
                          textStyle: boldTextStyle(color: neonHighlight, size: 14),
                        ),
                        tooltipBehavior: TooltipBehavior(
                          enable: true,
                          color: neonSurfaceCard,
                          textStyle: primaryTextStyle(color: Colors.white, size: 12),
                        ),
                        primaryXAxis: CategoryAxis(
                          isVisible: true,
                          majorGridLines: MajorGridLines(width: 0),
                          labelStyle: TextStyle(color: neonHighlight, fontSize: 11),
                          axisLine: AxisLine(color: neonAccent.withOpacity(0.35)),
                        ),
                        primaryYAxis: NumericAxis(
                          labelStyle: TextStyle(color: neonHighlight, fontSize: 11),
                          majorGridLines: MajorGridLines(color: neonAccent.withOpacity(0.14), width: 1),
                          axisLine: AxisLine(color: neonAccent.withOpacity(0.35)),
                        ),
                        series: <CartesianSeries<WeekReport, String>>[
                          StackedColumnSeries<WeekReport, String>(
                            color: neonAccent,
                            enableTooltip: true,
                            markerSettings: MarkerSettings(isVisible: true, color: neonHighlight, borderColor: neonAccent),
                            dataSource: weekReport,
                            xValueMapper: (WeekReport exp, _) => _weekdayLabel(context, exp),
                            yValueMapper: (WeekReport exp, _) => exp.amount,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    earningText(title: language.rides, amount: totalRideCount, isRides: true),
                    SizedBox(height: 16),
                    earningText(title: language.cash, amount: totalCashRide),
                    SizedBox(height: 16),
                    earningText(title: language.wallet, amount: totalWalletRide),
                    SizedBox(height: 16),
                    Divider(color: neonAccent.withOpacity(0.28), thickness: 1),
                    earningText(title: language.totalEarning, amount: totalEarnings, isTotal: true),
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
      },
    );
  }
}
