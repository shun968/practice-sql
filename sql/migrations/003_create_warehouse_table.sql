USE practice_db;

CREATE TABLE IF NOT EXISTS warehouse (
    warehouse_id INTEGER NOT NULL PRIMARY KEY,
    region CHAR(32) NOT NULL
);
