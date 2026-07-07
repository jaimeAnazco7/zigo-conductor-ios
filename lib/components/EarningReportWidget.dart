import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../main.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Extensions/extension.dart';
import '../utils/utils.dart';

class EarningReportWidget extends StatefulWidget {
  @override
  EarningReportWidgetState createState() => EarningReportWidgetState();
}

class EarningReportWidgetState extends State<EarningReportWidget> {
  TextEditingController fromDateController = TextEditingController();
  TextEditingController toDateController = TextEditingController();

  DateTime? fromDate, toDate;
  num totalRideCount = 0;
  num totalCashRide = 0;
  num totalWalletRide = 0;
  num totalEarnings = 0;

  @override
  void initState() {
    super.initState();
    init(isFirstTimeCall: true);
  }

  void init({bool? isFirstTimeCall}) async {
    if (fromDateController.text.isNotEmpty && toDateController.text.isNotEmpty) {
      appStore.setLoading(true);
      Map req = {
        "type": "report",
        "from_date": fromDateController.text.toString(),
        "to_date": toDateController.text.toString(),
      };
      await earningList(req: req).then((value) {
        appStore.setLoading(false);

        if (value.totalCashRide != null) totalCashRide = value.totalCashRide!;
        if (value.totalWalletRide != null) totalWalletRide = value.totalWalletRide!;
        if (value.totalEarnings != null) totalEarnings = value.totalEarnings!;
        if (value.totalRideCount != null) totalRideCount = value.totalRideCount!;

        setState(() {});
      }).catchError((error) {
        appStore.setLoading(false);

        log(error.toString());
      });
    } else {
      if (isFirstTimeCall == true) return;
      toast(language.pleaseSelectFromDateAndToDate);
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final ThemeData neonDateTheme = ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          primaryColor: neonAccent,
          colorScheme: ColorScheme.dark(
            primary: neonAccent,
            onPrimary: neonOnAccent,
            surface: neonSurfaceCard,
            onSurface: Colors.white,
            secondary: neonHighlight,
          ),
          dialogBackgroundColor: neonBackground,
          datePickerTheme: DatePickerThemeData(
            backgroundColor: neonSurfaceCard,
            headerForegroundColor: Colors.white,
            headerBackgroundColor: neonSurfaceCard,
            dayForegroundColor: WidgetStateProperty.all(Colors.white),
            todayForegroundColor: WidgetStateProperty.all(neonOnAccent),
            todayBackgroundColor: WidgetStateProperty.all(neonAccent),
          ),
        );

        return ColoredBox(
          color: neonBackground,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(top: 16, bottom: 24, left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(language.noteSelectFromDate, style: secondaryTextStyle(color: neonError, size: 13)),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Theme(
                            data: neonDateTheme,
                            child: DateTimePicker(
                              controller: fromDateController,
                              type: DateTimePickerType.date,
                              lastDate: DateTime.now(),
                              firstDate: DateTime(2010),
                              style: primaryTextStyle(color: Colors.white),
                              onChanged: (value) {
                                fromDate = DateTime.parse(value);
                                fromDateController.text = value;
                                setState(() {});
                              },
                              decoration: inputDecorationNeonForm(
                                context,
                                label: language.fromDate,
                                suffixIcon: Icon(Icons.calendar_today, color: neonHighlight),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_right_alt_outlined, color: neonHighlight),
                        SizedBox(width: 4),
                        Expanded(
                          child: Theme(
                            data: neonDateTheme,
                            child: DateTimePicker(
                              controller: toDateController,
                              type: DateTimePickerType.date,
                              lastDate: DateTime.now(),
                              firstDate: fromDate ?? DateTime.now(),
                              style: primaryTextStyle(color: Colors.white),
                              onChanged: (value) {
                                toDate = DateTime.parse(value);
                                toDateController.text = value;
                                init();
                                setState(() {});
                              },
                              decoration: inputDecorationNeonForm(
                                context,
                                label: language.toDate,
                                suffixIcon: Icon(Icons.calendar_today, color: neonHighlight),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
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
