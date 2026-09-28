// ignore_for_file: use_null_aware_elements
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/config/env.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/security/input_safety.dart';
import '../../../shared/models/models.dart';

/// Review business rules (§35 + §6):
/// - Available only after eligible COMPLETED booking, by a participant.
/// - Rating 1–5, comment optional (max 1000).
/// - One review per booking (unique); edit allowed, delete per policy.
/// - Report flags for admin moderation. Server enforces authoritatively.
class ReviewRules {
  static String? validateRating(int r) {
    if (r < 1 || r > 5) return 'Rating must be 1–5';
    return null;
  }

  static String? validateComment(String? c) {
    if (c != null && c.length > 1000) return 'Max 1000 characters';
    return null;
  }

  static String? validateEligibility(
      {required String bookingStatus, required bool isParticipant}) {
    if (bookingStatus != JobStatus.completed) {
      return 'Reviews unlock after job completion';
    }
    if (!isParticipant) return 'Only job participants can review';
    return null;
  }
}

abstract class ReviewsRepository {
  Future<Review> submit(
      {required String bookingId,
      required int rating,
      String? comment});
  Future<List<Review>> forBooking(String bookingId);
  Future<List<Review>> forTechnician(String technicianId);
  Future<Review> update(String id, {int? rating, String? comment});
  Future<void> remove(String id);
  Future<void> report(String id, String reason);
}

class FakeReviewsRepository implements ReviewsRepository {
  final Map<String, Review> _byBooking = {};
  int _seq = 0;

  @override
  Future<Review> submit(
      {required String bookingId,
      required int rating,
      String? comment}) async {
    final clean =
        comment == null ? null : sanitizeText(comment, max: 1000);
    final rErr = ReviewRules.validateRating(rating) ??
        ReviewRules.validateComment(clean);
    if (rErr != null) throw ValidationFailure(rErr);
    if (_byBooking.containsKey(bookingId)) {
      throw const ValidationFailure('This booking already has a review');
    }
    _seq++;
    final r = Review(
        id: 'rev-$_seq',
        bookingId: bookingId,
        rating: rating,
        comment: clean);
    _byBooking[bookingId] = r;
    return r;
  }

  @override
  Future<List<Review>> forBooking(String bookingId) async =>
      [if (_byBooking[bookingId] != null) _byBooking[bookingId]!];

  @override
  Future<List<Review>> forTechnician(String technicianId) async =>
      _byBooking.values.toList();

  @override
  Future<Review> update(String id,
      {int? rating, String? comment}) async {
    final e = _byBooking.entries
        .where((x) => x.value.id == id)
        .toList();
    if (e.isEmpty) throw const NotFoundFailure('Review not found');
    if (rating != null) {
      final err = ReviewRules.validateRating(rating);
      if (err != null) throw ValidationFailure(err);
    }
    final cleanComment =
        comment == null ? null : sanitizeText(comment, max: 1000);
    if (comment != null) {
      final err = ReviewRules.validateComment(cleanComment);
      if (err != null) throw ValidationFailure(err);
    }
    final old = e.first.value;
    final upd = Review(
        id: old.id,
        bookingId: old.bookingId,
        rating: rating ?? old.rating,
        comment: cleanComment ?? old.comment);
    _byBooking[e.first.key] = upd;
    return upd;
  }

  @override
  Future<void> remove(String id) async {
    _byBooking.removeWhere((_, v) => v.id == id);
  }

  @override
  Future<void> report(String id, String reason) async {
    final clean = sanitizeText(reason, max: 1000);
    if (clean.length < 5) {
      throw const ValidationFailure('Report reason required (min 5)');
    }
    // Flagged server-side for admin moderation; fake acknowledges.
  }
}

class ApiReviewsRepository implements ReviewsRepository {
  final DioClient api;
  ApiReviewsRepository(this.api);

  @override
  Future<Review> submit(
      {required String bookingId,
      required int rating,
      String? comment}) async {
    try {
      final r = await api.dio.post(ApiRoutes.reviews, data: {
        'booking_id': bookingId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      });
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'])
          : body;
      return Review.fromJson(data);
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<List<Review>> forBooking(String bookingId) async {
    if (AppEnv.useFakeBackend) {
      return FakeReviewsRepository().forBooking(bookingId);
    }
    try {
      final r = await api.getRetry(ApiRoutes.reviews,
          query: {'booking_id': bookingId});
      final body = Map<String, dynamic>.from(r.data as Map);
      return ApiResponse.list(body, Review.fromJson);
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<List<Review>> forTechnician(String technicianId) async {
    try {
      final r = await api.getRetry(ApiRoutes.reviews,
          query: {'technician_id': technicianId});
      final body = Map<String, dynamic>.from(r.data as Map);
      return ApiResponse.list(body, Review.fromJson);
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<Review> update(String id,
      {int? rating, String? comment}) async {
    try {
      final r = await api.dio.patch('${ApiRoutes.reviews}/$id', data: {
        if (rating != null) 'rating': rating,
        if (comment != null) 'comment': comment,
      });
      final body = Map<String, dynamic>.from(r.data as Map);
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'])
          : body;
      return Review.fromJson(data);
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<void> remove(String id) async {
    try {
      await api.dio.delete('${ApiRoutes.reviews}/$id');
    } catch (e) {
      throw api.mapError(e);
    }
  }

  @override
  Future<void> report(String id, String reason) async {
    try {
      await api.dio.post('${ApiRoutes.reviews}/$id/report',
          data: {'reason': reason});
    } catch (e) {
      throw api.mapError(e);
    }
  }
}
