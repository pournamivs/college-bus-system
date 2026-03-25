import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/glass_morphic_card.dart';
import 'role_feature_catalog.dart';

class RoleFeaturePanel extends StatelessWidget {
  final AppRole role;
  final String title;

  const RoleFeaturePanel({
    super.key,
    required this.role,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final features = RoleFeatureCatalog.byRole[role] ?? const <RoleFeature>[];
    return GlassMorphicCard(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...features.take(4).map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    feature.enabled ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: feature.enabled ? AppColors.success : AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
