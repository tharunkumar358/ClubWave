-- ============================================================================
-- CampusClubSystem — MySQL InnoDB Database Schema & Initial Seed Script
-- Database: campusflow_db
-- Compatible with MySQL 8.0+ / MySQL Workbench
-- Safe & Idempotent: Does NOT drop existing tables or overwrite user records.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS campusflow_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE campusflow_db;

-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL,
    password_hash VARCHAR(100) NOT NULL,
    role          ENUM('ADMIN', 'FACULTY_COORDINATOR', 'CLUB_LEADER', 'STUDENT') NOT NULL DEFAULT 'STUDENT',
    status        ENUM('ACTIVE', 'INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_users_email UNIQUE (email),
    INDEX idx_users_role_status (role, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Clubs Table
CREATE TABLE IF NOT EXISTS clubs (
    club_id        INT AUTO_INCREMENT PRIMARY KEY,
    club_slug      VARCHAR(50)  NOT NULL,
    club_name      VARCHAR(100) NOT NULL,
    focus_area     VARCHAR(220) NOT NULL,
    description    TEXT         NOT NULL,
    activities     TEXT         NOT NULL,
    icon_class     VARCHAR(60)  NOT NULL DEFAULT 'bi-stars',
    accent_theme   VARCHAR(30)  NOT NULL DEFAULT 'indigo',
    coordinator_id INT          NULL,
    leader_id      INT          NULL,
    created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_clubs_slug UNIQUE (club_slug),
    CONSTRAINT uk_clubs_name UNIQUE (club_name),
    CONSTRAINT fk_clubs_coordinator FOREIGN KEY (coordinator_id)
        REFERENCES users (user_id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_clubs_leader FOREIGN KEY (leader_id)
        REFERENCES users (user_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Club Memberships Table
CREATE TABLE IF NOT EXISTS club_memberships (
    membership_id INT AUTO_INCREMENT PRIMARY KEY,
    club_id       INT       NOT NULL,
    user_id       INT       NOT NULL,
    joined_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status        ENUM('ACTIVE', 'LEFT') NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT uk_club_membership UNIQUE (club_id, user_id),
    INDEX idx_memberships_user (user_id, status),
    CONSTRAINT fk_memberships_club FOREIGN KEY (club_id)
        REFERENCES clubs (club_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_memberships_user FOREIGN KEY (user_id)
        REFERENCES users (user_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Events Table
-- Note: event_date, times, venue, and organizer may be NULL for seeded flagship
-- events (such as Lakshya) until official schedule details are entered by an Admin.
CREATE TABLE IF NOT EXISTS events (
    event_id              INT AUTO_INCREMENT PRIMARY KEY,
    event_code            VARCHAR(50)  NULL,
    is_flagship           TINYINT(1)   NOT NULL DEFAULT 0,
    event_name            VARCHAR(150) NOT NULL,
    description           TEXT         NOT NULL,
    event_date            DATE         NULL,
    start_time            TIME         NULL,
    end_time              TIME         NULL,
    venue                 VARCHAR(180) NULL,
    organizer             VARCHAR(150) NULL,
    registration_deadline DATETIME     NULL,
    capacity              INT          NULL,
    status                ENUM('SCHEDULE_PENDING', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED', 'COMPLETED', 'CANCELLED')
                          NOT NULL DEFAULT 'PENDING_APPROVAL',
    created_by            INT          NULL,
    created_at            TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_events_code UNIQUE (event_code),
    INDEX idx_events_status_date (status, event_date),
    CONSTRAINT fk_events_created_by FOREIGN KEY (created_by)
        REFERENCES users (user_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Event-Clubs Junction Table (supports multi-club and flagship events)
CREATE TABLE IF NOT EXISTS event_clubs (
    event_id INT NOT NULL,
    club_id  INT NOT NULL,
    PRIMARY KEY (event_id, club_id),
    INDEX idx_event_clubs_club (club_id),
    CONSTRAINT fk_event_clubs_event FOREIGN KEY (event_id)
        REFERENCES events (event_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_event_clubs_club FOREIGN KEY (club_id)
        REFERENCES clubs (club_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Event Registrations Table
CREATE TABLE IF NOT EXISTS event_registrations (
    registration_id   INT AUTO_INCREMENT PRIMARY KEY,
    event_id          INT       NOT NULL,
    user_id           INT       NOT NULL,
    registration_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status            ENUM('REGISTERED', 'CANCELLED') NOT NULL DEFAULT 'REGISTERED',
    CONSTRAINT uk_event_registration UNIQUE (event_id, user_id),
    INDEX idx_registrations_user (user_id, status),
    INDEX idx_registrations_event_status (event_id, status),
    CONSTRAINT fk_registrations_event FOREIGN KEY (event_id)
        REFERENCES events (event_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_registrations_user FOREIGN KEY (user_id)
        REFERENCES users (user_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Attendance Table
CREATE TABLE IF NOT EXISTS attendance (
    attendance_id     INT AUTO_INCREMENT PRIMARY KEY,
    event_id          INT       NOT NULL,
    user_id           INT       NOT NULL,
    attendance_status ENUM('PRESENT', 'ABSENT') NOT NULL,
    marked_by         INT       NULL,
    marked_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uk_event_attendance UNIQUE (event_id, user_id),
    INDEX idx_attendance_event (event_id, attendance_status),
    CONSTRAINT fk_attendance_event FOREIGN KEY (event_id)
        REFERENCES events (event_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_attendance_user FOREIGN KEY (user_id)
        REFERENCES users (user_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_attendance_marked_by FOREIGN KEY (marked_by)
        REFERENCES users (user_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Event Approvals Audit History Table
CREATE TABLE IF NOT EXISTS event_approvals (
    approval_id     INT AUTO_INCREMENT PRIMARY KEY,
    event_id        INT          NOT NULL,
    reviewer_id     INT          NOT NULL,
    previous_status VARCHAR(30)  NOT NULL,
    decision        ENUM('APPROVED', 'REJECTED') NOT NULL,
    remarks         VARCHAR(500) NULL,
    reviewed_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_approvals_event (event_id, reviewed_at),
    CONSTRAINT fk_approvals_event FOREIGN KEY (event_id)
        REFERENCES events (event_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_approvals_reviewer FOREIGN KEY (reviewer_id)
        REFERENCES users (user_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- Seed Required Clubs: Prakruthi, Spoorthi, Kruthi, Saheli
-- ============================================================================

INSERT IGNORE INTO clubs (club_slug, club_name, focus_area, description, activities, icon_class, accent_theme)
VALUES
(
    'prakruthi',
    'Prakruthi',
    'Plants, greenery, environmental awareness, tree planting, sustainability, and campus gardening',
    'Prakruthi is the campus environmental and eco-stewardship club dedicated to nurturing green spaces, promoting sustainable habits, and engaging students in hands-on conservation initiatives.',
    'Campus tree plantation drives, botanical garden care, eco-awareness campaigns, waste-segregation initiatives, and sustainability workshops',
    'bi-tree-fill',
    'emerald'
),
(
    'spoorthi',
    'Spoorthi',
    'Literacy, English communication, reading, writing, debates, vocabulary, and language development',
    'Spoorthi empowers students to build confidence in English communication, critical reading, creative writing, public speaking, and structured parliamentary debates.',
    'Parliamentary debates, reading circles, creative writing challenges, vocabulary sprints, extempore speaking, and editorial workshops',
    'bi-journal-richtext',
    'sky'
),
(
    'kruthi',
    'Kruthi',
    'Dance, singing, performing arts, cultural programs, and student talent',
    'Kruthi celebrates artistic expression across classical and contemporary dance, vocal and instrumental music, theatre, and vibrant campus cultural showcases.',
    'Classical and fusion dance showcases, vocal and acoustic recitals, drama productions, open-mic talent evenings, and festive cultural programs',
    'bi-music-note-beamed',
    'amber'
),
(
    'saheli',
    'Saheli',
    'Women''s empowerment, leadership, awareness, mentoring, and skill development',
    'Saheli fosters an inclusive, supportive community focused on women''s leadership, peer mentoring, health and safety awareness, career readiness, and practical skill building.',
    'Leadership dialogues, peer mentoring circles, legal and wellness awareness sessions, self-reliance workshops, and skill development labs',
    'bi-heart-pulse-fill',
    'rose'
);

-- ============================================================================
-- Seed Primary College Event: Lakshya
-- Official date, venue, organizer, deadline, and capacity are intentionally NULL
-- so no unverified details are fabricated; authorized Administrators complete them.
-- ============================================================================

INSERT IGNORE INTO events (
    event_code,
    is_flagship,
    event_name,
    description,
    event_date,
    start_time,
    end_time,
    venue,
    organizer,
    registration_deadline,
    capacity,
    status,
    created_by
) VALUES (
    'LAKSHYA',
    1,
    'Lakshya',
    'Lakshya is our flagship college-wide celebration uniting Prakruthi, Spoorthi, Kruthi, and Saheli through flagship competitions, cultural showcases, literary arenas, sustainability exhibits, and student leadership forums.',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    'SCHEDULE_PENDING',
    NULL
);

-- Associate Lakshya with all four seeded clubs
INSERT IGNORE INTO event_clubs (event_id, club_id)
SELECT e.event_id, c.club_id
FROM events e
CROSS JOIN clubs c
WHERE e.event_code = 'LAKSHYA'
  AND c.club_slug IN ('prakruthi', 'spoorthi', 'kruthi', 'saheli');
