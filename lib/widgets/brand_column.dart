import 'package:flutter/material.dart';
import '../theme.dart';

class SectionLabel extends StatelessWidget {
  final String code;
  final String title;
  const SectionLabel({super.key, required this.code, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: RepairColors.tealDim,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(code,
              style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: RepairColors.tealBright)),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: RepairColors.heading)),
        ),
      ],
    );
  }
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const Panel({super.key, required this.child, this.padding});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: RepairDecor.panel(),
      child: child,
    );
  }
}

class BrandColumn extends StatelessWidget {
  const BrandColumn({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PREMIUM BRAND GUIDELINES',
                  style: RepairText.microTeal(size: 8.5)),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                              text: 'Repair',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5)),
                          TextSpan(
                              text: 'Connect™',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: RepairColors.tealBright,
                                  letterSpacing: -0.5)),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('VERSION 1.0 MATTE SPEC',
                          style: RepairText.microMuted(size: 7.5)),
                      Text('RELEASE DATE: Q1 2025',
                          style: RepairText.microMuted(size: 7.5)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: RepairColors.teal.withValues(alpha: 0.6))),
                        child: const Text('CURRENT ACTIVE',
                            style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                color: RepairColors.tealBright)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'A comprehensive, premium brand identity system built for a medical-grade, highly verified technical and home repair marketplace. Anchored on deep-navy foundation tones, surgical-teal precision accents, and absolute structural alignment.',
                style: RepairText.bodyTiny,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _logoSymbolConcept()),
            const SizedBox(width: 12),
            Expanded(child: _wordmarkSystem()),
          ],
        ),
        const SizedBox(height: 12),
        _logoSystem(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _palette()),
            const SizedBox(width: 12),
            Expanded(child: _typeHierarchy()),
          ],
        ),
        const SizedBox(height: 12),
        _patternCard(),
      ],
    );
  }

  Widget _logoSymbolConcept() {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(code: '01', title: 'LOGO SYMBOL CONCEPT'),
          const SizedBox(height: 8),
          const Text(
              'Our abstract symbol represents interlocking connection geometry (customer ↔ certified professional). It subtly constructs an ‘R’ and ‘C’ naturally through flow and solution-oriented node alignment.',
              style: TextStyle(fontSize: 9, height: 1.5, color: RepairColors.muted)),
          const SizedBox(height: 10),
          Container(
            height: 118,
            decoration: RepairDecor.inner(),
            child: const Center(
              child: Icon(Icons.hub_outlined,
                  size: 44, color: RepairColors.tealBright),
            ),
          ),
          const Center(
            child: Text('STANDALONE GLYPH • 96PX GRID VIEW',
                style: TextStyle(
                    fontSize: 7, color: RepairColors.faint, letterSpacing: 0.6)),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(
                  child: Text('Interlocking Core\nDirect customer to expert node linkage showing premium precision.',
                      style: TextStyle(
                          fontSize: 8.5,
                          height: 1.45,
                          color: RepairColors.muted))),
              SizedBox(width: 8),
              Expanded(
                  child: Text('Subtle R & C\nFormed organically by the intersection points of the geometric lines.',
                      style: TextStyle(
                          fontSize: 8.5,
                          height: 1.45,
                          color: RepairColors.muted))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wordmarkSystem() {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(code: '02', title: 'THE WORDMARK SYSTEM'),
          const SizedBox(height: 8),
          const Text(
              'Constructed using high-end geometric sans-serif styling. Designed with a custom letter-spacing layout for high contrast and executive fintech authority.',
              style: TextStyle(fontSize: 9, height: 1.5, color: RepairColors.muted)),
          const SizedBox(height: 10),
          Container(
            height: 118,
            alignment: Alignment.center,
            decoration: RepairDecor.inner(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text.rich(
                  TextSpan(
                    children: const [
                      TextSpan(
                          text: 'Repair ',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w300,
                              color: Colors.white)),
                      TextSpan(
                          text: 'Connect',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: RepairColors.tealBright)),
                    ],
                  ),
                ),
                Text('OPTICAL TRACKING / Semibold + Light Balance',
                    style: RepairText.microMuted(size: 7)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 8.5, height: 1.5, color: RepairColors.muted),
              children: [
                TextSpan(
                    text: 'REPAIR  ',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: RepairColors.copper)),
                TextSpan(
                    text:
                        '300 Light Weight / Suggests surgical cleanliness, ease, and resolution.\n'),
                TextSpan(
                    text: 'CONNECT  ',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: RepairColors.tealBright)),
                TextSpan(
                    text:
                        '600 Semibold Weight / Represents the verified, structural linkage of trust.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoSystem() {
    Widget tile(String label, bool light, Widget center) {
      return Container(
        height: 78,
        decoration: BoxDecoration(
          color: light ? Colors.white : const Color(0xFF060D1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: RepairColors.borderSoft),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            center,
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w600,
                    color: light ? Colors.black54 : RepairColors.faint)),
          ],
        ),
      );
    }

    TextStyle darkWord = const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white);
    TextStyle lightWord = const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(code: '03', title: 'THE LOGO SYSTEM'),
          const SizedBox(height: 6),
          const Text(
              'Six responsive configurations designed to satisfy multiple technical touchpoints, media backgrounds, and sizes down to 16px.',
              style: TextStyle(fontSize: 9, color: RepairColors.muted)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              tile(
                  '1. PRIMARY HORIZONTAL',
                  false,
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '◈ Repair ', style: darkWord),
                    const TextSpan(
                        text: 'Connect',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: RepairColors.tealBright)),
                  ]))),
              tile(
                  '2. STANDALONE APP ICON',
                  false,
                  Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: RepairColors.teal)),
                      child: const Icon(Icons.handyman_outlined,
                          size: 18, color: RepairColors.tealBright))),
              tile(
                  '3. COMPACT CONDENSED',
                  false,
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '◈ Repair ', style: darkWord.copyWith(fontSize: 9)),
                    const TextSpan(
                        text: 'Connect',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: RepairColors.tealBright)),
                  ]))),
              tile(
                  '4. MONOCHROME BLACK',
                  true,
                  Text('◈ Repair Connect', style: lightWord)),
              tile(
                  '5. LIGHT BACKGROUND (ACTIVE)',
                  true,
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '◈ Repair ', style: lightWord),
                    const TextSpan(
                        text: 'Connect',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0E9DB2))),
                  ]))),
              tile(
                  '6. DARK BACKGROUND',
                  false,
                  Text.rich(TextSpan(children: [
                    const TextSpan(
                        text: '◈ Repair ',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: Colors.white)),
                    TextSpan(text: 'Connect', style: darkWord),
                  ]))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _palette() {
    Widget swatch(String name, String hex, String usage, Color c, Color text) {
      return Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
            color: c, borderRadius: BorderRadius.circular(7)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: text)),
            Text(hex,
                style: TextStyle(
                    fontSize: 7.5, color: text.withValues(alpha: 0.75))),
            Text(usage,
                style: TextStyle(
                    fontSize: 7.5, height: 1.35, color: text.withValues(alpha: 0.85))),
          ],
        ),
      );
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(code: '04', title: 'VERIFIED PALETTE'),
          const SizedBox(height: 6),
          const Text(
              'Our primary colors invoke fintech rigor, hospital cleanliness, and professional trade trust.',
              style: TextStyle(fontSize: 9, color: RepairColors.muted)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: swatch('Navy Dark', '#0A1A2E\nRGB 10, 26, 46',
                      'Brand core background foundation.', const Color(0xFF060D1A), Colors.white)),
              const SizedBox(width: 8),
              Expanded(
                  child: swatch(
                      'Surgical Teal',
                      '#2AB6CE\nRGB 42, 182, 206',
                      'Primary brand color, representing precise connectivity.',
                      RepairColors.teal,
                      Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: swatch('Warm Copper', '#E8930C\nRGB 232, 147, 12',
                      'Secondary accent highlighting safety and guarantee.', RepairColors.copper, Colors.white)),
              const SizedBox(width: 8),
              Expanded(
                  child: swatch('Off-White', '#F1F5F9\nRGB 241, 245, 249',
                      'Clean surface layout backgrounds.', Colors.white, Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeHierarchy() {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(code: '05', title: 'TYPE HIERARCHY SPECIMEN'),
          const SizedBox(height: 6),
          const Text(
              'We use Outfit for premium, balanced geometric displays & Geist for monospace / technical body parameters.',
              style: TextStyle(fontSize: 9, color: RepairColors.muted)),
          const SizedBox(height: 10),
          Text('DISPLAY HEADING OUTFIT 36PX, 600',
              style: RepairText.microMuted(size: 7)),
          const Text('The Premium Standard of Repair',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2)),
          const SizedBox(height: 8),
          Text('H2 HEADING OUTFIT 20PX, 600',
              style: RepairText.microMuted(size: 7)),
          const Text('Verified On-site Technicians 24/7',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 6),
          const Text('H3 HEADING OUTFIT 14PX, 600',
              style: TextStyle(
                  fontSize: 7, color: RepairColors.faint, letterSpacing: 0.5)),
          const Text('Verified On-site Technicians 24/7',
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
          const Text('H4 HEADING OUTFIT 12PX, 600',
              style: TextStyle(
                  fontSize: 7, color: RepairColors.faint, letterSpacing: 0.5)),
          const Text('Verified On-site Technicians 24/7',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 6),
          const Text(
              'BODY TEXT GEIST 12PX, 400\nEvery specialist on our platform undergoes a meticulous background check and structural credentials audit. We prioritize clean technical delivery.',
              style: TextStyle(fontSize: 8.5, height: 1.5, color: RepairColors.muted)),
          const SizedBox(height: 6),
          const Text(
              'SMALL TEXT GEIST 10PX, 400\nEvery specialist on our platform undergoes a meticulous background check and structural credentials audit. We prioritize clean technical delivery.',
              style: TextStyle(fontSize: 8, height: 1.5, color: RepairColors.muted)),
          const SizedBox(height: 6),
          const Text(
              'CAPTION GEIST 8PX, 400\nEVERY SPECIALIST ON OUR PLATFORM UNDERGOES A METICULOUS BACKGROUND CHECK AND STRUCTURAL CREDENTIALS AUDIT. WE PRIORITIZE CLEAN TECHNICAL DELIVERY.',
              style: TextStyle(
                  fontSize: 7, height: 1.5, color: RepairColors.faint)),
        ],
      ),
    );
  }

  Widget _patternCard() {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
              code: '06',
              title: 'SUBTLE CONNECTION PATTERN & APPLIED BRAND CARD'),
          const SizedBox(height: 6),
          const Text(
              'Visualisation of the geometric node network texture, styled for digital backdrops alongside our high-end trust card mock-up.',
              style: TextStyle(fontSize: 9, color: RepairColors.muted)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  height: 120,
                  decoration: RepairDecor.inner(),
                  child: CustomPaint(painter: _DotGridPainter()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: Container(
                  height: 120,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E6B78), Color(0xFF0E3A44)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: RepairColors.teal),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Verified Partner',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ),
                          Icon(Icons.verified,
                              size: 14, color: Colors.white70),
                        ],
                      ),
                      Spacer(),
                      Text('VERIFICATION ID',
                          style: TextStyle(
                              fontSize: 7,
                              letterSpacing: 0.8,
                              color: Colors.white70)),
                      Text('RC - 9028 1194 TECH',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF1B3350);
    for (double y = 12; y < size.height; y += 22) {
      for (double x = 12; x < size.width; x += 22) {
        canvas.drawCircle(Offset(x, y), 1.2, p);
      }
    }
    final lp = Paint()
      ..color = const Color(0xFF1B3350).withValues(alpha: 0.5)
      ..strokeWidth = 0.6;
    canvas.drawLine(const Offset(12, 12), Offset(size.width - 12, 12), lp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
