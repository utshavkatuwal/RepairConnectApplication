// Strongly-typed domain models (manual fromJson/toJson to avoid
// build_runner in this env; compatible with json_serializable contracts).
// Backend (Laravel/MySQL) is authoritative; Flutter never trusts client state.
// Wire values pass through api_mapper (snake_case -> domain constants).

import '../../core/network/api_mapper.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role; // CUSTOMER | TECHNICIAN | ADMIN
  final String? phone;
  final String? avatarUrl;
  final bool isVerified;
  final bool techVerified;
  final String techStatus; // PENDING | APPROVED | REJECTED | CORRECTION
  const User(
      {required this.id,
      required this.name,
      required this.email,
      required this.role,
      this.phone,
      this.avatarUrl,
      this.isVerified = true,
      this.techVerified = false,
      this.techStatus = 'PENDING'});
  factory User.fromJson(Map<String, dynamic> j) => User(
        id: '${j['id']}',
        name: '${j['name'] ?? ''}',
        email: '${j['email'] ?? ''}',
        role: normalizeRole('${j['role'] ?? 'CUSTOMER'}'),
        phone: j['phone']?.toString(),
        avatarUrl: j['avatar_url']?.toString() ?? j['avatarUrl']?.toString(),
        isVerified: (j['is_verified'] ?? j['isVerified'] ?? true) == true ||
            '${j['is_verified'] ?? ''}' == '1',
        techVerified: (j['tech_verified'] ??
                    j['is_tech_verified'] ??
                    j['verified'] ??
                    false) ==
                true ||
            '${j['tech_verified'] ?? ''}' == '1',
        techStatus: '${j['tech_status'] ?? j['verification_status'] ?? 'PENDING'}',
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'avatar_url': avatarUrl,
        'is_verified': isVerified,
        'tech_verified': techVerified,
        'tech_status': techStatus,
      };

  /// Unverified technicians must not receive verification-gated functionality.
  bool get canAcceptJobs =>
      role != 'TECHNICIAN' || (techVerified && techStatus == 'APPROVED');
}

class Category {
  final String id;
  final String name;
  final String? icon;
  const Category({required this.id, required this.name, this.icon});
  factory Category.fromJson(Map<String, dynamic> j) =>
      Category(id: '${j['id']}', name: '${j['name']}', icon: j['icon']?.toString());
}

class ServiceItem {
  final String id;
  final String categoryId;
  final String name;
  final String? description;
  final double basePrice;
  const ServiceItem(
      {required this.id,
      required this.categoryId,
      required this.name,
      this.description,
      required this.basePrice});
  factory ServiceItem.fromJson(Map<String, dynamic> j) => ServiceItem(
        id: '${j['id']}',
        categoryId: '${j['category_id'] ?? j['categoryId']}',
        name: '${j['name']}',
        description: j['description']?.toString(),
        basePrice: double.tryParse('${j['base_price'] ?? j['basePrice'] ?? 0}') ?? 0,
      );
}

class Technician {
  final String id;
  final String userId;
  final String name;
  final String specialty;
  final double rating;
  final int jobsCompleted;
  final bool verified;
  final bool available;
  final String? avatarUrl;
  final String? serviceArea;
  const Technician(
      {required this.id,
      required this.userId,
      required this.name,
      required this.specialty,
      required this.rating,
      required this.jobsCompleted,
      required this.verified,
      required this.available,
      this.avatarUrl,
      this.serviceArea});
  factory Technician.fromJson(Map<String, dynamic> j) => Technician(
        id: '${j['id']}',
        userId: '${j['user_id'] ?? j['userId'] ?? ''}',
        name: '${j['name'] ?? ''}',
        specialty: '${j['specialty'] ?? ''}',
        rating: double.tryParse('${j['rating'] ?? 0}') ?? 0,
        jobsCompleted: int.tryParse('${j['jobs_completed'] ?? j['jobsCompleted'] ?? 0}') ?? 0,
        verified: (j['verified'] ?? j['is_verified'] ?? false) == true ||
            '${j['verified'] ?? ''}' == '1',
        available: (j['available'] ?? true) == true,
        avatarUrl: j['avatar_url']?.toString(),
        serviceArea: j['service_area']?.toString(),
      );
}

