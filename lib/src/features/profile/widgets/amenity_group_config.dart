import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/features/profile/models/gym_amenity.dart';

class AmenityGroupConfig {
  const AmenityGroupConfig({
    required this.title,
    required this.icon,
    required this.keys,
  });

  final String title;
  final IconData icon;
  final List<String> keys;
}

const amenityGroupConfigs = <AmenityGroupConfig>[
  AmenityGroupConfig(
    title: 'Training & floor',
    icon: Icons.fitness_center_rounded,
    keys: ['personal_training', 'gym_floor', 'open_gym', 'crossfit'],
  ),
  AmenityGroupConfig(
    title: 'Classes & dance',
    icon: Icons.music_note_rounded,
    keys: ['zumba', 'bhangra', 'yoga'],
  ),
  AmenityGroupConfig(
    title: 'Wellness & water',
    icon: Icons.spa_rounded,
    keys: ['spa', 'steam_bath', 'sauna', 'swimming_pool', 'pool'],
  ),
  AmenityGroupConfig(
    title: 'Extras',
    icon: Icons.local_cafe_rounded,
    keys: ['cafe'],
  ),
];

List<GymAmenity> amenitiesForGroup(AmenityGroupConfig group) {
  return group.keys.map(gymAmenityByKey).whereType<GymAmenity>().toList();
}

List<AmenityGroupConfig> visibleAmenityGroups(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return amenityGroupConfigs;

  return [
    for (final group in amenityGroupConfigs)
      AmenityGroupConfig(
        title: group.title,
        icon: group.icon,
        keys: [
          for (final amenity in amenitiesForGroup(group))
            if (amenity.label.toLowerCase().contains(q) ||
                amenity.key.toLowerCase().contains(q))
              amenity.key,
        ],
      ),
  ].where((group) => group.keys.isNotEmpty).toList();
}
