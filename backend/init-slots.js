// Quick script to initialize parking slots in the database
const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/reset',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  }
};

console.log('🔄 Initializing parking slots...\n');

const req = http.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('✅ Response Status:', res.statusCode);
    console.log('✅ Response Body:', data);

    if (res.statusCode === 200) {
      console.log('\n🎉 SUCCESS! Parking slots initialized!');
      console.log('📊 6 slots created: A1, A2, A3, A4, A5, A6\n');
    } else {
      console.log('\n❌ Error initializing slots\n');
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Error:', error.message);
  console.log('\n⚠️  Make sure the backend server is running!');
  console.log('   Run: npm start\n');
});

req.end();
