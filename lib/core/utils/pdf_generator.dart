import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/payroll_model.dart';

class PdfGenerator {
  static Future<void> generateAndPrintPayslip(Payslip payslip) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'CONNECT HR ENTERPRISE',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Official Monthly Salary Statement',
                        style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green100,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.green700),
                    ),
                    child: pw.Text(
                      payslip.status.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.green900,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.grey400, height: 24),

              // Employee Details
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Employee Name: ${payslip.employeeName}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Employee ID: ${payslip.employeeId}',
                            style: const pw.TextStyle(color: PdfColors.grey800)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Pay Period: ${payslip.month}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Issued: ${payslip.generatedAt.split('T').first}',
                            style: const pw.TextStyle(color: PdfColors.grey800)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Earnings & Deductions Table
              pw.Text(
                'Compensation & Deductions Breakdown',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Earnings Component', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Amount (₹)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Deductions', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Amount (₹)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Basic Salary')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('₹${payslip.basicSalary.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Provident Fund (PF)')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('₹${payslip.providentFund.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('House Rent Allowance (HRA)')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('₹${payslip.hra.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Income Tax (TDS)')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('₹${payslip.taxDeductions.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Special Allowances')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('₹${payslip.allowances.toStringAsFixed(2)}', textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('-')),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('-', textAlign: pw.TextAlign.right)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Total Calculation
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.indigo200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NET TAKE HOME PAY:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                    pw.Text(
                      '₹ ${payslip.netPay.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer Note
              pw.Divider(color: PdfColors.grey300),
              pw.Center(
                child: pw.Text(
                  'This is a computer-generated payslip and does not require a physical signature.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Payslip_${payslip.month.replaceAll(' ', '_')}_${payslip.employeeName}.pdf',
    );
  }
}
