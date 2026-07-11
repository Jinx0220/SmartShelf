import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  Future<String> exportToCSV(
      List<Map<String, dynamic>> data,
      List<String> headers,
      ) async {
    List<List<dynamic>> rows = [];

    rows.add(headers);

    for (var item in data) {
      rows.add(headers.map((h) => item[h] ?? '').toList());
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<File> saveCSVToFile(String csv, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();

    final file = File(
      '${directory.path}/$fileName.csv',
    );

    await file.writeAsString(csv);

    return file;
  }

  Future<void> shareFile(
      File file,
      String message,
      ) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: message,
      ),
    );
  }

  Future<void> shareText(String text) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
      ),
    );
  }

  Future<void> shareToWhatsApp(String text) async {
    await SharePlus.instance.share(
      ShareParams(
        text: text,
      ),
    );
  }

  Future<void> printOrder(String orderText) async {
    print(orderText);
  }
}