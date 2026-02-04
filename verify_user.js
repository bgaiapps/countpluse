const mongoose = require('mongoose');
require('dotenv').config();

async function verifyUser() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    
    const userSchema = new mongoose.Schema({
      name: String,
      email: String,
      phone: String,
      verified: Boolean,
      token: String
    });
    
    const User = mongoose.model('User', userSchema);
    
    // Verify the test user
    await User.updateOne(
      { email: 'test@example.com' },
      { verified: true }
    );
    
    console.log('✓ User verified successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

verifyUser();