class ServiceRequest {
  final String id;
  final String customerId;
  final String serviceId;
  final String description;
  final String status;
  final String? preferredAt;
  final String? address;
  const ServiceRequest(
      {required this.id,
      required this.customerId,
      required this.serviceId,
      required this.description,
      required this.status,
      this.preferredAt,
      this.address});
  factory ServiceRequest.fromJson(Map<String, dynamic> j) => ServiceRequest(
        id: '${j['id']}',
        customerId: '${j['customer_id'] ?? ''}',
        serviceId: '${j['service_id'] ?? j['specialty_id'] ?? ''}',
        description: '${j['description'] ?? ''}',
        status: normalizeStatus('${j['status'] ?? 'REQUESTED'}'),
        preferredAt: j['preferred_at']?.toString(),
        address: j['address']?.toString(),
      );
}

class Booking {
  final String id;
  final String requestId;
  final String customerId;
  final String technicianId;
  final String status;
  final double price;
  final String paymentStatus;
  final String? scheduledAt;
  const Booking(
      {required this.id,
      required this.requestId,
      required this.customerId,
      required this.technicianId,
      required this.status,
      required this.price,
      required this.paymentStatus,
      this.scheduledAt});
  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
        id: '${j['id']}',
        requestId: '${j['request_id'] ?? j['service_request_id'] ?? ''}',
        customerId: '${j['customer_id'] ?? ''}',
        technicianId: '${j['technician_id'] ?? ''}',
        status: normalizeStatus('${j['status'] ?? 'REQUESTED'}'),
        price: double.tryParse('${j['price'] ?? 0}') ?? 0,
        paymentStatus: '${j['payment_status'] ?? 'PENDING'}',
        scheduledAt: j['scheduled_at']?.toString(),
      );
}

class Conversation {
  final String id;
  final String bookingId;
  const Conversation({required this.id, required this.bookingId});
  factory Conversation.fromJson(Map<String, dynamic> j) =>
      Conversation(id: '${j['id']}', bookingId: '${j['booking_id'] ?? ''}');
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final String type;
  final String createdAt;
  final bool read;
  const ChatMessage(
      {required this.id,
      required this.conversationId,
      required this.senderId,
      required this.body,
      this.type = 'text',
      required this.createdAt,
      required this.read});
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: '${j['id']}',
        conversationId: '${j['conversation_id'] ?? ''}',
        senderId: '${j['sender_id'] ?? ''}',
        body: '${j['body'] ?? j['content'] ?? ''}',
        type: '${j['type'] ?? 'text'}',
        createdAt: '${j['created_at'] ?? ''}',
        read: (j['read'] ?? j['is_read'] ?? false) == true,
      );
  Map<String, dynamic> toJson() => {
        'conversation_id': conversationId,
        'body': body,
        'type': type,
      };
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final String createdAt;
  const AppNotification(
      {required this.id,
      required this.type,
      required this.title,
      required this.body,
      required this.read,
      required this.createdAt});
  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: '${j['id']}',
        type: '${j['type'] ?? 'SYSTEM'}',
        title: '${j['title'] ?? ''}',
        body: '${j['body'] ?? ''}',
        read: (j['read'] ?? false) == true,
        createdAt: '${j['created_at'] ?? ''}',
      );
}

class PaymentTx {
  final String id;
  final String bookingId;
  final double amount;
  final String status;
  final String? txRef;
  const PaymentTx(
      {required this.id,
      required this.bookingId,
      required this.amount,
      required this.status,
      this.txRef});
  factory PaymentTx.fromJson(Map<String, dynamic> j) => PaymentTx(
        id: '${j['id']}',
        bookingId: '${j['booking_id'] ?? ''}',
        amount: double.tryParse('${j['amount'] ?? 0}') ?? 0,
        status: '${j['status'] ?? 'PENDING'}',
        txRef: j['tx_ref']?.toString() ?? j['reference']?.toString(),
      );
}

class Review {
  final String id;
  final String bookingId;
  final int rating;
  final String? comment;
  const Review(
      {required this.id, required this.bookingId, required this.rating, this.comment});
  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: '${j['id']}',
        bookingId: '${j['booking_id'] ?? ''}',
        rating: int.tryParse('${j['rating'] ?? 0}') ?? 0,
        comment: j['comment']?.toString(),
      );
}

/// Remaining §10 relational entities. All parse both snake_case (API)
/// and camelCase (legacy) keys; unknown/missing fields default safely.

