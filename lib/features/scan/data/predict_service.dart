import 'dart:io';
import 'package:skindisease/features/scan/presentation/predict_result.dart';
import 'package:skindisease/core/tflite/tflite_helper.dart';

class PredictService {
    final List<String> labels = [
    'Cellulitis',
    'Impetigo',
    'Athlete Foot',
    'Nail Fungus',
    'Ringworm',
    'Normal',
    'Cutaneous Larva Migrans',
    'Chickenpox',
    'Shingles',
  ];

  Future<PredictResult> predictSkinDisease(File image) async {
    final List<double> output = await TFLiteHelper.run(image, labels.length);

    double maxScore = output.reduce((a, b) => a > b ? a : b);
    int index = output.indexOf(maxScore);

    return PredictResult(
      label: labels[index],
      confidence: maxScore,
    );
  }
}
