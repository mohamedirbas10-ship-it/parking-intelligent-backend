const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testBookingAuthentication() {
  console.log('\n========================================');
  console.log('🧪 Testing Booking Authentication Fix');
  console.log('========================================\n');

  try {
    // Step 1: Check server health
    console.log('1️⃣ Checking server health...');
    const healthResponse = await axios.get(`${BASE_URL}/`);
    console.log(`   ✅ Server is running`);
    console.log(`   📊 Database: ${healthResponse.data.database}`);
    console.log(`   🕐 Server time: ${healthResponse.data.timestamp}\n`);

    // Step 2: Register a new user
    console.log('2️⃣ Registering test user...');
    const email = `test_${Date.now()}@example.com`;
    const password = 'testpass123';
    const name = 'Test User';

    try {
      const registerResponse = await axios.post(`${BASE_URL}/api/auth/register`, {
        email,
        password,
        name
      });

      console.log(`   ✅ User registered: ${registerResponse.data.user.email}`);
      console.log(`   🔑 Token received: ${registerResponse.data.token.substring(0, 30)}...\n`);

      const token = registerResponse.data.token;
      const userId = registerResponse.data.user.id || registerResponse.data.user._id;

      // Step 3: Verify token
      console.log('3️⃣ Verifying token...');
      const verifyResponse = await axios.get(`${BASE_URL}/api/auth/verify`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });
      console.log(`   ✅ Token is valid for user: ${verifyResponse.data.user.email}\n`);

      // Step 4: Get available slots
      console.log('4️⃣ Fetching available slots...');
      const slotsResponse = await axios.get(`${BASE_URL}/api/parking/slots`, {
        headers: {
          'Authorization': `Bearer ${token}`
        }
      });

      const availableSlots = slotsResponse.data.slots.filter(s => s.status === 'available');
      console.log(`   ✅ Found ${availableSlots.length} available slots`);

      if (availableSlots.length > 0) {
        console.log(`   📍 First available slot: ${availableSlots[0].id}\n`);
      } else {
        console.log(`   ⚠️  No available slots found\n`);
        return;
      }

      // Step 5: Create a booking (THE CRITICAL TEST)
      console.log('5️⃣ Creating booking (THIS IS THE FIX TEST)...');
      const slotId = availableSlots[0].id;
      const duration = 2;
      const startTime = new Date();

      console.log(`   📋 Booking details:`);
      console.log(`      Slot: ${slotId}`);
      console.log(`      Duration: ${duration} hours`);
      console.log(`      Start: ${startTime.toISOString()}`);
      console.log(`      User ID: ${userId}`);
      console.log(`      Token: ${token.substring(0, 30)}...`);

      const bookingResponse = await axios.post(
        `${BASE_URL}/api/bookings`,
        {
          slotId,
          duration,
          startTime: startTime.toISOString()
        },
        {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json'
          }
        }
      );

      if (bookingResponse.data.success) {
        console.log(`\n   ✅ ✅ ✅ BOOKING CREATED SUCCESSFULLY! ✅ ✅ ✅`);
        console.log(`   📝 Booking ID: ${bookingResponse.data.booking.bookingId || bookingResponse.data.booking._id}`);
        console.log(`   🔖 QR Code: ${bookingResponse.data.booking.qrCode}`);
        console.log(`   🅿️  Slot: ${bookingResponse.data.booking.slotId}`);
        console.log(`   ⏰ Duration: ${bookingResponse.data.booking.duration}h`);
        console.log(`\n   🎉 THE AUTHENTICATION FIX IS WORKING! 🎉\n`);

        // Step 6: Verify the booking was created
        console.log('6️⃣ Verifying booking in database...');
        const userBookingsResponse = await axios.get(
          `${BASE_URL}/api/bookings/user/${userId}`,
          {
            headers: {
              'Authorization': `Bearer ${token}`
            }
          }
        );

        const userBookings = userBookingsResponse.data.bookings;
        console.log(`   ✅ User has ${userBookings.length} booking(s)`);

        if (userBookings.length > 0) {
          console.log(`   📋 Latest booking: ${userBookings[0].slotId} - ${userBookings[0].status}\n`);
        }

        console.log('========================================');
        console.log('✅ ALL TESTS PASSED!');
        console.log('🎊 Booking authentication is now fixed!');
        console.log('========================================\n');

      } else {
        console.log(`\n   ❌ Booking failed: ${bookingResponse.data.error}`);
        console.log(`   Response: ${JSON.stringify(bookingResponse.data, null, 2)}\n`);
      }

    } catch (registerError) {
      if (registerError.response && registerError.response.status === 409) {
        console.log(`   ⚠️  User already exists, trying to login instead...\n`);

        // Try login
        console.log('2b️⃣ Logging in with existing user...');
        const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
          email,
          password
        });

        const token = loginResponse.data.token;
        const userId = loginResponse.data.user.id || loginResponse.data.user._id;

        console.log(`   ✅ Login successful for: ${loginResponse.data.user.email}`);
        console.log(`   🔑 Token: ${token.substring(0, 30)}...\n`);

        // Continue with booking test...
        console.log('5️⃣ Creating booking with logged-in user...');

        const slotsResponse = await axios.get(`${BASE_URL}/api/parking/slots`);
        const availableSlots = slotsResponse.data.slots.filter(s => s.status === 'available');

        if (availableSlots.length === 0) {
          console.log(`   ⚠️  No available slots\n`);
          return;
        }

        const bookingResponse = await axios.post(
          `${BASE_URL}/api/bookings`,
          {
            slotId: availableSlots[0].id,
            duration: 2,
            startTime: new Date().toISOString()
          },
          {
            headers: {
              'Authorization': `Bearer ${token}`,
              'Content-Type': 'application/json'
            }
          }
        );

        if (bookingResponse.data.success) {
          console.log(`\n   ✅ ✅ ✅ BOOKING CREATED SUCCESSFULLY! ✅ ✅ ✅`);
          console.log(`   🎉 THE AUTHENTICATION FIX IS WORKING! 🎉\n`);
        } else {
          console.log(`\n   ❌ Booking failed: ${bookingResponse.data.error}\n`);
        }
      } else {
        throw registerError;
      }
    }

  } catch (error) {
    console.error('\n❌ TEST FAILED!');

    if (error.response) {
      console.error(`   Status: ${error.response.status}`);
      console.error(`   Error: ${JSON.stringify(error.response.data, null, 2)}`);
    } else if (error.request) {
      console.error(`   No response from server. Is it running on ${BASE_URL}?`);
    } else {
      console.error(`   Error: ${error.message}`);
    }

    console.log('\n========================================\n');
    process.exit(1);
  }
}

// Run the test
testBookingAuthentication();
