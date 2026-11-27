import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/scanner_frame_painter.dart';

Future<void> showHomeIsbnScannerDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> books,
  required Future<Map<String, dynamic>?> Function(String isbn) onSearchIsbn,
  required ValueChanged<Map<String, dynamic>> onBookSelected,
  required ValueChanged<String> onMessage,
}) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (dialogContext) {
      return _HomeIsbnScannerDialog(
        books: books,
        onSearchIsbn: onSearchIsbn,
        onBookSelected: onBookSelected,
        onMessage: onMessage,
      );
    },
  );
}

class _HomeIsbnScannerDialog extends StatefulWidget {
  const _HomeIsbnScannerDialog({
    required this.books,
    required this.onSearchIsbn,
    required this.onBookSelected,
    required this.onMessage,
  });

  final List<Map<String, dynamic>> books;
  final Future<Map<String, dynamic>?> Function(String isbn) onSearchIsbn;
  final ValueChanged<Map<String, dynamic>> onBookSelected;
  final ValueChanged<String> onMessage;

  @override
  State<_HomeIsbnScannerDialog> createState() => _HomeIsbnScannerDialogState();
}

class _HomeIsbnScannerDialogState extends State<_HomeIsbnScannerDialog> {
  final TextEditingController isbnController = TextEditingController();
  late final MobileScannerController scannerController;
  bool scanningIsbn = false;

  Color get _surface => AppColors.surfaceOf(context);
  Color get _textPrimary => AppColors.textPrimaryOf(context);
  Color get _textSecondary => AppColors.textSecondaryOf(context);
  Color get _gold => AppColors.goldOf(context);
  Color get _onDeep => AppColors.isDark(context)
      ? AppColors.darkTextPrimary
      : AppColors.background;

  @override
  void initState() {
    super.initState();

    scannerController = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [BarcodeFormat.ean13],
    );
  }

  @override
  void dispose() {
    isbnController.dispose();
    unawaited(scannerController.dispose());
    super.dispose();
  }

  Future<void> _openBookFromIsbn(String rawIsbn) async {
    if (scanningIsbn) return;

    final normalized = rawIsbn.replaceAll(RegExp(r'[^0-9Xx]'), '');

    if (normalized.isEmpty) {
      Navigator.of(context).pop();
      widget.onMessage('Escribe un ISBN para buscarlo.');
      return;
    }

    setState(() {
      scanningIsbn = true;
    });

    try {
      final found = await widget.onSearchIsbn(normalized);

      if (!mounted) return;

      Navigator.of(context).pop();

      if (found == null) {
        widget.onMessage('No encontramos un libro con el ISBN $normalized.');
        return;
      }

      widget.onBookSelected(found);
    } catch (_) {
      if (!mounted) return;

      Navigator.of(context).pop();

      widget.onMessage('No fue posible buscar el libro. Inténtalo nuevamente.');
    } finally {
      if (mounted) {
        setState(() {
          scanningIsbn = false;
        });
      }
    }
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (scanningIsbn) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;

      if (rawValue == null || rawValue.isEmpty) {
        continue;
      }

      final isbn = rawValue.replaceAll(RegExp(r'[^0-9]'), '');

      if (!RegExp(r'^(978|979)\d{10}$').hasMatch(isbn)) {
        continue;
      }

      isbnController.text = isbn;

      unawaited(_openBookFromIsbn(isbn));
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF120C0A),
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _gold.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: _gold, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Escáner ISBN',
                    style: GoogleFonts.cinzel(
                      color: _onDeep,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _gold, width: 1.5),
                color: Colors.black,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: MobileScanner(
                        controller: scannerController,
                        onDetect: _handleBarcode,
                        errorBuilder: (context, error) {
                          String message =
                              'No fue posible iniciar la cámara.\nPuedes escribir el ISBN manualmente.';

                          if (error.errorCode ==
                              MobileScannerErrorCode.permissionDenied) {
                            message = 'Permiso de cámara denegado.\nPuedes escribir el ISBN manualmente.';
                          } else if (error.errorCode ==
                              MobileScannerErrorCode.unsupported) {
                            message = 'La cámara no está disponible en este dispositivo.\nPuedes escribir el ISBN manualmente.';
                          }

                          return Container(
                            color: Colors.black,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              message,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 10,
                                height: 1.45,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: ScannerFramePainter()),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 8,
                      child: Text(
                        'Apunta la cámara al código de barras\ndel libro impreso',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 10,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: isbnController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: _textPrimary, fontSize: 11),
              decoration: InputDecoration(
                filled: true,
                fillColor: _surface,
                hintText: 'O escribe un ISBN',
                hintStyle: GoogleFonts.inter(
                  color: _textSecondary,
                  fontSize: 10,
                ),
                prefixIcon: Icon(Icons.numbers_rounded, color: _gold, size: 18),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _gold),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _gold, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _openBookFromIsbn(isbnController.text),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _gold,
                      side: BorderSide(color: _gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Buscar ISBN'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