class Address {
  final String id;
  final String userId;
  final String? label;
  final String line1;
  final String? city;
  final double? lat;
  final double? lng;
  const Address(
      {required this.id,
      required this.userId,
      this.label,
      required this.line1,
      this.city,
      this.lat,
      this.lng});
  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: '${j['id']}',
        userId: '${j['user_id'] ?? j['userId'] ?? ''}',
        label: j['label']?.toString(),
        line1: '${j['line1'] ?? j['line_1'] ?? ''}',
        city: j['city']?.toString(),
        lat: j['lat'] == null ? null : double.tryParse('${j['lat']}'),
        lng: j['lng'] == null ? null : double.tryParse('${j['lng']}'),
      );
}

class JobStatusEvent {
  final String id;
  final String bookingId;
  final String? from;
  final String to;
  final String actorId;
  final String createdAt;
  const JobStatusEvent(
      {required this.id,
      required this.bookingId,
      this.from,
      required this.to,
      required this.actorId,
      required this.createdAt});
  factory JobStatusEvent.fromJson(Map<String, dynamic> j) =>
      JobStatusEvent(
        id: '${j['id']}',
        bookingId: '${j['booking_id'] ?? ''}',
        from: j['from_status']?.toString() ?? j['from']?.toString(),
        to: '${j['to_status'] ?? j['to'] ?? ''}',
        actorId: '${j['actor_id'] ?? ''}',
        createdAt: '${j['created_at'] ?? ''}',
      );
}

class Transaction {
  final String id;
  final String paymentId;
  final String kind;
  final double amount;
  const Transaction(
      {required this.id,
      required this.paymentId,
      required this.kind,
      required this.amount});
  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: '${j['id']}',
        paymentId: '${j['payment_id'] ?? ''}',
        kind: '${j['kind'] ?? ''}',
        amount: double.tryParse('${j['amount'] ?? 0}') ?? 0,
      );
}

class Invoice {
  final String id;
  final String bookingId;
  final double total;
  final String issuedAt;
  const Invoice(
      {required this.id,
      required this.bookingId,
      required this.total,
      required this.issuedAt});
  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        id: '${j['id']}',
        bookingId: '${j['booking_id'] ?? ''}',
        total: double.tryParse('${j['total'] ?? 0}') ?? 0,
        issuedAt: '${j['issued_at'] ?? ''}',
      );
}

class Complaint {
  final String id;
  final String? bookingId;
  final String reporterId;
  final String body;
  final String status;
  const Complaint(
      {required this.id,
      this.bookingId,
      required this.reporterId,
      required this.body,
      required this.status});
  factory Complaint.fromJson(Map<String, dynamic> j) => Complaint(
        id: '${j['id']}',
        bookingId: j['booking_id']?.toString(),
        reporterId: '${j['reporter_id'] ?? ''}',
        body: '${j['body'] ?? ''}',
        status: '${j['status'] ?? 'OPEN'}',
      );
}

class Favorite {
  final String technicianId;
  const Favorite(this.technicianId);
  factory Favorite.fromJson(Map<String, dynamic> j) =>
      Favorite('${j['technician_id'] ?? j['id']}');
}

class AttachmentMeta {
  final String id;
  final String url;
  final String mime;
  final int size;
  const AttachmentMeta(
      {required this.id,
      required this.url,
      required this.mime,
      required this.size});
  factory AttachmentMeta.fromJson(Map<String, dynamic> j) =>
      AttachmentMeta(
        id: '${j['id']}',
        url: '${j['url'] ?? ''}',
        mime: '${j['mime'] ?? j['mime_type'] ?? 'application/octet-stream'}',
        size: int.tryParse('${j['size'] ?? 0}') ?? 0,
      );

  /// Client-side upload guard (§19). Server revalidates authoritatively.
  static String? validateForUpload(
      {required String mime, required int bytes}) {
    const allowed = [
      'image/jpeg',
      'image/png',
      'image/webp',
      'application/pdf'
    ];
    if (!allowed.contains(mime)) return 'Unsupported file type';
    if (bytes > 10 * 1024 * 1024) return 'Max file size is 10MB';
    return null;
  }
}

class AuditLog {
  final String id;
  final String actorId;
  final String action;
  final String? targetType;
  final String? targetId;
  final String createdAt;
  const AuditLog(
      {required this.id,
      required this.actorId,
      required this.action,
      this.targetType,
      this.targetId,
      required this.createdAt});
  factory AuditLog.fromJson(Map<String, dynamic> j) => AuditLog(
        id: '${j['id']}',
        actorId: '${j['actor_id'] ?? ''}',
        action: '${j['action'] ?? ''}',
        targetType: j['target_type']?.toString(),
        targetId: j['target_id']?.toString(),
        createdAt: '${j['created_at'] ?? ''}',
      );
}
