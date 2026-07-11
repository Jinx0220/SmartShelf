import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionModel {
  String? id;
  String productId;
  String productName;
  int predictedQuantity;
  int? actualQuantity;
  String confidenceLevel;
  DateTime generatedDate;
  DateTime forWeekStarting;
  Map<String, dynamic> explanationData;

  PredictionModel({
    this.id,
    required this.productId,
    required this.productName,
    required this.predictedQuantity,
    this.actualQuantity,
    required this.confidenceLevel,
    required this.generatedDate,
    required this.forWeekStarting,
    required this.explanationData,
  });

  bool get isHighConfidence => confidenceLevel == 'High';
  bool get isMediumConfidence => confidenceLevel == 'Medium';
  bool get isLowConfidence => confidenceLevel == 'Low';
  bool get isInsufficient => confidenceLevel == 'Insufficient';

  String get confidenceColor {
    switch (confidenceLevel) {
      case 'High':
        return 'success';
      case 'Medium':
        return 'tertiary';
      case 'Low':
        return 'warning';
      default:
        return 'secondary';
    }
  }

  double get accuracy {
    if (actualQuantity == null || actualQuantity == 0) return 0.0;
    if (predictedQuantity == 0) return 0.0;
    final diff = (predictedQuantity - actualQuantity!).abs();
    final accuracyValue = ((1 - (diff / predictedQuantity)) * 100).clamp(0.0, 100.0);
    return accuracyValue.toDouble();
  }

  String get accuracyLabel {
    if (actualQuantity == null) return 'Not measured';
    final acc = accuracy;
    if (acc >= 80) return 'Excellent';
    if (acc >= 60) return 'Good';
    if (acc >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'predictedQuantity': predictedQuantity,
      'actualQuantity': actualQuantity,
      'confidenceLevel': confidenceLevel,
      'generatedDate': generatedDate.toIso8601String(),
      'forWeekStarting': forWeekStarting.toIso8601String(),
      'explanationData': explanationData,
    };
  }

  factory PredictionModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    // Fixed conversion vulnerability using cross-compatible dynamic checking
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return PredictionModel(
      id: documentId ?? map['id'] as String?,
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? 'Unknown Product',
      predictedQuantity: map['predictedQuantity'] as int? ?? 0,
      actualQuantity: map['actualQuantity'] as int?,
      confidenceLevel: map['confidenceLevel'] as String? ?? 'Low',
      generatedDate: parseDate(map['generatedDate']),
      forWeekStarting: parseDate(map['forWeekStarting']),
      explanationData: map['explanationData'] != null
          ? Map<String, dynamic>.from(map['explanationData'] as Map)
          : {},
    );
  }

  PredictionModel copyWith({
    String? id,
    String? productId,
    String? productName,
    int? predictedQuantity,
    int? actualQuantity,
    String? confidenceLevel,
    DateTime? generatedDate,
    DateTime? forWeekStarting,
    Map<String, dynamic>? explanationData,
  }) {
    return PredictionModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      predictedQuantity: predictedQuantity ?? this.predictedQuantity,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      generatedDate: generatedDate ?? this.generatedDate,
      forWeekStarting: forWeekStarting ?? this.forWeekStarting,
      explanationData: explanationData ?? this.explanationData,
    );
  }
}