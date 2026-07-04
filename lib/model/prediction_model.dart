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

  // US-41: Calculate accuracy - FIXED: returns double
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

  factory PredictionModel.fromMap(Map<String, dynamic> map) {
    return PredictionModel(
      id: map['id'] as String?,
      productId: map['productId'] as String,
      productName: map['productName'] as String,
      predictedQuantity: map['predictedQuantity'] as int,
      actualQuantity: map['actualQuantity'] as int?,
      confidenceLevel: map['confidenceLevel'] as String,
      generatedDate: DateTime.parse(map['generatedDate'] as String),
      forWeekStarting: DateTime.parse(map['forWeekStarting'] as String),
      explanationData: map['explanationData'] as Map<String, dynamic>? ?? {},
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