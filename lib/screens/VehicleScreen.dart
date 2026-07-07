import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/model/UserDetailModel.dart';
import 'package:taxi_driver/network/RestApis.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Extensions/AppButtonWidget.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';

import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_textfield.dart';

class VehicleScreen extends StatefulWidget {
  @override
  VehicleScreenState createState() => VehicleScreenState();
}

class VehicleScreenState extends State<VehicleScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController carModelController = TextEditingController();
  TextEditingController carColorController = TextEditingController();
  TextEditingController carPlateNumberController = TextEditingController();
  TextEditingController carProductionYearController = TextEditingController();
  TextEditingController vehicleService = TextEditingController();

  UserDetail userDetail = UserDetail();

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    appStore.setLoading(true);
    await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
      userDetail = value.data!.userDetail!;
      carModelController.text = userDetail.carModel.validate();
      carColorController.text = userDetail.carColor.validate();
      carPlateNumberController.text = userDetail.carPlateNumber.validate();
      carProductionYearController.text = userDetail.carProductionYear.validate();
      vehicleService.text = value.data!.driverService!.name.validate();
      appStore.setLoading(false);
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  Future<void> updateVehicle() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      appStore.setLoading(true);
      updateVehicleDetail(
        carColor: carColorController.text.trim(),
        carModel: carModelController.text.trim(),
        carPlateNumber: carPlateNumberController.text.trim(),
        carProduction: carProductionYearController.text.trim(),
      ).then((value) {
        appStore.setLoading(false);

        // Navigator.pop(context);
        toast(language.vehicleInfoUpdateSucessfully);
      }).catchError((error) {
        appStore.setLoading(false);
        log(error.toString());
      });
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neonBackground,
      appBar: AppBar(
        title: Text(language.updateVehicleInfo, style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: Form(
        key: formKey,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(left: 16, top: 30, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    controller: vehicleService,
                    textFieldType: TextFieldType.NAME,
                    errorThisFieldRequired: language.thisFieldRequired,
                    readOnly: true,
                    textStyle: primaryTextStyle(color: neonHighlight.withOpacity(0.9)),
                    cursorColor: neonAccent,
                    decoration: inputDecorationNeonForm(context, label: language.serviceInfo),
                    onTap: () {
                      toast(language.youCannotChangeService);
                    },
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    controller: carModelController,
                    textFieldType: TextFieldType.NAME,
                    errorThisFieldRequired: language.thisFieldRequired,
                    cursorColor: neonAccent,
                    textStyle: primaryTextStyle(color: Colors.white),
                    decoration: inputDecorationNeonForm(context, label: language.carModel),
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    controller: carColorController,
                    textFieldType: TextFieldType.NAME,
                    errorThisFieldRequired: language.thisFieldRequired,
                    cursorColor: neonAccent,
                    textStyle: primaryTextStyle(color: Colors.white),
                    decoration: inputDecorationNeonForm(context, label: language.carColor),
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    controller: carPlateNumberController,
                    textFieldType: TextFieldType.NAME,
                    errorThisFieldRequired: language.thisFieldRequired,
                    cursorColor: neonAccent,
                    textStyle: primaryTextStyle(color: Colors.white),
                    decoration: inputDecorationNeonForm(context, label: language.carPlateNumber),
                  ),
                  SizedBox(height: 16),
                  AppTextField(
                    controller: carProductionYearController,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textFieldType: TextFieldType.PHONE,
                    errorThisFieldRequired: language.thisFieldRequired,
                    cursorColor: neonAccent,
                    textStyle: primaryTextStyle(color: Colors.white),
                    validator: (s) => validateCarProductionYear(s, language.thisFieldRequired, language.carProductionYearInvalid),
                    decoration: inputDecorationNeonForm(context, label: language.carProductionYear),
                  ),
                ],
              ),
            ),
            Observer(builder: (context) {
              return Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              );
            })
          ],
        ),
      ),
      bottomNavigationBar: SafeScaffoldBottomBar(
        child: Container(
          color: neonBackground,
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: AppButtonWidget(
            text: language.updateVehicle,
            onTap: () {
              updateVehicle();
            },
          ),
        ),
      ),
    );
  }
}
