

import 'dart:math';

import 'package:analyzer_plugin/utilities/pair.dart';

abstract class FaceFeatureComparator {
  ID? findBest<ID>(List<double> target, List<Pair<ID, List<double>>> featureList);

  double compare(List<double> feature1, List<double> feature2);
}

class ArcFaceComparator implements FaceFeatureComparator {

  double threshold;

  ArcFaceComparator(this.threshold);

  @override
  double compare(List<double> feature1, List<double> feature2) {
    return _cosineSimilarity(feature1, feature2);
  }

  double _cosineSimilarity(List<double> e1, List<double> e2) {

    List<double> normE1 = _normalize(e1);
    List<double> normE2 = _normalize(e2);

    int len = normE1.length;

    double sum = 0.0;
    for (int i = 0; i < len; i++) {
      sum += normE1[i] * normE2[i];
    }

    print("ArcFaceComparator: Inner product: $sum");
    return sum;
  }

  List<double> _normalize(List<double> e) {
    int len = e.length;

    double sum = 0.0;

    // e.reduce((value, element) => value + element * element);

    for (int i = 0; i < len; i++) {
      sum += e[i] * e[i];
    }

    double sigma = sqrt(sum);

    List<double> result = List.generate(len, (index) => e[index] / sigma);

    return result;
  }

  @override
  ID? findBest<ID>(List<double> target, List<Pair<ID, List<double>>> featureList) {
    ID? currentBest;
    double bestValue = -1;

    for (final feature in featureList) {
      final result = compare(target, feature.last);
      if (result > bestValue) {
        bestValue = result;
        currentBest = feature.first;
      }
    }

    if (bestValue > threshold) {
      return currentBest;
    }

    return null;
  }

}