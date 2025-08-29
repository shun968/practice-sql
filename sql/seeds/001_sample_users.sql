-- Seed: 001_sample_users.sql
-- Description: サンプルユーザーデータの挿入
-- Created: 2024-01-01
-- Author: System

USE practice_db;

-- サンプルユーザーデータの挿入
INSERT INTO users (username, email) VALUES
('john_doe', 'john.doe@example.com'),
('jane_smith', 'jane.smith@example.com'),
('bob_wilson', 'bob.wilson@example.com'),
('alice_brown', 'alice.brown@example.com'),
('charlie_davis', 'charlie.davis@example.com'),
('diana_miller', 'diana.miller@example.com'),
('eve_garcia', 'eve.garcia@example.com'),
('frank_rodriguez', 'frank.rodriguez@example.com')
ON DUPLICATE KEY UPDATE
    updated_at = CURRENT_TIMESTAMP;
