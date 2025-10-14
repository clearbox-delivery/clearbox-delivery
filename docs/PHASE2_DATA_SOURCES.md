# Phase 2 Temporary Data Sources

## Merchant Sorting S (weekly meal count)

**Requirement**: [customer_app_whitepaper.md Section 4.4] R score needs weekly meal counts with P95 capping and min-max normalization.

**Temporary Solution for MVP**:
- Add `weekly_meal_count INT DEFAULT 0` to `merchants` table (migration).
- Manually seed with sample values for dev/testing.
- In production, this would be computed weekly by aggregating delivered orders.

**Migration snippet**:
```sql
ALTER TABLE merchants ADD COLUMN IF NOT EXISTS weekly_meal_count INT DEFAULT 0;
```

**Rationale**: Full aggregation requires order event tracking and scheduled jobs (post-MVP). For Phase 2 validation, a simple column with seed data suffices to verify sorting logic.

**Post-MVP**: Replace with RPC `get_merchants_with_weekly_counts()` that joins orders and computes real counts.

