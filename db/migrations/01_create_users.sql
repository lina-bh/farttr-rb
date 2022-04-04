CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  name TEXT UNIQUE NOT NULL CHECK(LENGTH(name) > 0),
  email TEXT,
  password_digest BLOB
);