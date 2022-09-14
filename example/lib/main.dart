import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Save image to gallery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _requestPermission(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Save image to gallery"),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              RepaintBoundary(
                key: _globalKey,
                child: Container(
                  width: 200,
                  height: 200,
                  color: Colors.red,
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 15),
                width: 200,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _saveScreen(context),
                  child: const Text("Save Local Image"),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 15),
                width: 200,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _getHttp(context),
                  child: const Text("Save network image"),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 15),
                width: 200,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _saveVideo(context),
                  child: const Text("Save network video"),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(top: 15),
                width: 200,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => _saveGif(context),
                  child: const Text("Save Gif to gallery"),
                ),
              ),
            ],
          ),
        ));
  }

  _requestPermission(BuildContext context) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();

    final info = statuses[Permission.storage].toString();
    log(info);
    if (!mounted) return;
    _toastInfo(context, info);
  }

  _saveScreen(BuildContext context) async {
    RenderRepaintBoundary boundary =
        _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage();
    ByteData? byteData =
        await (image.toByteData(format: ui.ImageByteFormat.png));
    if (byteData != null) {
      final result =
          await ImageGallerySaver.saveImage(byteData.buffer.asUint8List());
      log(result);
      if (!mounted) return;
      _toastInfo(context, result.toString());
    }
  }

  _getHttp(BuildContext context) async {
    var response = await Dio().get(
        "https://ss0.baidu.com/94o3dSag_xI4khGko9WTAnF6hhy/image/h%3D300/sign=a62e824376d98d1069d40a31113eb807/838ba61ea8d3fd1fc9c7b6853a4e251f94ca5f46.jpg",
        options: Options(responseType: ResponseType.bytes));
    final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(response.data),
        quality: 60,
        name: "hello");
    log(result);
    if (!mounted) return;
    _toastInfo(context, "$result");
  }

  _saveGif(BuildContext context) async {
    var appDocDir = await getTemporaryDirectory();
    String savePath = "${appDocDir.path}/temp.gif";
    String fileUrl =
        "https://hyjdoc.oss-cn-beijing.aliyuncs.com/hyj-doc-flutter-demo-run.gif";
    await Dio().download(fileUrl, savePath);
    final result = await ImageGallerySaver.saveFile(savePath);
    log(result);
    if (!mounted) return;
    _toastInfo(context, "$result");
  }

  _saveVideo(BuildContext context) async {
    var appDocDir = await getTemporaryDirectory();
    String savePath = "${appDocDir.path}/temp.mp4";
    String fileUrl =
        "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4";
    await Dio().download(fileUrl, savePath, onReceiveProgress: (count, total) {
      log("${(count / total * 100).toStringAsFixed(0)}%");
    });
    final result = await ImageGallerySaver.saveFile(savePath);
    log(result);
    if (!mounted) return;
    _toastInfo(context, "$result");
  }

  _toastInfo(BuildContext context, String info) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(info)),
    );
  }
}
