import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';

class ImportedDocumentText {
  const ImportedDocumentText({
    required this.name,
    required this.text,
    this.path,
  });

  final String name;
  final String text;
  final String? path;
}

class DocumentTextExtractor {
  Future<ImportedDocumentText?> pickAndExtract() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: <String>['txt', 'pdf', 'docx'],
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final text = extractTextFromBytes(bytes, file.name);
    return ImportedDocumentText(name: file.name, text: text, path: file.path);
  }

  Future<String> extractTextFromPath(String path) async {
    final bytes = await File(path).readAsBytes();
    return extractTextFromBytes(bytes, path);
  }

  String extractTextFromBytes(Uint8List bytes, String nameOrPath) {
    final extension = p.extension(nameOrPath).toLowerCase();
    return switch (extension) {
      '.txt' => _decodeText(bytes),
      '.pdf' => _extractPdfText(bytes),
      '.docx' => _extractDocxText(bytes),
      _ => throw StateError('仅支持 TXT、PDF 或 Word DOCX 文件'),
    };
  }

  String _decodeText(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  String _extractPdfText(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      return PdfTextExtractor(document).extractText().trim();
    } finally {
      document.dispose();
    }
  }

  String _extractDocxText(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final documentXml = archive.findFile('word/document.xml');
    if (documentXml == null) {
      throw StateError('这个 Word 文件没有可读取的正文');
    }
    final xmlText = utf8.decode(documentXml.content);
    final document = XmlDocument.parse(xmlText);
    final buffer = StringBuffer();
    for (final paragraph in document.findAllElements('w:p')) {
      final text = paragraph
          .findAllElements('w:t')
          .map((node) => node.innerText)
          .join();
      if (text.trim().isNotEmpty) {
        buffer.writeln(text.trim());
      }
    }
    return buffer.toString().trim();
  }
}
