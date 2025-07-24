// constants.dart

// Docker URL (for when running in Docker)

const String dockerUrl = 'http://localhost:3000/api';

// Local development URL (for direct Node.js run)
const String localrunUrl = 'http://192.168.100.87:3003/api';

// ========== PRODUCTION CONFIGURATION ==========

// HTTP API base URL (for REST endpoints)
const String baseUrl = 'http://192.168.100.87:3003/api';

// Socket.IO URLs (same port as main server)
const String socketIOUrl = 'http://192.168.100.87:3003'; // Main namespace
const String socketIOTestUrl =
    'http://192.168.100.87:3003/test'; // Test namespace

// WebSocket URL (with specific /ws path)
const String webSocketUrl = 'ws://192.168.100.87:3003/ws';

// ========== URL EXPLANATION ==========
/*
🟦 Socket.IO Main (requires auth): http://192.168.100.87:3003
🧪 Socket.IO Test (no auth): http://192.168.100.87:3003/test  
🟩 WebSocket (requires auth): ws://192.168.100.87:3003/ws
🌐 HTTP API: http://192.168.100.87:3003/api

All services run on the same port (3003) but different paths/namespaces.
*/
