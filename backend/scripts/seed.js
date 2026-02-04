require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../src/models/User');
const CountRecord = require('../src/models/CountRecord');

const USER_IDS = [
  '65a100000000000000000001',
  '65a100000000000000000002',
  '65a100000000000000000003',
  '65a100000000000000000004',
  '65a100000000000000000005',
  '65a100000000000000000006',
  '65a100000000000000000007',
  '65a100000000000000000008',
  '65a100000000000000000009',
  '65a100000000000000000010',
];

const TARGETS = [
  'Radha',
  'Ram',
  'Breaths',
  'Steps',
  'Mantra',
  'Pushups',
  'Pages',
  'Glasses',
  'Minutes',
  'Habits',
];

const createUsers = async () => {
  await User.deleteMany({});

  const users = USER_IDS.map((id, index) => ({
    _id: new mongoose.Types.ObjectId(id),
    name: `Demo User ${index + 1}`,
    email: `demo${index + 1}@countpluse.dev`,
    phone: `+1555000${(index + 1).toString().padStart(3, '0')}`,
    isVerified: true,
    verificationToken: null,
    verificationTokenExpires: null,
  }));

  await User.insertMany(users);
  return users;
};

const countForDate = (date, seed) => {
  const valueSeed = date.getFullYear() * 10000 + (date.getMonth() + 1) * 100 + date.getDate();
  const base = (valueSeed + seed * 97) % 9000;
  const variance = (seed % 5) * 200;
  return Math.max(0, 1000 + base + variance);
};

const createCounts = async (users) => {
  await CountRecord.deleteMany({});
  const today = new Date();
  const end = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const start = new Date(end);
  start.setDate(start.getDate() - 365);

  const records = [];
  for (let i = 0; i < users.length; i += 1) {
    const user = users[i];
    for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
      const dateKey = d.toISOString().slice(0, 10);
      records.push({
        userId: user._id,
        date: dateKey,
        count: countForDate(d, i + 1),
        targetLabel: TARGETS[i % TARGETS.length],
      });
    }
  }

  await CountRecord.insertMany(records);
};

const run = async () => {
  const mongoUri = process.env.MONGODB_URI || 'mongodb://localhost:27017/countpluse';
  await mongoose.connect(mongoUri);
  const users = await createUsers();
  await createCounts(users);
  await mongoose.disconnect();

  console.log('Seed complete.');
  console.log('Demo user IDs (use any):');
  USER_IDS.forEach(id => console.log(`- ${id}`));
  console.log(`Suggested demo user ID: ${USER_IDS[0]}`);
};

run().catch(error => {
  console.error('Seed failed:', error);
  process.exit(1);
});
