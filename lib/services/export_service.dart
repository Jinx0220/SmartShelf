import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ExportService {
  // Export to CSV
  Future<String> exportToCSV(List<Map<String, dynamic>> data, List<String> headers) async {
    try {
      StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln(headers.join(','));

      for (var row in data) {
        List<String> rowValues = [];
        for (var header in headers) {
          var value = row[header];
          String stringValue = value?.toString() ?? '';
          if (stringValue.contains(',') || stringValue.contains('"')) {
            stringValue = '"${stringValue.replaceAll('"', '""')}"';
          }
          rowValues.add(stringValue);
        }
        csvBuffer.writeln(rowValues.join(','));
      }

      return csvBuffer.toString();
    } catch (e) {
      throw Exception('Failed to generate CSV: $e');
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

  // Share file
  Future<void> shareFile(File file, String message) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: message,
      );
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  // Share text
  Future<void> shareText(String text) async {
    try {
      await Share.share(text);
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

      await Share.shareXFiles(
        [XFile(path)],
        text: 'SmartShelf Backup Data',
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