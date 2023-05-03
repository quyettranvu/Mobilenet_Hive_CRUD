import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:face_recognition_flutter/models/user.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;

import '../../utils/local_db.dart';
import '../../utils/utils.dart';
import 'image_converter.dart';

class MLService {
  late Interpreter interpreter;
  List? predictedArray;


  //async function to predict user
  Future<User?> predict(CameraImage cameraImage, Face face, bool loginUser, String name)
  async {
      //pre-processing
      List input = _preProcess(cameraImage, face);
      input = input.reshape([1, 112, 112, 3]); //1 dimension(single image), 112 pixels in height, 112 pixels in width, and 3 color channels (red, green, blue).

      /*Note: changing the output size might affect the accuracy of the model's predictions*/
      List output = List.generate(1, (index) => List.filled(192, 0)); //output has size (1 row, 192 columns initialized with 0)

      await initializeInterpreter();

      //run interpreter
      interpreter.run(input, output);
      output = output.reshape([192]);

      predictedArray = List.from(output);

      //If register set Data to Hive Box
      if(!loginUser){
        LocalDB.setUserDetails(User(name: name, array: predictedArray!));
        return null;
      }
      //if login then check existing User
      else{
        User? user = LocalDB.getUser();
        List userArray = user.array!;
        int minDist = 999;
        double threshold = 1.5;
        var dist = euclideanDistance(predictedArray!, userArray);
        if (dist <= threshold && dist < minDist) {
          return user;
        } else {
          return null;
        }
      }
  }

  euclideanDistance(List l1, List l2) {
    double sum = 0;
    for (int i = 0; i < l1.length; i++) {
      sum += pow((l1[i] - l2[i]), 2);
    }

    return pow(sum, 0.5);
  }

  //Initialize Interpreter
  initializeInterpreter() async {
    try {
      var interpreterOptions = InterpreterOptions();
      interpreter = await Interpreter.fromAsset('mobilefacenet.tflite',
          options: interpreterOptions);
    } catch (e) {
      printIfDebug('Failed to load model.');
      printIfDebug(e);
    }
  }
  // initializeInterpreter() async {
  //   Delegate? delegate;
  //   try {
  //     if (Platform.isAndroid) {
  //       delegate = GpuDelegateV2(
  //           options: GpuDelegateOptionsV2(
  //             isPrecisionLossAllowed: false,
  //             inferencePreference: TfLiteGpuInferenceUsage.fastSingleAnswer,
  //             inferencePriority1: TfLiteGpuInferencePriority.minLatency,
  //             inferencePriority2: TfLiteGpuInferencePriority.auto,
  //             inferencePriority3: TfLiteGpuInferencePriority.auto,
  //           ));
  //     } else if (Platform.isIOS) {
  //       delegate = GpuDelegate(
  //         options: GpuDelegateOptions(
  //             allowPrecisionLoss: true,
  //             waitType: TFLGpuDelegateWaitType.active),
  //       );
  //     }
  //     var interpreterOptions = InterpreterOptions()..addDelegate(delegate!);
  //
  //     interpreter = await Interpreter.fromAsset('mobilefacenet.tflite',
  //         options: interpreterOptions);
  //   } catch (e) {
  //     printIfDebug('Failed to load model.');
  //     printIfDebug(e);
  //   }
  // }


  //Preprocessing image
  List _preProcess(CameraImage image, Face faceDetected){
    imglib.Image croppedImage = _cropFace(image, faceDetected);
    imglib.Image img = imglib.copyResizeCropSquare(croppedImage,112);

    Float32List imageAsList = _imageToByteListFloat32(img);
    return imageAsList;
  }

  //Cropping  a face from an image captured by a frame box
  imglib.Image _cropFace(CameraImage image, Face faceDetected){
    imglib.Image convertedImage = convertedCameraImage(image);

    //ensure bounding box of captured face will be included in the cropped image
    double x = faceDetected.boundingBox.left - 10.0;
    double y = faceDetected.boundingBox.top -10.0;
    double w = faceDetected.boundingBox.width + 10.0;
    double h = faceDetected.boundingBox.height + 10.0;

    return imglib.copyCrop(
        convertedImage,x.round(),y.round(),w.round(),h.round());
  }

  //rotate or not depends on the orientation of the camera sensor relative to the device's display
  imglib.Image convertedCameraImage(CameraImage image){
    var img = convertToImage(image);
    var img1 = imglib.copyRotate(img!,-90);
    return img1;
  }

  Float32List _imageToByteListFloat32(imglib.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (imglib.getRed(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getGreen(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getBlue(pixel) - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

}