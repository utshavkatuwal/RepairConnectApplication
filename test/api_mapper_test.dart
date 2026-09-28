import 'package:flutter_test/flutter_test.dart';
import 'package:repairconnect/core/constants/app_constants.dart';
import 'package:repairconnect/core/network/api_mapper.dart';
import 'package:repairconnect/shared/models/models.dart';

void main() {
  test('statuses map snake to domain', () {
    expect(normalizeStatus('requested'), JobStatus.requested);
    expect(normalizeStatus('searching'), JobStatus.requested);
    expect(normalizeStatus('technician_arriving'), JobStatus.enRoute);
    expect(normalizeStatus('in_progress'), JobStatus.inProgress);
    expect(normalizeStatus('IN_PROGRESS'), JobStatus.inProgress);
    expect(normalizeStatus('completed'), JobStatus.completed);
    expect(normalizeStatus('cancelled'), JobStatus.cancelled);
  });

  test('unknown statuses stay visible but inert', () {
    final s = normalizeStatus('teleporting');
    expect(JobStatus.transitions[s], isNull);
  });

  test('roles map both directions', () {
    expect(normalizeRole('customer'), AppRoles.customer);
    expect(normalizeRole('technician'), AppRoles.technician);
    expect(normalizeRole('super_admin'), AppRoles.admin);
    expect(normalizeRole('CUSTOMER'), AppRoles.customer);
    expect(apiRole(AppRoles.customer), 'customer');
    expect(apiRole(AppRoles.technician), 'technician');
    expect(apiRole(AppRoles.admin), 'admin');
  });

  test('models parse live backend shapes', () {
    final u = User.fromJson({
      'id': 7,
      'name': 'Dev Admin',
      'email': 'admin@repairconnect.dev',
      'role': 'admin',
    });
    expect(u.role, AppRoles.admin);
    final b = Booking.fromJson({
      'id': 1,
      'service_request_id': 2,
      'technician_arriving': null,
      'status': 'technician_arriving',
      'price': 1500,
    });
    expect(b.status, JobStatus.enRoute);
    final r = ServiceRequest.fromJson({
      'id': 2,
      'specialty_id': 3,
      'description': 'x',
      'status': 'searching',
    });
    expect(r.status, JobStatus.requested);
    expect(r.serviceId, '3');
  });

  test('request body splits coordinates + titles', () {
    final body = serviceRequestBody(
      specialtyId: '3',
      description: 'Kitchen tap leaks continuously, needs washer.',
      address: 'Lakeside 1 [28.2096, 83.9856]',
    );
    expect(body['specialty_id'], '3');
    expect(body['latitude'], 28.2096);
    expect(body['longitude'], 83.9856);
    expect(body['address'], 'Lakeside 1');
    expect((body['title'] as String).isNotEmpty, true);

    final named = serviceRequestBody(
      specialtyId: '3',
      title: 'Anesthesia Vent Calibration',
      description: 'Long description here.',
      address: 'Somewhere',
    );
    expect(named['title'], 'Anesthesia Vent Calibration');
    expect(named.containsKey('latitude'), false);
  });
}
