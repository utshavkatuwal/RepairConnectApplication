import 'package:flutter/material.dart';
import '../theme.dart';
import 'brand_column.dart';

class ComponentsColumn extends StatelessWidget {
  const ComponentsColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: RepairColors.tealDim,
                        borderRadius: BorderRadius.circular(4)),
                    child: const Text('01',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: RepairColors.tealBright)),
                  ),
                  const SizedBox(width: 7),
                  const Text('BUTTON SYSTEM & STATE MATRIX',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.white)),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                  'Standard state behaviors for core user flows. Built with precise 6px corner radii, strict spacing parameters, and high-visibility contrast ratios.',
                  style: TextStyle(fontSize: 9, color: RepairColors.muted)),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 520;
                  Widget cell(Widget w) => SizedBox(
                      width:
                          narrow ? (c.maxWidth - 10) / 2 : (c.maxWidth - 30) / 4,
                      child: w);
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      cell(_btnGroup('PRIMARY VARIANT', [
                        _btn('Confirm Dispatch', RepairColors.teal,
                            Colors.white, false, 'Default'),
                        _btn('Confirm Dispatch', RepairColors.tealBright,
                            const Color(0xFF06222A), false, 'Hover'),
                        _btn('Confirm Dispatch', const Color(0xFF173F4D),
                            Colors.white54, false, 'Disabled'),
                      ])),
                      cell(_btnGroup('SECONDARY (OUTLINE)', [
                        _btn('Schedule Technician', Colors.transparent,
                            RepairColors.tealBright, true, 'Default'),
                        _btn('Schedule Technician', const Color(0xFF0E2A36),
                            RepairColors.tealBright, true, 'Hover'),
                        _btn('Schedule Technician', Colors.transparent,
                            Colors.white24, true, 'Disabled'),
                      ])),
                      cell(_btnGroup('GHOST & DESTRUCTIVE', [
                        _btn('Cancel Request', Colors.transparent,
                            RepairColors.muted, false, 'Ghost Default'),
                        _btn('Cancel Request', const Color(0xFF16293F),
                            RepairColors.body, false, 'Ghost Hover'),
                        _btn('Revoke Certification', RepairColors.red,
                            Colors.white, false, 'Destructive Default'),
                      ])),
                      cell(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SIZES & INTEGRATIONS',
                              style: RepairText.microTeal(size: 8)),
                          const SizedBox(height: 8),
                          const Text('Primary Small (32px)',
                              style: TextStyle(
                                  fontSize: 7.5, color: RepairColors.faint)),
                          _smallBtn('Edit Job'),
                          const SizedBox(height: 8),
                          const Text('Primary Large (48px)',
                              style: TextStyle(
                                  fontSize: 7.5, color: RepairColors.faint)),
                          _btn('Submit Verification Audit', RepairColors.teal,
                              Colors.white, false, null),
                          const SizedBox(height: 8),
                          const Text('Button with leading icon',
                              style: TextStyle(
                                  fontSize: 7.5, color: RepairColors.faint)),
                          _btnWithIcon(),
                        ],
                      )),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('INTERFACE & SYSTEM SPECIFICATION',
                  style: RepairText.microTeal(size: 8.5)),
              Row(
                children: [
                  const Expanded(
                    child: Text('RepairConnect™ UI Components',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: RepairColors.teal)),
                    child: const Text('SYSTEM VERIFIED',
                        style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w700,
                            color: RepairColors.tealBright)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                  'Interactive state standards, input fields, and design token implementations. Strictly constructed for extreme legibility, high-stress trade verified workflows, and surgical-grade alignment.',
                  style: TextStyle(fontSize: 9, color: RepairColors.muted)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel(
                  code: '02', title: 'FORM FIELDS & CONTROLS SCHEMA'),
              const SizedBox(height: 4),
              const Text(
                  'Detailed validation states, selections, and helper typography across both standard light-on-dark surface environments and legacy print structures.',
                  style: TextStyle(fontSize: 9, color: RepairColors.muted)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  if (c.maxWidth < 480) {
                    return Column(
                      children: [
                        _darkForm(),
                        const SizedBox(height: 12),
                        _lightForm(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _darkForm()),
                      const SizedBox(width: 12),
                      Expanded(child: _lightForm()),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            Text('© 2025 RepairConnect Technologies Inc. All rights reserved.',
                style: TextStyle(fontSize: 7, color: RepairColors.faint)),
            Text('CLASSIFICATION: SECURE TECHNICAL COMPONENT BOOK V1.4',
                style: TextStyle(fontSize: 7, color: RepairColors.faint)),
          ],
        ),
      ],
    );
  }

  Widget _btnGroup(String title, List<Widget> btns) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: RepairText.microTeal(size: 8)),
        const SizedBox(height: 8),
        ...btns.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8), child: b)),
      ],
    );
  }

  Widget _btn(String label, Color bg, Color fg, bool outline, String? state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state != null)
          Text(state,
              style:
                  const TextStyle(fontSize: 7.5, color: RepairColors.faint)),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: outline
                    ? (fg.withValues(alpha: 0.5))
                    : Colors.transparent),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600, color: fg)),
        ),
      ],
    );
  }

  Widget _smallBtn(String label) {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: const Color(0xFF0E2A36),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: RepairColors.teal.withValues(alpha: 0.5))),
      child: Text(label,
          style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
              color: RepairColors.tealBright)),
    );
  }

  Widget _btnWithIcon() {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: RepairColors.teal,
          borderRadius: BorderRadius.circular(6)),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: Colors.white),
          SizedBox(width: 5),
          Flexible(
            child: Text('Verify Technician Credentials',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _darkForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF081222),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: RepairColors.borderSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DARK SYSTEM SURFACES',
              style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const Text('Optimized for low-light mobile & trade dashboard monitoring consoles.',
              style: TextStyle(fontSize: 7.5, color: RepairColors.faint)),
          const SizedBox(height: 10),
          _darkLabel('TECHNICIAN UNIQUE ID *'),
          _darkField('e.g. RC-9028-1194', false, false),
          const Text('Must match system registration paper spec',
              style: TextStyle(fontSize: 7, color: RepairColors.faint)),
          const SizedBox(height: 8),
          _darkLabel('OFFICIAL BUSINESS EMAIL'),
          _darkField('dispatch@connect-repair.co', true, false),
          const SizedBox(height: 8),
          _darkLabel('POSTAL CODE'),
          _darkField('INVALID_ZIP', false, true),
          const Text('Please enter a valid verified trade dispatch zip code.',
              style: TextStyle(fontSize: 7, color: RepairColors.red)),
          const SizedBox(height: 8),
          _darkLabel('SYSTEM CORE CLOCK'),
          _darkField('Locked UTC/GMT+5 Only', false, false, locked: true),
          const SizedBox(height: 8),
          _darkLabel('SEARCH HARDWARE REQUISITIONS'),
          _darkField('🔍  Surgical valve clamps', false, false),
          const SizedBox(height: 8),
          _darkLabel('ANAMNESIS & DAMAGE REPORT DESCRIPTION'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: RepairColors.fieldBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: RepairColors.borderSoft)),
            child: const Text(
                'Mechanical calibration fault on secondary manifold line. Pressure exceeded nominal standards by 14%.',
                style: TextStyle(fontSize: 8.5, color: RepairColors.body)),
          ),
          const SizedBox(height: 8),
          _darkLabel('SELECT DISPATCH PRIORITY LEVEL'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
                color: RepairColors.fieldBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: RepairColors.borderSoft)),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 7, color: RepairColors.copper),
                SizedBox(width: 6),
                Expanded(
                  child: Text('CRITICAL EMERGENCY (LEVEL 1)',
                      style:
                          TextStyle(fontSize: 7.5, color: RepairColors.body)),
                ),
                Icon(Icons.keyboard_arrow_down,
                    size: 14, color: RepairColors.faint),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: Text('CHECKBOXES', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: RepairColors.tealBright))),
              Expanded(child: Text('RADIO CHIPS', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: RepairColors.tealBright))),
              Expanded(child: Text('POWER TOGGLES', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: RepairColors.tealBright))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('☐  Standard',
                      style: TextStyle(fontSize: 8, color: RepairColors.muted)),
                  Text('☑  Verified Active',
                      style: TextStyle(fontSize: 8, color: RepairColors.muted)),
                ],
              )),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('○  Manual Override',
                      style: TextStyle(fontSize: 8, color: RepairColors.muted)),
                  Text('◉  AI Autonomic',
                      style: TextStyle(fontSize: 8, color: RepairColors.muted)),
                ],
              )),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FakeToggle(on: false, label: 'Off'),
                  const SizedBox(height: 3),
                  _FakeToggle(on: true, label: 'Online'),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lightForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LIGHT SYSTEM SURFACES',
              style: TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w800, color: Colors.black87)),
          const Text('Specified for legal invoices, paper printouts, and client-facing quotes.',
              style: TextStyle(fontSize: 7.5, color: Colors.black45)),
          const SizedBox(height: 10),
          _lightLabel('TECHNICIAN UNIQUE ID *'),
          _lightField('e.g. RC-9028-1194'),
          const Text('Must match system registration paper spec',
              style: TextStyle(fontSize: 7, color: Colors.black45)),
          const SizedBox(height: 8),
          _lightLabel('OFFICIAL BUSINESS EMAIL'),
          _lightField('dispatch@connect-repair.co', active: true),
          const SizedBox(height: 8),
          _lightLabel('POSTAL CODE'),
          _lightField('INVALID_ZIP', error: true),
          const Text('Please enter a valid verified trade dispatch zip code.',
              style: TextStyle(fontSize: 7, color: RepairColors.red)),
          const SizedBox(height: 8),
          _lightLabel('SYSTEM CORE CLOCK'),
          _lightField('Locked UTC/GMT+5 Only', locked: true),
          const SizedBox(height: 8),
          _lightLabel('SEARCH HARDWARE REQUISITIONS'),
          _lightField('🔍  Surgical valve clamps'),
          const SizedBox(height: 8),
          _lightLabel('ANAMNESIS & DAMAGE REPORT DESCRIPTION'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Text(
                'Mechanical calibration fault on secondary manifold line. Pressure exceeded nominal standards by 14%.',
                style: TextStyle(fontSize: 8.5, color: Colors.black87)),
          ),
          const SizedBox(height: 8),
          _lightLabel('SELECT DISPATCH PRIORITY LEVEL'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 7, color: RepairColors.copper),
                SizedBox(width: 6),
                Expanded(
                  child: Text('CRITICAL EMERGENCY (LEVEL 1)',
                      style:
                          TextStyle(fontSize: 7.5, color: Colors.black87)),
                ),
                Icon(Icons.keyboard_arrow_down,
                    size: 14, color: Colors.black38),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: Text('CHECKBOXES', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: Color(0xFF0E9DB2)))),
              Expanded(child: Text('RADIO CHIPS', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: Color(0xFF0E9DB2)))),
              Expanded(child: Text('POWER TOGGLES', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700, color: Color(0xFF0E9DB2)))),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('☐  Standard',
                      style: TextStyle(fontSize: 8, color: Colors.black54)),
                  Text('☑  Verified Active',
                      style: TextStyle(fontSize: 8, color: Colors.black54)),
                ],
              )),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('○  Manual Override',
                      style: TextStyle(fontSize: 8, color: Colors.black54)),
                  Text('◉  AI Autonomic',
                      style: TextStyle(fontSize: 8, color: Colors.black54)),
                ],
              )),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FakeToggle(on: false, label: 'Off', dark: false),
                  SizedBox(height: 3),
                  _FakeToggle(on: true, label: 'Online', dark: false),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _darkLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t,
            style:
                const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: RepairColors.muted)),
      );
  Widget _lightLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(t,
            style: const TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w700,
                color: Colors.black54)),
      );

  Widget _darkField(String hint, bool active, bool error,
      {bool locked = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: RepairColors.fieldBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: error
                ? RepairColors.red
                : active
                    ? RepairColors.teal
                    : RepairColors.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(hint,
                  style: TextStyle(
                      fontSize: 8.5,
                      color: locked
                          ? RepairColors.faint
                          : active
                              ? Colors.white
                              : error
                                  ? RepairColors.red
                                  : RepairColors.faint))),
          if (error)
            const Icon(Icons.error_outline, size: 12, color: RepairColors.red),
          if (active)
            const Icon(Icons.keyboard_arrow_down,
                size: 12, color: RepairColors.tealBright),
        ],
      ),
    );
  }

  Widget _lightField(String hint,
      {bool active = false, bool error = false, bool locked = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: locked ? const Color(0xFFF1F5F9) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: error
                ? RepairColors.red
                : active
                    ? const Color(0xFF0E9DB2)
                    : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(hint,
                  style: TextStyle(
                      fontSize: 8.5,
                      color: error
                          ? RepairColors.red
                          : locked
                              ? Colors.black38
                              : Colors.black87))),
          if (error)
            const Icon(Icons.error_outline, size: 12, color: RepairColors.red),
          if (active)
            const Icon(Icons.keyboard_arrow_down,
                size: 12, color: Color(0xFF0E9DB2)),
        ],
      ),
    );
  }
}

class _FakeToggle extends StatelessWidget {
  final bool on;
  final String label;
  final bool dark;
  const _FakeToggle({required this.on, required this.label, this.dark = true});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 11,
          decoration: BoxDecoration(
            color: on
                ? (dark ? RepairColors.teal : const Color(0xFF0E9DB2))
                : (dark ? const Color(0xFF1A2F4A) : const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          padding: const EdgeInsets.all(1.5),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 7,
                  color: dark ? RepairColors.muted : Colors.black54)),
        ),
      ],
    );
  }
}
