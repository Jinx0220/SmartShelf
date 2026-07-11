import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:csv/csv.dart';

class ExportService {

  // Export to CSV using the modern csv 8.0.0+ global encoder
  Future<String> exportToCSV(List<Map<String, dynamic>> data, List<String> headers) async {
    try {
      List<List<dynamic>> csvData = [];

      // Add the header row
      csvData.add(headers);

      // Add the data rows
      for (var row in data) {
        List<dynamic> rowValues = [];
        for (var header in headers) {
          rowValues.add(row[header] ?? '');
        }
        csvData.add(rowValues);
      }

      // Utilizing top-level codec serialization engine
      return csv.encode(csvData);
    } catch (e) {
      throw Exception('Failed to generate CSV: $e');
    }
  }

  // Parse raw CSV text into a matrix grid using the modern csv 8.0.0+ global decoder
  Future<List<List<dynamic>>> parseCSV(String csvContent) async {
    try {
      if (csvContent.isEmpty) return [];
      // Utilizing top-level codec deserialization engine
      return csv.decode(csvContent);
    } catch (e) {
      throw Exception('Failed to parse imported CSV data: $e');
    }
  }

  // Save CSV to file
  Future<File> saveCSVToFile(String csv, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/$fileName.csv';
      final file = File(path);
      await file.writeAsString(csv);
      return file;
    } catch (e) {
      throw Exception('Failed to save CSV: $e');
    }
  }

  // Share file using unified ShareParams payload configuration
  Future<void> shareFile(File file, String message) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: 'SmartShelf Share',
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  // Share text using unified ShareParams payload configuration
  Future<void> shareText(String text) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: text),
      );
    } catch (e) {
      throw Exception('Failed to share text: $e');
    }
  }

  // Share to WhatsApp
  Future<void> shareToWhatsApp(String text) async {
    try {
      final encodedText = Uri.encodeComponent(text);
      final url = 'whatsapp://send?text=$encodedText';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        await shareText(text);
      }
    } catch (e) {
      throw Exception('Failed to share to WhatsApp: $e');
    }
  }

  // Print order
  Future<void> printOrder(String orderText) async {
    throw UnimplementedError('Printing not yet implemented');
  }

  // US-53: Backup data to cloud
  Future<void> backupData(Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(path);
      await file.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(
          text: 'SmartShelf Backup Data',
          files: [XFile(path)],
        ),
      );
    } catch (e) {
      throw Exception('Failed to backup data: $e');
    }
  }

  // US-54: Restore data from backup
  Future<Map<String, dynamic>> restoreData(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString);
      return data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to restore data: $e');
    }
  }
}