-- RepairConnect MySQL schema (normalized, FKs, indexes, soft deletes).
-- Laravel migrations mirror this; Flutter never connects directly.
CREATE DATABASE IF NOT EXISTS repairconnect CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE repairconnect;

CREATE TABLE roles (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, name VARCHAR(20) UNIQUE NOT NULL);
INSERT INTO roles (name) VALUES ('CUSTOMER'),('TECHNICIAN'),('ADMIN');

CREATE TABLE users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(190) UNIQUE NOT NULL,
  phone VARCHAR(40) NULL,
  password_hash VARCHAR(255) NOT NULL,
  avatar_url VARCHAR(512) NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NULL, updated_at TIMESTAMP NULL, deleted_at TIMESTAMP NULL,
  FOREIGN KEY (role_id) REFERENCES roles(id),
  INDEX idx_users_email (email), INDEX idx_users_role (role_id)
);

CREATE TABLE customer_profiles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED UNIQUE NOT NULL,
  default_address_id BIGINT UNSIGNED NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE technician_profiles (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED UNIQUE NOT NULL,
  specialty VARCHAR(120) NOT NULL,
  bio TEXT NULL,
  experience_years INT NOT NULL DEFAULT 0,
  service_area VARCHAR(255) NULL,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  verification_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  rating DECIMAL(3,2) NOT NULL DEFAULT 0,
  jobs_completed INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NULL, updated_at TIMESTAMP NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_tech_verified (is_verified), INDEX idx_tech_available (is_available)
);

CREATE TABLE categories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL, icon VARCHAR(120) NULL, is_active BOOLEAN DEFAULT TRUE
);
CREATE TABLE services (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(160) NOT NULL, description TEXT NULL,
  base_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  FOREIGN KEY (category_id) REFERENCES categories(id),
  INDEX idx_services_cat (category_id)
);
CREATE TABLE technician_services (
  technician_id BIGINT UNSIGNED NOT NULL, service_id BIGINT UNSIGNED NOT NULL,
  price_override DECIMAL(10,2) NULL,
  PRIMARY KEY (technician_id, service_id),
  FOREIGN KEY (technician_id) REFERENCES technician_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE CASCADE
);

CREATE TABLE addresses (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  label VARCHAR(80) NULL, line1 VARCHAR(255) NOT NULL,
  city VARCHAR(120) NULL, lat DECIMAL(10,7) NULL, lng DECIMAL(10,7) NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_addr_user (user_id)
);

CREATE TABLE service_requests (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  customer_id BIGINT UNSIGNED NOT NULL,
  service_id BIGINT UNSIGNED NOT NULL,
  description TEXT NOT NULL,
  preferred_at DATETIME NULL, address_id BIGINT UNSIGNED NULL,
  address_text VARCHAR(512) NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
  created_at TIMESTAMP NULL, updated_at TIMESTAMP NULL, deleted_at TIMESTAMP NULL,
  FOREIGN KEY (customer_id) REFERENCES users(id),
  FOREIGN KEY (service_id) REFERENCES services(id),
  INDEX idx_req_customer (customer_id), INDEX idx_req_status (status)
);

CREATE TABLE bookings (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  request_id BIGINT UNSIGNED UNIQUE NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL, technician_id BIGINT UNSIGNED NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  scheduled_at DATETIME NULL,
  created_at TIMESTAMP NULL, updated_at TIMESTAMP NULL,
  FOREIGN KEY (request_id) REFERENCES service_requests(id),
  FOREIGN KEY (customer_id) REFERENCES users(id),
  FOREIGN KEY (technician_id) REFERENCES technician_profiles(id),
  INDEX idx_book_status (status), INDEX idx_book_tech (technician_id)
);

CREATE TABLE job_status_history (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id BIGINT UNSIGNED NOT NULL,
  from_status VARCHAR(20) NULL, to_status VARCHAR(20) NOT NULL,
  actor_id BIGINT UNSIGNED NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
);

CREATE TABLE conversations (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id BIGINT UNSIGNED UNIQUE NOT NULL,
  created_at TIMESTAMP NULL,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
);
CREATE TABLE conversation_participants (
  conversation_id BIGINT UNSIGNED NOT NULL, user_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (conversation_id, user_id),
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
);
CREATE TABLE messages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  conversation_id BIGINT UNSIGNED NOT NULL,
  sender_id BIGINT UNSIGNED NOT NULL,
  body TEXT NOT NULL, is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE,
  INDEX idx_msg_conv (conversation_id, created_at)
);

CREATE TABLE notifications (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  type VARCHAR(20) NOT NULL, title VARCHAR(200) NOT NULL, body TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_notif_user (user_id, is_read)
);

CREATE TABLE payments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id BIGINT UNSIGNED NOT NULL,
  amount DECIMAL(10,2) NOT NULL, currency CHAR(3) DEFAULT 'USD',
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
  provider VARCHAR(40) NULL, provider_ref VARCHAR(191) NULL,
  idempotency_key VARCHAR(64) UNIQUE NOT NULL,
  created_at TIMESTAMP NULL, updated_at TIMESTAMP NULL,
  FOREIGN KEY (booking_id) REFERENCES bookings(id),
  INDEX idx_pay_booking (booking_id)
);
CREATE TABLE transactions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  payment_id BIGINT UNSIGNED NOT NULL,
  kind VARCHAR(20) NOT NULL, amount DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE CASCADE
);
CREATE TABLE invoices (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id BIGINT UNSIGNED UNIQUE NOT NULL,
  total DECIMAL(10,2) NOT NULL, issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id)
);

CREATE TABLE reviews (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id BIGINT UNSIGNED UNIQUE NOT NULL,
  reviewer_id BIGINT UNSIGNED NOT NULL, rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT NULL, is_flagged BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
);
CREATE TABLE complaints (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_id BIGINT UNSIGNED NULL, reporter_id BIGINT UNSIGNED NOT NULL,
  body TEXT NOT NULL, status VARCHAR(20) DEFAULT 'OPEN',
  resolution TEXT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  actor_id BIGINT UNSIGNED NOT NULL, action VARCHAR(120) NOT NULL,
  target_type VARCHAR(80) NULL, target_id BIGINT UNSIGNED NULL,
  meta JSON NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_actor (actor_id)
);
