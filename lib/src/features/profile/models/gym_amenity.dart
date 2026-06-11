import 'package:flutter/material.dart';

class GymAmenity {
  const GymAmenity({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

const gymAmenitiesCatalog = <GymAmenity>[
  GymAmenity(key: 'personal_training', label: 'Personal Training', icon: Icons.person_pin_rounded),
  GymAmenity(key: 'gym_floor', label: 'Gym', icon: Icons.fitness_center_rounded),
  GymAmenity(key: 'spa', label: 'Spa', icon: Icons.spa_rounded),
  GymAmenity(key: 'zumba', label: 'Zumba', icon: Icons.music_note_rounded),
  GymAmenity(key: 'bhangra', label: 'Bhangra', icon: Icons.celebration_rounded),
  GymAmenity(key: 'yoga', label: 'Yoga', icon: Icons.self_improvement_rounded),
  GymAmenity(key: 'steam_bath', label: 'Steam bath', icon: Icons.cloud_rounded),
  GymAmenity(key: 'swimming_pool', label: 'Swimming pool', icon: Icons.pool_rounded),
  GymAmenity(key: 'pool', label: 'Pool', icon: Icons.water_rounded),
  GymAmenity(key: 'open_gym', label: 'Open gym section', icon: Icons.open_in_full_rounded),
  GymAmenity(key: 'cafe', label: 'Cafe', icon: Icons.local_cafe_rounded),
  GymAmenity(key: 'sauna', label: 'Sauna', icon: Icons.hot_tub_rounded),
  GymAmenity(key: 'crossfit', label: 'Crossfit', icon: Icons.sports_martial_arts_rounded),
];

GymAmenity? gymAmenityByKey(String key) {
  for (final item in gymAmenitiesCatalog) {
    if (item.key == key) return item;
  }
  return null;
}

List<GymAmenity> gymAmenitiesFromKeys(List<String> keys) {
  return keys.map(gymAmenityByKey).whereType<GymAmenity>().toList();
}
