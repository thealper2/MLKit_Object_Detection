import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'MLKit Object Detection'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  late List<DetectedObject> objects;
  var image;
  String result = "";
  late ImagePicker imagePicker;

  dynamic objectDetector;
  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    final options = ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true);
    objectDetector = ObjectDetector(options: options);
  }

  pickImage(bool fromGallery) async {
    XFile? pickedFile = await imagePicker.pickImage(
        source: fromGallery ? ImageSource.gallery : ImageSource.camera);
    File image = File(pickedFile!.path);
    setState(() {
      _image = image;
      if (_image != null) {
        objectDetection();
      }
    });
  }

  objectDetection() async {
    result = "";
    final inputImage = InputImage.fromFile(_image!);
    objects = await objectDetector.processImage(inputImage);

    image = await _image?.readAsBytes();
    image = await decodeImageFromList(image);

    setState(() {
      image;
      objects;
      result;
    });
  }

  @override
  void dispose() {
    super.dispose();
    objectDetector.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(widget.title),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _image != null
                ? Container(
                  height: 350,
                  width: 350,
                  child: FittedBox(
                    child: SizedBox(
                      height: image.width.toDouble(),
                      width: image.width.toDouble(),
                      child: CustomPaint(
                          painter:
                              ObjectPainter(objectList: objects, imageFile: image),
                        ),
                    ),
                  ),
                )
                : Container(
                  height: 350,
                  width: 350,
                  child: FittedBox(
                    child: SizedBox(
                      height: 350,
                      width: 350,
                      child: Icon(
                          Icons.image,
                        size: 350,
                        ),
                    ),
                  ),
                ),
            ElevatedButton(
              onPressed: () {
                pickImage(true);
              },
              onLongPress: () {
                pickImage(false);
              },
              child: Text("Choose"),
            ),
          ],
        ),
      ),
    );
  }
}

class ObjectPainter extends CustomPainter {
  List<DetectedObject> objectList;
  dynamic imageFile;
  ObjectPainter({required this.objectList, @required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    for (DetectedObject object in objectList) {
      paintObject(object, canvas, size);
    }
  }

  void paintObject(DetectedObject object, Canvas canvas, Size size) {
    final paint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8;

    canvas.drawRect(object.boundingBox, paint);
    var list = object.labels;
    for (Label label in list) {
      TextSpan span = TextSpan(
          text: label.text,
          style: const TextStyle(
              fontSize: 35, fontWeight: FontWeight.bold, color: Colors.blue));

      TextPainter painter = TextPainter(
          text: span,
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr);

      painter.layout();
      painter.paint(canvas, Offset(object.boundingBox.left, object.boundingBox.top));
      break;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
