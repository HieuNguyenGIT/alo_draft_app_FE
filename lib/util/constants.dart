// constants.dart
const String dockerUrl = 'http://localhost:3000/api';
const String localrunUrl = 'http://192.168.100.87:3003/api';

// 🔥 ENSURE: Use the same base URL for both API and Socket.IO
const String baseUrl = 'http://192.168.100.87:3003/api'; // HTTP API
const String socketIOUrl =
    'http://192.168.100.87:3003'; // Socket.IO (same server, no /api)

// 🔥 DEBUG: Health check URL
const String healthCheckUrl = 'http://192.168.100.87:3003/health';

// 🔥 DEBUG: Test URLs
const String testHttpUrl = 'http://192.168.100.87:3003/api/auth/login';
const String testSocketUrl = 'http://192.168.100.87:3003/socket.io/';

const String env = 'local';
