# MVP 测试计划
## 基于 docs/MVP_SPEC.md 的完整测试覆盖

### REQ-CUST (顾客端)
- ✅ REQ-CUST-ORDER-001: 顾客自订外送费 (30-5000)
  - TC-CUST-001: 有效价格测试
  - TC-CUST-002: 价格边界测试

- ✅ REQ-CUST-SORT-001: 推荐餐厅排序 (距离 + 评价)
  - TC-CUST-SORT-001: H3 k=40 范围店家筛选
  - TC-CUST-SORT-002: 排序公式验证

### REQ-MER (商家端)
- ✅ REQ-MER-CO-001: 商家确认订单 → WAITING_COURIER
  - TC-MER-CO-001: 状态转换测试

- ✅ REQ-MER-CO-002: 2秒内实时更新
  - TC-MER-E2E-001: 新订单2秒可见性

- REQ-MER-MENU-001: 菜单管理 (TODO)
  - TC-MER-MENU-001: CRUD操作

### REQ-COU (外送员端)
- ✅ REQ-COU-MATCH-003: 原子性接单 (防竞态)
  - TC-COU-ACPT-001: 竞态条件测试

- ✅ REQ-COU-SORT-001: R/T 排序
  - TC-COU-SORT-001: 优先级计算

- REQ-COU-HEAT-001: 供需热度地图 (TODO)
  - TC-COU-HEAT-001: 热度计算

### REQ-CORE (核心)
- ✅ REQ-CORE-AUDIT-001: 订单事件审计
  - TC-AUDIT-001: 事件记录完整性

- ✅ REQ-RLS-ISO-001: 数据隔离
  - TC-RLS-001~006: RLS策略测试

- REQ-CORE-RT-001: 实时更新
  - TC-RT-001: Realtime延迟测试

