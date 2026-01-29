const https = require('https');

// Reset the backend data
const resetBackend = async () => {
  const options = {
    hostname: 'parking-intelligent-backend.onrender.com',
    port: 443,
    path: '/api/reset',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    }
  };

  const req = https.request(options, (res) => {
    console.log(`Status: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log('Response:', JSON.parse(data));
      console.log('✅ Backend reset complete!');
    });
  });

  req.on('error', (error) => {
    console.error('❌ Error:', error);
  });

  req.end();
};

console.log('🔄 Resetting backend data...');
resetBackend();
