import 'package:flutter/material.dart';
import '../theme.dart';

class TelemetryColumn extends StatelessWidget {
  const TelemetryColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: RepairDecor.panel(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('REPAIRCONNECT SYSTEM BLUEPRINTS',
                  style: RepairText.microTeal(size: 8)),
              Text('SPEC STABLE V1.8',
                  style: RepairText.microMuted(size: 7.5)),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Text('SPEC-01  ',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: RepairColors.tealBright)),
              Expanded(
                child: Text('Telemetry & Verified Components',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              Icon(Icons.verified_outlined,
                  size: 14, color: RepairColors.tealBright),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
              'Interactive card specifications, verification states, and status indicator components. Built for surgical-grade trade calibration and medical facility operations.',
              style: TextStyle(fontSize: 9, color: RepairColors.muted)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
                color: RepairColors.tealDim,
                borderRadius: BorderRadius.circular(5)),
            child: const Text('SPEC-04   CARD DESIGNS MATRIX',
                style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: RepairColors.tealBright)),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < 560) {
                return Column(
                  children: [
                    _doctorCard(),
                    const SizedBox(height: 10),
                    _caseCard(),
                    const SizedBox(height: 10),
                    _shieldCard(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _doctorCard()),
                  const SizedBox(width: 10),
                  Expanded(child: _caseCard()),
                  const SizedBox(width: 10),
                  Expanded(child: _shieldCard()),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth < 420) {
                return Column(
                  children: [
                    _quoteCard(),
                    const SizedBox(height: 10),
                    _telemetryAlert(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _quoteCard()),
                  const SizedBox(width: 10),
                  Expanded(flex: 4, child: _telemetryAlert()),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Text('© 2025 RepairConnect Technologies Inc. All rights reserved.',
                  style: TextStyle(fontSize: 7, color: RepairColors.faint)),
              Text('CLASSIFICATION: SECURE TECHNICAL BLUEPRINT V1.8',
                  style: TextStyle(fontSize: 7, color: RepairColors.faint)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _doctorCard() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: const Color(0xFF0E1E33),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: RepairColors.borderSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                  radius: 13,
                  backgroundColor: RepairColors.tealDim,
                  child: Icon(Icons.person, size: 16, color: Colors.white)),
              const SizedBox(width: 7),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. Keith Sterling',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Text('Surgical Electronics Specialist',
                        style:
                            TextStyle(fontSize: 7.5, color: RepairColors.muted)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: RepairColors.tealDim,
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('VERIFIED',
                    style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: RepairColors.tealBright)),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Row(
            children: [
              Text('★★★★★  4.95',
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: RepairColors.star)),
              SizedBox(width: 6),
              Text('142 Jobs Completed',
                  style: TextStyle(fontSize: 7.5, color: RepairColors.faint)),
            ],
          ),
          const SizedBox(height: 7),
          const Text('CORE CREDENTIALS',
              style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  color: RepairColors.tealBright)),
          const Text(
              'Class-III Medical Device Certified • Calibrations & Mainstage telemetry • ISO 13485 Standards Audit compliant.',
              style: TextStyle(
                  fontSize: 8, height: 1.45, color: RepairColors.muted)),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: RepairColors.teal,
                borderRadius: BorderRadius.circular(6)),
            child: const Text('Book Now',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _caseCard() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(9)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CASE ID: IPC-9028-T',
                  style: TextStyle(fontSize: 7.5, color: Colors.black45)),
              Text('IN PROGRESS',
                  style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0E9DB2))),
            ],
          ),
          SizedBox(height: 6),
          Text('Anesthesia Vent Calibration',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
          Text('Oct 24, 2025 • 09:00 AM',
              style: TextStyle(fontSize: 8, color: Colors.black45)),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 12, color: Colors.black45),
              SizedBox(width: 4),
              Expanded(
                child: Text('St. Jude Research Wing\nBuilding B, Biosafety Lab 4 • Restricted Access',
                    style: TextStyle(fontSize: 7.5, color: Colors.black54)),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text('View Details →',
              style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0E9DB2))),
        ],
      ),
    );
  }

  Widget _shieldCard() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: const Color(0xFF0E1E33),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: RepairColors.borderSoft)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ELITE ENTERPRISE',
              style: RepairText.microMuted(size: 7.5)),
          const Text('Enterprise Shield',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 4),
          const Text('\$299',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
          const Text('/month',
              style: TextStyle(fontSize: 8, color: RepairColors.muted)),
          const SizedBox(height: 6),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✓  2-hour priority response SLA',
                  style: TextStyle(fontSize: 7.5, color: RepairColors.muted)),
              Text('✓  Certified medical-grade parts',
                  style: TextStyle(fontSize: 7.5, color: RepairColors.muted)),
              Text('✓  Unlimited emergency callouts',
                  style: TextStyle(fontSize: 7.5, color: RepairColors.muted)),
              Text('✓  Digital verification log vault',
                  style: TextStyle(fontSize: 7.5, color: RepairColors.muted)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: RepairColors.teal,
                borderRadius: BorderRadius.circular(6)),
            child: const Text('Deploy Shield',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _quoteCard() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(9)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('★★★★★',
                  style:
                      TextStyle(fontSize: 9, color: RepairColors.star)),
              Text('2 days ago',
                  style: TextStyle(fontSize: 7.5, color: Colors.black45)),
            ],
          ),
          SizedBox(height: 6),
          Text(
              '"The diagnostic and response workflow was surgical. Technician arrived within 45 minutes with pre-verified diagnostic telemetry. Unparalleled standard of service."',
              style: TextStyle(
                  fontSize: 8.5, height: 1.5, color: Colors.black87)),
          SizedBox(height: 8),
          Text('Dr. Aris Vance',
              style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          Text('Chief of Surgery, General Clinical Lab',
              style: TextStyle(fontSize: 7.5, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _telemetryAlert() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
          color: const Color(0xFF0E1E33),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: RepairColors.borderSoft)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('System Telemetry Alert',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              Icon(Icons.more_horiz,
                  size: 14, color: RepairColors.faint),
            ],
          ),
          SizedBox(height: 6),
          Text(
              'Calibration certificate for Asset IRC-8102 has been successfully issued and cryptographically locked.',
              style: TextStyle(
                  fontSize: 8, height: 1.45, color: RepairColors.muted)),
          SizedBox(height: 10),
          Text('10M AGO • SYSTEMS OPERATIONAL',
              style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  color: RepairColors.faint)),
        ],
      ),
    );
  }
}
