# Notification API Contract

Purpose: Define push notification topics, payloads, and delivery mechanisms for the three ClearBox apps. Used by frontend to listen and display realtime updates.

## Delivery mechanism
- **Dev/Web**: Supabase Realtime channels with broadcast messages (no-op in local web runs).
- **Prod/Mobile**: Firebase Cloud Messaging (FCM) with topic subscriptions.
- All apps must handle graceful degradation if no connection.

## Notification types and payloads

### 1. New Order (`topic:merchant:new_order`)
**Recipient**: Merchant app
**Trigger**: Customer creates order
**Payload**:
```json
{
  "type": "new_order",
  "order_id": "uuid",
  "customer_nickname": "string",
  "delivery_price": 100.0,
  "items_summary": "便當 x2, 飲料 x1",
  "created_at": "ISO8601"
}
```
**Action**: Show toast; refresh CurrentOrders pending tab; optional sound/vibration.

### 2. Courier Accepted (`topic:merchant:courier_accepted`, `topic:customer:courier_accepted`)
**Recipients**: Merchant + Customer apps
**Trigger**: Courier accepts order
**Payload**:
```json
{
  "type": "courier_accepted",
  "order_id": "uuid",
  "courier_name": "string",
  "courier_rating": 4.85,
  "eta_minutes": 15
}
```
**Action**: Merchant: move order to "備餐中" tab, show toast "已有人接單，請開始備餐". Customer: show "外送員已接單" toast.

### 3. Prep Ready (`topic:courier:prep_ready`)
**Recipient**: Courier app
**Trigger**: Merchant marks "我備好囉"
**Payload**:
```json
{
  "type": "prep_ready",
  "order_id": "uuid",
  "merchant_name": "string",
  "pickup_code": "ABCD12"
}
```
**Action**: Show toast "可到店取餐".

### 4. Picked Up (`topic:merchant:picked_up`, `topic:customer:picked_up`)
**Recipients**: Merchant + Customer apps
**Trigger**: Courier completes pickup
**Payload**:
```json
{
  "type": "picked_up",
  "order_id": "uuid",
  "pickup_time": "ISO8601"
}
```
**Action**: Merchant: move to "已取餐" tab. Customer: show "外送員已取餐，配送中".

### 5. Arriving in 2 minutes (`topic:customer:arriving_soon`)
**Recipient**: Customer app
**Trigger**: Courier presses "我將於兩分鐘後抵達"
**Payload**:
```json
{
  "type": "arriving_soon",
  "order_id": "uuid",
  "courier_name": "string"
}
```
**Action**: Show toast + optional sound.

### 6. Delivered (`topic:all:delivered`)
**Recipients**: All three apps
**Trigger**: Courier completes delivery
**Payload**:
```json
{
  "type": "delivered",
  "order_id": "uuid",
  "delivered_at": "ISO8601"
}
```
**Action**: Move to history; show "訂單已完成" toast.

### 7. Cancelled (`topic:all:cancelled`)
**Recipients**: All relevant parties
**Trigger**: Any party cancels order
**Payload**:
```json
{
  "type": "cancelled",
  "order_id": "uuid",
  "cancelled_by": "CUSTOMER|MERCHANT|COURIER|SYSTEM",
  "reason": "string",
  "cancelled_at": "ISO8601"
}
```
**Action**: Move to history with status; show cancellation reason.

## Implementation notes
- All apps subscribe to relevant topics on login; unsubscribe on logout.
- Dev mode: simulated notifications via test buttons or manual trigger.
- Prod mode: FCM tokens stored in `user_devices` table; backend sends via FCM Admin SDK.
- Toast display uses `CBToast.show()` from core_ui.
- Deep links: `clearbox://order/{order_id}` for detail navigation.

## Channel naming convention (Supabase Realtime)
- `notifications:merchant:{merchant_id}`
- `notifications:customer:{customer_id}`
- `notifications:courier:{courier_id}`

## Security
- Backend validates sender authority before publishing.
- Clients validate message schema before processing.
- No sensitive data (addresses, phone) in push payload; fetch on tap.

