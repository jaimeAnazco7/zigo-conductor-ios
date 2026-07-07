import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Extensions/AppButtonWidget.dart';
import 'package:taxi_driver/utils/Extensions/app_common.dart';
import 'package:taxi_driver/utils/Extensions/dataTypeExtensions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/ImageSourceDialog.dart';
import '../model/DocumentListModel.dart';
import '../model/DriverDocumentList.dart';
import '../network/NetworkUtils.dart';
import '../network/RestApis.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/ConformationDialog.dart';
import '../utils/Images.dart';
import 'DashboardScreen.dart';

class DocumentsScreen extends StatefulWidget {
  final bool isShow;

  DocumentsScreen({this.isShow = false});

  @override
  DocumentsScreenState createState() => DocumentsScreenState();
}

class DocumentsScreenState extends State<DocumentsScreen> {
  DateTime selectedDate = DateTime.now();

  List<DocumentModel> documentList = [];
  List<DriverDocumentModel> driverDocumentList = [];

  List<int> uploadedDocList = [];
  List<String> eAttachments = [];
  String? imagePath;
  int docId = 0;
  var compressedImg;

  int? isExpire;

  ThemeData get _neonDatePickerTheme => ThemeData(
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

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2040),
      builder: (context, child) {
        return Theme(
          data: _neonDatePickerTheme,
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    afterBuildCreated(() async {
      appStore.setLoading(true);
      await getDocument();
      await driverDocument();
    });
  }

  ///Driver Document List
  Future<void> getDocument() async {
    appStore.setLoading(true);
    await getDocumentList().then((value) {
      documentList.addAll(value.data!);
      appStore.setLoading(false);
      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);

      toast(error.toString());
    });
  }

  ///Document List
  Future<void> driverDocument() async {
    appStore.setLoading(true);
    await getDriverDocumentList().then((value) {
      driverDocumentList.clear();
      driverDocumentList.addAll(value.data!);
      uploadedDocList.clear();
      driverDocumentList.forEach((element) {
        uploadedDocList.add(element.documentId!);
      });
      appStore.setLoading(false);

      setState(() {});
    }).catchError((error) {
      appStore.setLoading(false);
      // throw error;
      log(error.toString());
    });
  }

  /// Add Documents
  addDocument(int? docId, int? isExpire, {int? updateId, DateTime? dateTime}) async {
    MultipartRequest multiPartRequest = await getMultiPartRequest(updateId == null ? 'driver-document-save' : 'driver-document-update/$updateId');
    multiPartRequest.fields['driver_id'] = sharedPref.getInt(USER_ID).toString();
    multiPartRequest.fields['document_id'] = docId.toString();
    multiPartRequest.fields['is_verified'] = '0';
    if (isExpire != null) multiPartRequest.fields['expire_date'] = dateTime.toString();
    if (imagePath != null) {
      multiPartRequest.files.add(await MultipartFile.fromPath("driver_document", imagePath!));
    }
    multiPartRequest.headers.addAll(buildHeaderTokens());
    appStore.setLoading(true);
    sendMultiPartRequest(
      multiPartRequest,
      onSuccess: (data) async {
        appStore.setLoading(false);
        await driverDocument();
      },
      onError: (error) {
        appStore.setLoading(false);
        // throw error;
        toast(error.toString(), print: true);
      },
    ).catchError((e) {
      appStore.setLoading(false);
      // throw e;
      toast(e.toString());
    });
  }

  Future<File> compressFile(File file) async {
    Directory d = await getTemporaryDirectory();
    FlutterImageCompress.validator.ignoreCheckExtName = true;
    try {
      Uint8List? result = await FlutterImageCompress.compressWithFile(
        file.path,
        minHeight: 512,
        minWidth: 512,
        quality: 100,
      );
      if (result == null) {
        return file;
      }
      File file2 = await File('${d.path}/image.png').create();
      file2.writeAsBytesSync(result);
      return file2;
    } catch (e) {
      return file;
    }
  }

