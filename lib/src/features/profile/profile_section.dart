import 'package:flutter/material.dart';

enum ProfileSection {
  dietPlan,
  exercises,
  gymTiming,
  feeStructure,
  exclusiveOffers;

  static ProfileSection? fromQuery(String? value) {
    switch (value) {
      case 'diet':
        return ProfileSection.dietPlan;
      case 'exercises':
        return ProfileSection.exercises;
      case 'timing':
        return ProfileSection.gymTiming;
      case 'fees':
        return ProfileSection.feeStructure;
      case 'offers':
        return ProfileSection.exclusiveOffers;
      default:
        return null;
    }
  }

  String get routeKey {
    switch (this) {
      case ProfileSection.dietPlan:
        return 'diet';
      case ProfileSection.exercises:
        return 'exercises';
      case ProfileSection.gymTiming:
        return 'timing';
      case ProfileSection.feeStructure:
        return 'fees';
      case ProfileSection.exclusiveOffers:
        return 'offers';
    }
  }

  String get title {
    switch (this) {
      case ProfileSection.dietPlan:
        return 'Diet Plan';
      case ProfileSection.exercises:
        return 'Exercises';
      case ProfileSection.gymTiming:
        return 'Gym Timing';
      case ProfileSection.feeStructure:
        return 'Fee Structure';
      case ProfileSection.exclusiveOffers:
        return 'Exclusive Offers';
    }
  }

  String get subtitle {
    switch (this) {
      case ProfileSection.dietPlan:
        return 'Lose, gain & healthy meal plans';
      case ProfileSection.exercises:
        return 'Images, sets, reps & muscle groups';
      case ProfileSection.gymTiming:
        return 'Open hours & schedules';
      case ProfileSection.feeStructure:
        return 'Membership plans & pricing';
      case ProfileSection.exclusiveOffers:
        return 'Promotions & deals';
    }
  }

  IconData get icon {
    switch (this) {
      case ProfileSection.dietPlan:
        return Icons.restaurant_menu_rounded;
      case ProfileSection.exercises:
        return Icons.fitness_center_rounded;
      case ProfileSection.gymTiming:
        return Icons.schedule_rounded;
      case ProfileSection.feeStructure:
        return Icons.payments_rounded;
      case ProfileSection.exclusiveOffers:
        return Icons.local_offer_rounded;
    }
  }
}
