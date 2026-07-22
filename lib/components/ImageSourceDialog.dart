import 'package:flutter/material.dart';

import '../main.dart';
import '../utils/Extensions/extension.dart';
import '../utils/utils.dart';

/// Menú de fuentes (Galería / Cámara / Archivo) con fondo blanco y texto oscuro
/// para buen contraste sobre temas oscuros de la app.
class ImageSourceDialog extends StatefulWidget {
  final Function()? onGallery;
  final Function()? onCamera;
  final Function()? onFile;
  final bool isFile;

  ImageSourceDialog({this.onGallery, this.onCamera, this.onFile, this.isFile = false});

  @override
  State<ImageSourceDialog> createState() => _ImageSourceDialogState();
}

class _ImageSourceDialogState extends State<ImageSourceDialog> {
  static const Color _titleColor = Color(0xFF0B1B33);
  static const Color _textColor = Color(0xFF0B1B33);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(defaultRadius),
          topRight: Radius.circular(defaultRadius),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.selectSources, style: boldTextStyle(size: 18, color: _titleColor)),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(color: _titleColor.withOpacity(0.08), shape: BoxShape.circle),
                  child: Icon(Icons.close, size: 20, color: _titleColor),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          inkWellWidget(
            onTap: widget.onGallery ?? () {},
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(ic_gallery, height: 26, width: 26, fit: BoxFit.cover, color: _textColor),
                  SizedBox(width: 8),
                  Text(language.gallery, style: primaryTextStyle(color: _textColor)),
                ],
              ),
            ),
          ),
          Divider(height: 16, color: Colors.black26),
          inkWellWidget(
            onTap: widget.onCamera ?? () {},
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(ic_camera, height: 26, width: 26, fit: BoxFit.cover, color: _textColor),
                  SizedBox(width: 8),
                  Text(language.camera, style: primaryTextStyle(color: _textColor)),
                ],
              ),
            ),
          ),
          if (widget.isFile) ...[
            Divider(height: 16, color: Colors.black26),
            inkWellWidget(
              onTap: widget.onFile ?? () {},
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(ic_pdf, height: 26, width: 26, fit: BoxFit.cover, color: _textColor),
                    SizedBox(width: 8),
                    Text(language.file, style: primaryTextStyle(color: _textColor)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
