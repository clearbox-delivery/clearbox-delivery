#!/usr/bin/env -S deno run --allow-env --allow-net

// Dynamic seed script for generating test data
// [TC-MER-CO-001, TC-COU-ACPT-001]

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const supabaseUrl = Deno.env.get('SUPABASE_URL') || 'http://localhost:54321';
const serviceKey = Deno.env.get('SERVICE_ROLE_KEY') || Deno.env.get('SUPABASE_SERVICE_KEY');

if (!serviceKey) {
  console.error('ERROR: SERVICE_ROLE_KEY or SUPABASE_SERVICE_KEY not set');
  Deno.exit(1);
}

const supabase = createClient(supabaseUrl, serviceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false,
  },
});

console.log('🌱 Seeding dynamic test data...');

// Create 10 pending orders for merchant testing [TC-MER-CO-001]
async function seedPendingOrders() {
  console.log('Creating pending orders for merchant...');
  
  const customerAuthId = '00000000-0000-0000-0000-000000000001';
  const merchantAuthId = '00000000-0000-0000-0000-000000000002';

  for (let i = 0; i < 10; i++) {
    const { data, error } = await supabase.rpc('create_order', {
      p_merchant_id: merchantAuthId,
      p_items: [
        {
          sku: `bento-00${(i % 3) + 1}`,
          name: `Test Bento ${i + 1}`,
          quantity: 1 + (i % 3),
          unit_price: 100,
        },
      ],
      p_delivery_price: 45 + (i * 5),
      p_h3_customer: '8a1234567890def',
      p_customer_notes: `Test order ${i + 1}`,
    });

    if (error) {
      console.error(`Error creating order ${i}:`, error);
    } else {
      console.log(`✓ Created order ${i + 1}:`, data?.id);
    }

    // Small delay to avoid rate limits
    await new Promise(resolve => setTimeout(resolve, 100));
  }
}

// Create orders in WAITING_COURIER status for courier testing [TC-COU-ACPT-001]
async function seedWaitingCourierOrders() {
  console.log('Creating WAITING_COURIER orders for courier testing...');
  
  const customerAuthId = '00000000-0000-0000-0000-000000000001';
  const merchantAuthId = '00000000-0000-0000-0000-000000000002';

  for (let i = 0; i < 5; i++) {
    // Create order
    const { data: order, error: createError } = await supabase.rpc('create_order', {
      p_merchant_id: merchantAuthId,
      p_items: [
        {
          sku: 'bento-001',
          name: 'Courier Test Bento',
          quantity: 1,
          unit_price: 100,
        },
      ],
      p_delivery_price: 50 + (i * 10),
      p_h3_customer: '8a1234567890def',
    });

    if (createError) {
      console.error(`Error creating courier order ${i}:`, createError);
      continue;
    }

    // Confirm order to move to WAITING_COURIER
    const { data: confirmed, error: confirmError } = await supabase.rpc('merchant_confirm_order', {
      p_order_id: order.id,
      p_prep_time_minutes: 15 + (i * 5),
    });

    if (confirmError) {
      console.error(`Error confirming order ${i}:`, confirmError);
    } else {
      console.log(`✓ Created WAITING_COURIER order ${i + 1}:`, confirmed?.id);
    }

    await new Promise(resolve => setTimeout(resolve, 100));
  }
}

// Main execution
try {
  await seedPendingOrders();
  await seedWaitingCourierOrders();
  console.log('✅ Dynamic seeding complete!');
} catch (error) {
  console.error('❌ Seeding failed:', error);
  Deno.exit(1);
}


