import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:face_recognition_flutter/models/user.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

import '../../widgets/common_widgets.dart';
import '../home_page.dart';
import 'ml_service.dart';

List<CameraDescription>? cameras;

class FaceScanScreen extends StatefulWidget{
  final User? user;

  const FaceScanScreen({Key? key, this.user}) : super(key: key);

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen>{
  //text controller, camera controller, flash-controller, face detector,(from Google ML Kit) mlservice
  TextEditingController controller = TextEditingController();
  // late List<CameraDescription> cameras;
  late CameraController _cameraController;
  bool flash = false;
  bool isControllerInitialized = false;

  late FaceDetector _faceDetector;
  final MLService _mlService = MLService();
  List<Face> facesDetected = [];

  //Initialize Cameras-at first flash off
  Future initializeCamera() async{
    await _cameraController.initialize();
    isControllerInitialized = true;
    _cameraController.setFlashMode(FlashMode.off);
    setState(() {});
  }

  //Image Rotation
  InputImageRotation rotationIntToImageRotation(int rotation) {
    switch(rotation){
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;  
      default: 
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> detectFacesFromImage(CameraImage image) async{
    InputImageData _firebaseImageMetadata = InputImageData(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        imageRotation: rotationIntToImageRotation(_cameraController.description.sensorOrientation),
        inputImageFormat: InputImageFormat.bgra8888,
        planeData: image.planes.map(
            (Plane plane){
              return InputImagePlaneMetadata(
                  bytesPerRow: plane.bytesPerRow,
                  height: plane.height,
                  width: plane.width,
              );
            }
        ).toList(),
    );

    InputImage _firebaseVisionImage = InputImage.fromBytes(
        bytes: Uint8List.fromList(
          image.planes.fold(
              <int>[],
                  (List<int> previousValue, element) =>
              previousValue..addAll(element.bytes)),
        ),
        inputImageData: _firebaseImageMetadata,
    );

    //processing with input image and assign detected faces to list
    var result = await _faceDetector.processImage(_firebaseVisionImage);
    if(result.isNotEmpty){
      facesDetected = result;
    }
  }

  //Predict Face from Image
  Future<void> _predictFacesFromImage({required CameraImage image}) async{
    await detectFacesFromImage(image);

    if(facesDetected.isNotEmpty){
      User? user = await _mlService.predict(
          image,
          facesDetected[0], //first face
          widget.user != null,
          widget.user != null ? widget.user!.name! : controller.text);
      if(widget.user == null){
        //register case
        Navigator.pop(context);
        print("User registered successfully!");
      } else{
        //login case
        if(user == null){
          Navigator.pop(context);
          print("Unknown User");
        } else{
          Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage()));
        }
      }
    }

    if(mounted) setState(() {});
    await takePicture();
  }

  Future<void> takePicture() async{
    if(facesDetected.isNotEmpty){
      await _cameraController.stopImageStream();
      XFile file = await _cameraController.takePicture();
      file = XFile(file.path);
      _cameraController.setFlashMode(FlashMode.off);
    } else{
      showDialog(context: context, builder: (context) =>
      const AlertDialog(content: Text("Processing...No Faces Detected if took long"),));
    }
  }

  @override
  void initState() {
    _cameraController = CameraController(cameras![0], ResolutionPreset.high);
    initializeCamera();
    _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
          FocusScopeNode currentFocus = FocusScope.of(context);

          if(!currentFocus.hasPrimaryFocus){
            currentFocus.unfocus();
          }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            //frame box
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: isControllerInitialized ?
                  Transform.rotate(
                    angle: -pi / 2, // rotate the camera preview by 90 degrees
                    child: CameraPreview(_cameraController),
                  )
                  : null
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children:[
                    //loading animation space while processing
                    Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Lottie.asset("assets/loading.json",
                              width: MediaQuery.of(context).size.width * 0.7),
                        )
                    ),

                    //text name input
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),

                    //Button and flash mode
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: CWidgets.customExtendedButton(
                              text: "Capture",
                              context: context,
                              isClickable: true,
                              onTap: (){
                                bool canProcess = false;
                                _cameraController.startImageStream((CameraImage image) async {
                                  if(canProcess) return;
                                  canProcess = true;
                                  _predictFacesFromImage(image: image).then((value){
                                    canProcess = false;
                                  });
                                  return null;
                                });
                              },
                          )
                        ),

                        //Flash Icon Button
                        IconButton(
                          icon: Icon(
                            flash ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: (){
                            setState(() {
                              flash = !flash;
                            });
                            flash ? _cameraController.setFlashMode(FlashMode.torch)
                                : _cameraController.setFlashMode(FlashMode.off);
                          },
                        )
                      ],
                    ),
                  ]
                ),
              ),
            const SizedBox(
              height: 30,
            ),
          ],
        )
      )
    );
  }
}