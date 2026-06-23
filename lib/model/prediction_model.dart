class PredictionModel {
  String? id;
  String productId;
  String productName;
  int predictedQuantity;
  int? actualQuantity;
  String confidenceLevel; // High, Medium, Low, Insufficient
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

  // Computed properties
  bool get isHighConfidence => confidenceLevel == 'High';
  bool get isMediumConfidence => confidenceLevel == 'Medium';
  bool get isLowConfidence => confidenceLevel == 'Low';
  bool get isInsufficient => confidenceLevel == 'Insufficient';
}