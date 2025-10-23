import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:google_fonts/google_fonts.dart';

class PdfViewerPage extends StatefulWidget {
  final String pdfUrl;
  final String? title;

  const PdfViewerPage({
    Key? key,
    required this.pdfUrl,
    this.title,
  }) : super(key: key);

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isLoading = true;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 700;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Memo Viewer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_hasError) {
            return Center(
              child: Text(
                'Failed to load PDF 😞',
                style: GoogleFonts.poppins(color: Colors.red, fontSize: 16),
              ),
            );
          }

          return Stack(
            children: [
              SfPdfViewer.asset(
                'assets/memo_file.pdf',
                key: _pdfViewerKey,
                onDocumentLoaded: (_) {
                  setState(() => _isLoading = false);
                },
                onDocumentLoadFailed: (_) {
                  setState(() {
                    _hasError = true;
                    _isLoading = false;
                  });
                },
              ),
              if (_isLoading)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Loading PDF...',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
