// novo arquivo: lib/services/pdf_service.dart

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateAndPrintQrPdf({
    required String establishmentName,
    required String deepLink,
  }) async {
    // Cria um novo documento PDF
    final doc = pw.Document();

    // Carrega a imagem do logo dos assets para usar no PDF
    final logoImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    // Adiciona uma página ao documento
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(height: 120, child: pw.Image(logoImage)),
                pw.SizedBox(height: 20),
                pw.Text(
                  establishmentName,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 40),
                // Gera o QR Code diretamente no PDF
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: deepLink,
                  width: 200,
                  height: 200,
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'Aponte a câmera do seu celular para este código\ne entre na fila automaticamente!',
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Abre o diálogo nativo de impressão/compartilhamento do PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}
