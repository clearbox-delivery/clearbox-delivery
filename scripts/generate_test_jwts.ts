#!/usr/bin/env -S deno run --allow-env --allow-net

/**
 * 生成测试用 JWT tokens
 * 用于 RLS 集成测试
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabaseUrl = Deno.env.get('SUPABASE_URL') || 'http://localhost:54321';
const serviceKey = Deno.env.get('SERVICE_ROLE_KEY') || Deno.env.get('SUPABASE_SERVICE_KEY');

if (!serviceKey) {
  console.error('ERROR: SERVICE_ROLE_KEY not set');
  Deno.exit(1);
}

const supabase = createClient(supabaseUrl, serviceKey);

console.log('🔑 Generating test JWT tokens...\n');

const testUsers = [
  { email: 'customer@test.com', password: 'testpass123', role: 'customer' },
  { email: 'merchant@test.com', password: 'testpass123', role: 'merchant' },
  { email: 'courier@test.com', password: 'testpass123', role: 'courier' },
];

for (const user of testUsers) {
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email: user.email,
      password: user.password,
    });

    if (error) {
      console.error(`❌ Failed to sign in as ${user.role}:`, error.message);
      continue;
    }

    if (data.session) {
      console.log(`✅ ${user.role.toUpperCase()} JWT:`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Token: ${data.session.access_token.substring(0, 50)}...`);
      console.log(`   User ID: ${data.user?.id}`);
      console.log();
    }
  } catch (e) {
    console.error(`Error with ${user.role}:`, e);
  }
}

console.log('✅ JWT generation complete!');
console.log('\nCopy these tokens to:');
console.log('- tests/api/env.test.json');
console.log('- CI environment variables');

