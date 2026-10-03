import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';

class TFLiteHelper {
  static const int inputSize = 224;
  static Interpreter? _interpreter;
  static bool get isModelLoaded => _interpreter != null;

  static Future<void> loadModel() async {
    if (_interpreter != null) return;
    try {
      // ✅ Load via rootBundle lalu tulis ke temp file
      // Ini cara paling reliable untuk semua versi tflite_flutter
      final byteData = await rootBundle.load(
        'assets/models/efficientnet_lite_skin_disease.tflite',
      );

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/efficientnet_lite_skin_disease.tflite');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      final options = InterpreterOptions()..threads = 2;
      _interpreter = Interpreter.fromFile(tempFile, options: options);

      print('✅ Model berhasil di-load via rootBundle');
      print('Input shape : ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      _interpreter = null;
      throw Exception('Gagal load model: $e');
    }
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  static List<List<List<List<double>>>> preprocess(File imageFile) {
    final bytes = imageFile.readAsBytesSync();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Gagal decode gambar');

    final image = img.copyResize(
      decoded,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    return [
      List.generate(inputSize, (y) {
        return List.generate(inputSize, (x) {
          final pixel = image.getPixel(x, y);
          // EfficientNet preprocessing: [0,255] → [-1, 1]
          final r = (pixel.r / 127.5) - 1.0;
          final g = (pixel.g / 127.5) - 1.0;
          final b = (pixel.b / 127.5) - 1.0;
          return [r, g, b];
        });
      }),
    ];
  }

  static Future<List<double>> run(File imageFile, int numClasses) async {
    if (_interpreter == null) await loadModel();
    if (_interpreter == null) throw Exception('Interpreter tidak tersedia');

    try {
      final input = preprocess(imageFile);
      final output = List.filled(numClasses, 0.0).reshape([1, numClasses]);
      _interpreter!.run(input, output);
      return List<double>.from(output[0]);
    } catch (e) {
      throw Exception('Inferensi gagal: $e');
    }
  }
}