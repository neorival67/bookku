import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/book.dart';

class PdfViewerScreen extends StatefulWidget {
  final Book book;
  
  const PdfViewerScreen({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfViewerController _pdfViewerController;
  bool _isLoading = true;
  String? _directPdfUrl;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _validateAndConvertPdfUrl();
  }

  String _getDirectDownloadUrl(String? driveUrl) {
    if (driveUrl == null || driveUrl.isEmpty) return '';
    
    // Handle different Google Drive URL formats
    String fileId = '';
    
    if (driveUrl.contains('drive.google.com/file/d/')) {
      // Format: https://drive.google.com/file/d/{fileId}/view
      fileId = driveUrl.split('/file/d/')[1].split('/')[0];
    } else if (driveUrl.contains('drive.google.com/open')) {
      // Format: https://drive.google.com/open?id={fileId}
      fileId = driveUrl.split('id=')[1].split('&')[0];
    }
    
    if (fileId.isEmpty) return driveUrl; // Return original if not a Drive URL
    
    // Convert to direct download URL
    return 'https://drive.google.com/uc?export=download&id=$fileId';
  }

  void _validateAndConvertPdfUrl() {
    if (widget.book.pdfUrl == null || widget.book.pdfUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF URL is not available'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _directPdfUrl = _getDirectDownloadUrl(widget.book.pdfUrl);
        _isLoading = false;
      });
      print('Direct PDF URL: $_directPdfUrl'); // For debugging
    }
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel + 0.25;
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: () {
              _pdfViewerController.zoomLevel = _pdfViewerController.zoomLevel - 0.25;
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading PDF...'),
                ],
              ),
            )
          : _directPdfUrl == null || _directPdfUrl!.isEmpty
              ? const Center(
                  child: Text('Failed to load PDF'),
                )
              : SfPdfViewer.network(
                  _directPdfUrl!,
                  controller: _pdfViewerController,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    print('PDF loaded successfully. Pages: ${details.document.pages.count}');
                  },
                  onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                    print('PDF load failed: ${details.error}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to load PDF: ${details.error}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  enableDoubleTapZooming: true,
                  enableTextSelection: true,
                  interactionMode: PdfInteractionMode.pan,
                ),
    );
  }
}
