import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';

class HomeQuoteSection extends StatefulWidget {
  const HomeQuoteSection({
    super.key,
    required this.quotes,
  });

  final List<Map<String, String>> quotes;

  @override
  State<HomeQuoteSection> createState() => _HomeQuoteSectionState();
}

class _HomeQuoteSectionState extends State<HomeQuoteSection> {
  final Random random = Random();
  Timer? quoteTimer;

  bool showQuoteShare = false;
  String? quoteSharedOn;
  int currentQuote = 0;

  List<Map<String, String>> get quotes => widget.quotes;

  Color get _deepSurface => AppColors.deepOf(context);
  Color get _deepAltSurface => AppColors.deepAltOf(context);
  Color get _gold => AppColors.goldOf(context);
  Color get _onDeep => AppColors.isDark(context)
      ? AppColors.darkTextPrimary
      : AppColors.background;
  Color get _goldInk => AppColors.deep;

  @override
  void initState() {
    super.initState();

    quoteTimer = Timer.periodic(
      const Duration(seconds: 40),
      (_) => _changeQuote(),
    );
  }

  @override
  void dispose() {
    quoteTimer?.cancel();
    super.dispose();
  }

  void _changeQuote() {
    if (!mounted || quotes.length < 2) {
      return;
    }

    var next = currentQuote;

    while (next == currentQuote) {
      next = random.nextInt(quotes.length);
    }

    setState(() {
      currentQuote = next;
      showQuoteShare = false;
      quoteSharedOn = null;
    });
  }

  Widget _buildQuote() {
    final quote = quotes[currentQuote];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: Container(
        key: ValueKey(currentQuote),
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_deepSurface, const Color(0xFF63252D), _deepAltSurface],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: _deepSurface.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 8,
              top: -24,
              child: Text(
                '“',
                style: GoogleFonts.merriweather(
                  fontSize: 84,
                  height: 1,
                  color: _gold.withValues(alpha: 0.09),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: -12,
              child: Transform.rotate(
                angle: -0.2,
                child: Icon(
                  Icons.edit_note_rounded,
                  size: 54,
                  color: _gold.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _gold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'CITA DEL DÍA',
                          style: GoogleFonts.cinzel(
                            color: _gold,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            showQuoteShare = !showQuoteShare;
                            quoteSharedOn = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _gold.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            showQuoteShare ? 'Cerrar' : 'Compartir',
                            style: GoogleFonts.inter(
                              color: _gold,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '“${quote['text']}”',
                    style: GoogleFonts.merriweather(
                      color: const Color(0xFFF7EFE2),
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '— ${quote['author']}'
                      '${quote['work']!.isEmpty ? '' : ', ${quote['work']}'}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        color: _gold,
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (showQuoteShare)
              Positioned.fill(
                child: GestureDetector(
                  onTap: quoteSharedOn == null
                      ? () {
                          setState(() {
                            showQuoteShare = false;
                            quoteSharedOn = null;
                          });
                        }
                      : null,
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: const Color(0x8A2B1713),
                      alignment: Alignment.center,
                      child: quoteSharedOn == null
                          ? _buildShareOptions()
                          : _buildSharedConfirmation(quoteSharedOn!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOptions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'COMPARTIR',
          style: GoogleFonts.cinzel(
            color: _onDeep,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _shareButton(
              icon: Icons.chat_bubble_rounded,
              platform: 'WhatsApp',
              backgroundColor: const Color(0xFF25D366),
            ),
            const SizedBox(width: 18),
            _shareButton(
              icon: Icons.camera_alt_rounded,
              platform: 'Instagram',
              backgroundColor: const Color(0xFFE95B70),
            ),
            const SizedBox(width: 18),
            _shareButton(
              icon: Icons.facebook_rounded,
              platform: 'Facebook',
              backgroundColor: const Color(0xFF1877F2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _shareButton({
    required IconData icon,
    required String platform,
    required Color backgroundColor,
  }) {
    return InkWell(
      onTap: () => _shareQuote(platform),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }

  Widget _buildSharedConfirmation(String platform) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _gold,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.check_rounded, color: _goldInk, size: 23),
        ),
        const SizedBox(height: 7),
        Text(
          'COMPARTIDO',
          style: GoogleFonts.cinzel(
            color: _onDeep,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'en $platform',
          style: GoogleFonts.inter(
            color: _onDeep.withValues(alpha: 0.82),
            fontSize: 7,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _shareQuote(String platform) async {
    final quote = quotes[currentQuote];

    final text =
        '“${quote['text']}”\n'
        '— ${quote['author']}'
        '${quote['work']!.isEmpty ? '' : ' · ${quote['work']}'}\n\n'
        '📚 Compartido desde Capítulo 0';

    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) {
      return;
    }

    setState(() {
      showQuoteShare = true;
      quoteSharedOn = platform;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1350));

    if (!mounted) {
      return;
    }

    setState(() {
      showQuoteShare = false;
      quoteSharedOn = null;
    });
  }



  @override
  Widget build(BuildContext context) => _buildQuote();
}
