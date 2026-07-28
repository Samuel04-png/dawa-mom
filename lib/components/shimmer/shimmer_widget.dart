import '/localization/dawa_localized_material.dart';

import '/design_system/dawa_components.dart';
import '/design_system/dawa_design_tokens.dart';

export 'shimmer_model.dart';

/// Backwards-compatible loader for older FlutterFlow screens.
///
/// New screens use [DawaLoadingSkeleton] or [DawaPageSkeleton] directly.
class ShimmerWidget extends StatelessWidget {
  const ShimmerWidget({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(DawaSpacing.md),
        child: DawaLoadingSkeleton(
          label: 'Loading health information',
          lines: 3,
        ),
      );
}
