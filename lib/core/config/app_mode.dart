/// Flip this flag to switch the entire data layer between
/// local SQLite and the remote REST backend.
///
/// LOCAL  → uses sqflite directly (no server needed)
/// REMOTE → calls the Node.js backend via HTTP (set ApiConfig.baseUrl first)
///
/// MIGRATION: When you deploy to production, set this to true and update
/// ApiConfig.baseUrl. No other file needs to change.
const bool kUseRemoteBackend = true;