  /// SelectImage
  getMultipleFile(int? docId, int? isExpire, {int? updateId, DateTime? dateTime}) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: neonBackground,
      barrierColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(defaultRadius), topRight: Radius.circular(defaultRadius)),
        side: BorderSide(color: neonAccent.withOpacity(0.35), width: 1),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: ImageSourceDialog(
                onCamera: () async {
                  Navigator.pop(context);
                  final camStatus = await Permission.camera.request();
                  if (!camStatus.isGranted) {
                    if (camStatus.isPermanentlyDenied) {
                      await openAppSettings();
                    }
                    toast('Permiso de cámara necesario para tomar la foto. Actívalo en Ajustes si lo rechazaste.');
                    return;
                  }
                  try {
                    var result = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 100);
                    if (result != null) {
                      File result2 = await compressFile(File(result!.path));
                      int b = await result2.length();
                      double fileSizeInMB = b / (1024 * 1024);
                      if (fileSizeInMB > 2) {
                        return toast(language.fileSizeValidateMsg);
                      }
                      uploadFile(result2.path, docId, isExpire, updateId: updateId);
                    }
                  } catch (e) {
                    toast(e.toString());
                    return;
                  }
                },
                onGallery: () async {
                  Navigator.pop(context);
                  var result = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 100);
                  if (result != null) {
                    File result2 = await compressFile(File(result!.path));
                    int b = await result2.length();
                    double fileSizeInMB = b / (1024 * 1024);
                    if (fileSizeInMB > 2) {
                      return toast(language.fileSizeValidateMsg);
                    }
                    uploadFile(result.path, docId, isExpire, updateId: updateId);
                  }
                },
                onFile: () async {
                  Navigator.pop(context);
                  FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'], allowMultiple: false);
                  if (filePickerResult != null) {
                    int b = filePickerResult.files.first.size;
                    double fileSizeInMB = b / (1024 * 1024);
                    if (fileSizeInMB > 2) {
                      return toast(language.fileSizeValidateMsg);
                    }
                    uploadFile(filePickerResult.files.first.path, docId, isExpire, updateId: updateId);
                  }
                },
                isFile: true,
              ),
            );
          },
        );
      },
    );
  }

  uploadFile(String? file, int? docId, int? isExpire, {int? updateId}) {
    if (file != null) {
      showConfirmDialogCustom(
        context,
        title: language.uploadFileConfirmationMsg,
        onAccept: (BuildContext context) {
          setState(() {
            imagePath = file;
          });
          addDocument(docId, isExpire, dateTime: selectedDate, updateId: updateId);
        },
        positiveText: language.yes,
        negativeText: language.no,
        primaryColor: primaryColor,
      );
      if (isExpire == 1) selectDate(context);
    }
  }

  /// Delete Documents
  deleteDoc(int? id) {
    appStore.setLoading(true);
    deleteDeliveryDoc(id!).then((value) {
      toast(value.message, print: true);

      driverDocument();
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  Future<void> getDetailAPi() async {
    appStore.setLoading(true);
    await getUserDetail(userId: sharedPref.getInt(USER_ID)).then((value) {
      appStore.setLoading(false);

      sharedPref.setInt(IS_Verified_Driver, value.data!.isVerifiedDriver!);
      sharedPref.setInt(IS_DOCUMENT_REQUIRED, value.data!.isDocumentRequired ?? 1);
      syncProfilePhotoRequiredFromUser(value.data);
      if (value.data!.isDocumentRequired != 0) {
        toast(language.someRequiredDocumentAreNotUploaded);
      } else {
        launchDriverPostLoginScreen(context, isNewTask: true);
      }
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
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) {
          return true;
        } else {
          SystemNavigator.pop();
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: neonBackground,
        appBar: AppBar(
          title: Text(language.documents, style: boldTextStyle(color: appTextPrimaryColorWhite)),
        ),
        body: Observer(builder: (context) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(left: 16, top: 30, right: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: neonSurfaceCard,
                              border: Border.all(color: neonAccent.withOpacity(0.4)),
                              borderRadius: radius(),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(canvasColor: neonSurfaceCard, brightness: Brightness.dark),
                              child: DropdownButtonFormField<DocumentModel>(
                                borderRadius: radius(),
                                dropdownColor: neonSurfaceCard,
                                icon: Icon(Icons.arrow_drop_down, color: neonHighlight),
                                style: primaryTextStyle(color: Colors.white),
                                hint: Text(language.selectDocument, style: primaryTextStyle(color: neonHighlight)),
                                decoration: InputDecoration.collapsed(
                                  hintText: null,
                                  focusColor: neonAccent,
                                ),
                                isExpanded: true,
                                isDense: true,
                                items: documentList.map((e) {
                                  return DropdownMenuItem(
                                    value: e,
                                    child: RichText(
                                      text: TextSpan(
                                        text: e.name.validate(),
                                        style: primaryTextStyle(color: Colors.white),
                                        children: [
                                          TextSpan(text: '${e.isRequired == 1 ? ' *' : ''}', style: boldTextStyle(color: neonError)),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (DocumentModel? val) {
                                  docId = val!.id!;
                                  isExpire = val.hasExpiryDate!;

                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ),
                        if (docId != 0)
                          SizedBox(
                            width: 16,
                          ),
                        if (docId != 0)
                          Visibility(
                            visible: !uploadedDocList.contains(docId),
                            child: inkWellWidget(
                              onTap: () {
                                if (isExpire == 1) {
                                  getMultipleFile(docId, isExpire == 0 ? null : 1, dateTime: selectedDate);
                                } else {
                                  getMultipleFile(docId, isExpire == 0 ? null : 1);
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: neonSurfaceCard,
                                  border: Border.all(color: neonAccent.withOpacity(0.4)),
                                  borderRadius: radius(),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, color: neonAccent, size: 24),
                                    SizedBox(width: 8),
                                    Text(language.addDocument, style: secondaryTextStyle(color: neonHighlight)),
                                  ],
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
                    SizedBox(height: 8),
                    // Text(language.fileSizeValidate, style: secondaryTextStyle(size: 12)),
                    Text(language.isMandatoryDocument, style: primaryTextStyle(color: neonError)),
                    SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      itemCount: driverDocumentList.length,
                      physics: NeverScrollableScrollPhysics(),
                      itemBuilder: (_, index) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(driverDocumentList[index].documentName!, style: boldTextStyle(color: Colors.white)),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: neonSurfaceCard,
                                border: Border.all(color: neonAccent.withOpacity(0.38), width: 1),
                                borderRadius: BorderRadius.circular(defaultRadius),
                              ),
                              child: Column(
                                children: [
                                  driverDocumentList[index].driverDocument!.contains('.pdf')
                                      ? InkWell(
                                          child: Column(
                                            children: [
                                              Image.asset(ic_pdf, fit: BoxFit.cover, height: 35, width: 35),
                                              SizedBox(height: 8),
                                              Text(driverDocumentList[index].driverDocument!.split('/').last, style: primaryTextStyle(color: neonHighlight)),
                                            ],
                                          ),
                                          onTap: () {
                                            launchUrl(Uri.parse(driverDocumentList[index].driverDocument.validate()), mode: LaunchMode.externalApplication);
                                          },
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(defaultRadius),
                                          child: commonCachedNetworkImage(driverDocumentList[index].driverDocument!, height: 200, width: MediaQuery.of(context).size.width, fit: BoxFit.cover),
                                        ),
                                  SizedBox(height: 16),
                                  Row(
                                    children: [
                                      driverDocumentList[index].expireDate != null ? Text(language.expireDate, style: boldTextStyle(color: neonHighlight)) : Text(''),
                                      SizedBox(width: 8),
                                      driverDocumentList[index].expireDate != null
                                          ? Expanded(child: Text(driverDocumentList[index].expireDate.toString(), style: primaryTextStyle(color: Colors.white)))
                                          : Expanded(
                                              child: Text(
                                              '',
                                              style: primaryTextStyle(color: Colors.white),
                                            )),
                                      Visibility(
                                        visible: driverDocumentList[index].isVerified == 0,
                                        child: inkWellWidget(
                                          onTap: () {
                                            if (isExpire == 1) {
                                              getMultipleFile(driverDocumentList[index].documentId, driverDocumentList[index].expireDate != null ? 1 : null,
                                                  dateTime: selectedDate, updateId: driverDocumentList[index].id);
                                            } else {
                                              getMultipleFile(driverDocumentList[index].documentId, driverDocumentList[index].expireDate != null ? 1 : null, updateId: driverDocumentList[index].id);
                                            }
                                          },
                                          child: Container(
                                            height: 25,
                                            width: 25,
                                            decoration: BoxDecoration(
                                              color: neonAccent.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: neonAccent),
                                            ),
                                            child: Icon(Icons.edit, color: neonAccent, size: 14),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Visibility(
                                        visible: driverDocumentList[index].isVerified == 0,
                                        child: inkWellWidget(
                                          onTap: () async {
                                            showConfirmDialogCustom(
                                              context,
                                              title: language.areYouSureYouWantToDeleteThisDocument,
                                              onAccept: (BuildContext context) async {
                                                await deleteDoc(driverDocumentList[index].id);
                                              },
                                              positiveText: language.yes,
                                              negativeText: language.no,
                                              primaryColor: primaryColor,
                                            );
                                          },
                                          child: Container(
                                            height: 25,
                                            width: 25,
                                            decoration: BoxDecoration(
                                              color: neonError.withOpacity(0.18),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: neonError),
                                            ),
                                            child: Icon(Icons.delete, color: neonError, size: 14),
                                          ),
                                        ),
                                      ),
                                      driverDocumentList[index].isVerified == 1 ? SizedBox(width: 16) : SizedBox(),
                                      Visibility(
                                        visible: driverDocumentList[index].isVerified == 1,
                                        child: Icon(Icons.verified_user, color: neonAccent),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      separatorBuilder: (_, index) {
                        return Divider();
                      },
                    )
                  ],
                ),
              ),
              Visibility(
                visible: appStore.isLoading,
                child: loaderWidget(),
              ),
              if (!appStore.isLoading && driverDocumentList.isEmpty) emptyWidget()
            ],
          );
        }),
        bottomNavigationBar: driverDocumentList.isNotEmpty
            ? SafeScaffoldBottomBar(
                child: Visibility(
                  visible: widget.isShow,
                  child: Container(
                    color: neonBackground,
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: AppButtonWidget(
                      text: language.goDashBoard,
                      onTap: () {
                        getDetailAPi();
                      },
                    ),
                  ),
                ),
              )
            : SizedBox(),
      ),
    );
  }
}
