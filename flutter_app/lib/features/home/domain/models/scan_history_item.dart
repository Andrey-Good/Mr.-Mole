import 'dart:convert';

class ScanHistoryItem {
  final String id;
  final String imagePath;
  final String result;
  final DateTime timestamp;
  final String? moleLocation;

  ScanHistoryItem({
    required this.id,
    required this.imagePath,
    required this.result,
    required this.timestamp,
    this.moleLocation,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: json['id'],
      imagePath: json['imagePath'],
      result: json['result'],
      timestamp: DateTime.parse(json['timestamp']),
      moleLocation: json['moleLocation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'result': result,
      'timestamp': timestamp.toIso8601String(),
      'moleLocation': moleLocation,
    };
  }

  static String encode(List<ScanHistoryItem> items) {
    return json.encode(
      items.map<Map<String, dynamic>>((item) => item.toJson()).toList(),
    );
  }

  static List<ScanHistoryItem> decode(String items) {
    return (json.decode(items) as List<dynamic>)
        .map<ScanHistoryItem>((item) => ScanHistoryItem.fromJson(item))
        .toList();
  }
}
