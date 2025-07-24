// constants.dart
const String dockerUrl = 'http://localhost:3000/api';
const String localrunUrl = 'http://192.168.100.87:3003/api';

const String baseUrl = 'http://192.168.100.87:3003/api'; // HTTP API + WebSocket
const String socketIOUrl =
    'http://192.168.100.87:3003'; // Socket.IO (WebSocket transport only)

const String socketIOTestUrl =
    'http://192.168.100.87:3003/test'; // Test namespace
const String webSocketUrl = 'ws://192.168.100.87:3003/ws'; // Native WebSocket

const int socketIOTimeout = 45000; // 45 seconds for main connection
const int socketIOTestTimeout = 30000; // 30 seconds for test connection
const int webSocketTimeout = 30000; // 30 seconds for WebSocket

const bool enableSocketIODebug = true;
