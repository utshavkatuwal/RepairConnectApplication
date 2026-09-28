import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/rc_widgets.dart';
import '../../../widgets/brand_column.dart';
import '../../../widgets/components_column.dart';
import '../../../widgets/telemetry_column.dart';
import '../../../theme.dart';

/// Approved Figma/Stitch board preserved 1:1 as visual source of truth.
/// Intentionally kept in its dark blueprint presentation in both modes.
class DesignSystemScreen extends StatelessWidget {
  const DesignSystemScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RepairColors.pageBg,
      appBar: const RcBackAppBar(
          title: 'Approved design system',
          fallback: AppRoutes.landing),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 1180;
          if (wide) {
            return const SingleChildScrollView(
              padding: EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 10, child: BrandColumn()),
                  SizedBox(width: 14),
                  Expanded(flex: 11, child: ComponentsColumn()),
                  SizedBox(width: 14),
                  Expanded(flex: 11, child: TelemetryColumn()),
                ],
              ),
            );
          }
          return const SingleChildScrollView(
            padding: EdgeInsets.all(14),
            child: Column(
              children: [
                BrandColumn(),
                SizedBox(height: 14),
                ComponentsColumn(),
                SizedBox(height: 14),
                TelemetryColumn(),
              ],
            ),
          );
        },
      ),
    );
  }
}
