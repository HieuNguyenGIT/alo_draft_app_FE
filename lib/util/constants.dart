// constants.dart
const String dockerUrl = 'http://localhost:3000/api';
const String localrunUrl = 'http://192.168.100.87:3003/api';

// FIXED: Use the same port for both HTTP API and Socket.IO
const String baseUrl = 'http://192.168.100.87:3003/api'; // HTTP API + WebSocket
const String socketIOUrl =
    'http://192.168.100.87:3003'; // Socket.IO (same port as main server)
