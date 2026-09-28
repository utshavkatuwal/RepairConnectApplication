import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/features/customer/presentation/customer_extra_screens.dart';
import 'package:repairconnect/shared/models/models.dart';

const _techs = [
  Technician(
      id: 't1',
      userId: 'u1',
      name: 'Zed',
      specialty: 'HVAC',
      rating: 4.9,
      jobsCompleted: 10,
      verified: false,
      available: true),
  Technician(
      id: 't2',
      userId: 'u2',
      name: 'Amy',
      specialty: 'HVAC Pro',
      rating: 4.6,
      jobsCompleted: 200,
      verified: true,
      available: false),
  Technician(
      id: 't3',
      userId: 'u3',
      name: 'Bob',
      specialty: 'Electrical',
      rating: 4.95,
      jobsCompleted: 50,
      verified: true,
      available: true),
];

void main() {
  test('verified first, then rating', () {
    final out = filterTechnicians(_techs);
    expect(out.map((t) => t.id).toList(), ['t3', 't2', 't1']);
  });

  test('keyword + rating + availability filters', () {
    expect(filterTechnicians(_techs, q: 'hvac').length, 2);
    expect(filterTechnicians(_techs, minRating: 4.8).length, 2);
    expect(
        filterTechnicians(_techs, availableOnly: true)
            .every((t) => t.available),
        true);
  });

  test('service filter by category and query', () {
    const all = [
      ServiceItem(
          id: 's1', categoryId: 'c1', name: 'Washer Fix', basePrice: 10),
      ServiceItem(
          id: 's2', categoryId: 'c2', name: 'Vent Cal', basePrice: 20),
    ];
    expect(filterServices(all, categoryId: 'c1').length, 1);
    expect(filterServices(all, q: 'vent').first.id, 's2');
  });
}
