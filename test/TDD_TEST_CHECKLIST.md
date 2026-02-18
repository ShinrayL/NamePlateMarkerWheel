# NamePlateMarkerWheel TDD 测试清单

## 测试文件结构

```
test/
├── Core.test.lua           # 核心逻辑测试
├── WheelUI.test.lua        # 轮盘UI测试
├── NamePlateDetector.test.lua  # 姓名板检测测试
├── Config.test.lua         # 配置管理测试
└── Integration.test.lua    # 集成测试
```

---

## 第一阶段：基础框架 (P0 核心功能)

### 1. 双击姓名板检测测试 (NamePlateDetector)

| 序号 | 测试用例 | 测试目的 | 优先级 |
|------|----------|----------|--------|
| 1.1 | `test_double_click_detected` | 验证双击动作被正确识别 | P0 |
| 1.2 | `test_single_click_ignored` | 验证单击不会触发轮盘 | P0 |
| 1.3 | `test_click_timing_threshold` | 验证双击时间间隔阈值(默认300ms) | P0 |
| 1.4 | `test_nameplate_unit_retrieved` | 验证获取姓名板关联的单位 | P0 |
| 1.5 | `test_invalid_unit_ignored` | 验证无效单位不触发轮盘 | P0 |
| 1.6 | `test_unit_exists_check` | 验证单位存在性检查 | P0 |
| 1.7 | `test_double_click_different_nameplates` | 验证不同姓名板双击不冲突 | P1 |
| 1.8 | `test_triple_click_handling` | 验证三次点击的处理逻辑 | P1 |

### 2. 径向轮盘UI测试 (WheelUI)

| 序号 | 测试用例 | 测试目的 | 优先级 |
|------|----------|----------|--------|
| 2.1 | `test_wheel_frame_created` | 验证轮盘框架被创建 | P0 |
| 2.2 | `test_wheel_shows_at_cursor` | 验证轮盘在光标位置显示 | P0 |
| 2.3 | `test_wheel_8_icons_displayed` | 验证8个标记图标正确显示 | P0 |
| 2.4 | `test_wheel_radial_layout` | 验证径向布局计算正确 | P0 |
| 2.5 | `test_wheel_icons_clickable` | 验证图标可点击 | P0 |
| 2.6 | `test_wheel_hidden_by_default` | 验证轮盘默认隐藏 | P0 |
| 2.7 | `test_wheel_closes_on_selection` | 验证选择后轮盘关闭 | P0 |
| 2.8 | `test_wheel_boundary_check` | 验证轮盘不超出屏幕边界 | P1 |
| 2.9 | `test_wheel_icon_highlight` | 验证当前标记高亮显示 | P3 |

### 3. 标记设置功能测试 (Core)

| 序号 | 测试用例 | 测试目的 | 优先级 |
|------|----------|----------|--------|
| 3.1 | `test_set_raid_target_called` | 验证调用 SetRaidTarget | P0 |
| 3.2 | `test_marker_1_skull_applied` | 验证骷髅标记(1)设置 | P0 |
| 3.3 | `test_marker_2_cross_applied` | 验证红X标记(2)设置 | P0 |
| 3.4 | `test_marker_3_square_applied` | 验证蓝方标记(3)设置 | P0 |
| 3.5 | `test_marker_4_moon_applied` | 验证绿月标记(4)设置 | P0 |
| 3.6 | `test_marker_5_triangle_applied` | 验证紫三角标记(5)设置 | P0 |
| 3.7 | `test_marker_6_diamond_applied` | 验证白菱形标记(6)设置 | P0 |
| 3.8 | `test_marker_7_circle_applied` | 验证黄圆标记(7)设置 | P0 |
| 3.9 | `test_marker_8_star_applied` | 验证橙星标记(8)设置 | P0 |
| 3.10 | `test_marker_cleared_with_zero` | 验证标记清除(index=0) | P1 |

---

## 第二阶段：交互功能 (P1)

### 4. 右键取消功能测试

| 序号 | 测试用例 | 测试目的 | 优先级 |
|------|----------|----------|--------|
| 4.1 | `test_right_click_closes_wheel` | 验证右键关闭轮盘 | P1 |
| 4.2 | `test_right_click_blank_area` | 验证点击空白处关闭轮盘 | P1 |
| 4.3 | `test_right_click_no_marker_set` | 验证右键不设置任何标记 | P1 |
| 4.4 | `test_escape_key_closes_wheel` | 验证ESC键关闭轮盘 | P1 |

### 5. 标记移除功能测试

| 序号 | 测试用例 | 测试目的 | 优先级 |
|------|----------|----------|--------|
| 5.1 | `test_center_button_clears_marker` | 验证中心按钮清除标记 | P1 |
| 5.2 | `test_clear_marker_api_called` | 验证清除时调用SetRaidTarget(unit, 0) | P1 |
| 5.3 | `test_current_marker_displayed` | 验证当前标记在中心显示 | P3 |

---

## 第三阶段：配置功能 (P2)

### 6. 配置管理测试 (Config)

| 序号 | 测试用例 | 测试目的 | 优先级 |
|------|----------|----------|--------|
| 6.1 | `test_config_defaults_loaded` | 验证默认配置加载 | P2 |
| 6.2 | `test_config_saved_to_savedVariables` | 验证配置保存 | P2 |
| 6.3 | `test_config_loaded_from_savedVariables` | 验证配置读取 | P2 |
| 6.4 | `test_wheel_radius_configurable` | 验证轮盘半径可配置 | P2 |
| 6.5 | `test_wheel_opacity_configurable` | 验证透明度可配置 | P2 |
| 6.6 | `test_wheel_scale_configurable` | 验证缩放比例可配置 | P2 |
| 6.7 | `test_double_click_interval_configurable` | 验证双击间隔可配置 | P2 |
| 6.8 | `test_config_reset_to_default` | 验证配置重置功能 | P2 |
| 6.9 | `test_invalid_config_handled` | 验证无效配置处理 | P2 |

### 7. 快捷键支持测试

| 序号 | 测试用例 | 测试目的 | 优先级 |
|------|----------|----------|--------|
| 7.1 | `test_keybinding_registered` | 验证按键绑定注册 | P2 |
| 7.2 | `test_keybinding_triggers_wheel` | 验证按键触发轮盘 | P2 |
| 7.3 | `test_keybinding_customizable` | 验证按键可自定义 | P2 |
| 7.4 | `test_slash_command_works` | 验证 /np 命令可用 | P2 |
| 7.5 | `test_slash_command_opens_config` | 验证 /np 打开配置界面 | P2 |

---

## 第四阶段：高级功能 (P3)

### 8. 标记同步显示测试

| 序号 | 测试用例 | 测试目的 | 优先级 |
|------|----------|----------|--------|
| 8.1 | `test_current_marker_highlighted` | 验证当前标记高亮 | P3 |
| 8.2 | `test_marker_change_event_handled` | 验证标记变更事件处理 | P3 |
| 8.3 | `test_wheel_updates_on_marker_change` | 验证轮盘随标记更新 | P3 |
| 8.4 | `test_no_marker_no_highlight` | 验证无标记时不高亮 | P3 |

---

## 第五阶段：边界情况和错误处理

### 9. 边界情况测试

| 序号 | 测试用例 | 测试目的 | 优先级 |
|------|----------|----------|--------|
| 9.1 | `test_wheel_position_screen_edge` | 验证屏幕边缘位置处理 | P1 |
| 9.2 | `test_combat_state_handling` | 验证战斗状态处理 | P1 |
| 9.3 | `test_unit_dead_or_ghost` | 验证死亡/幽灵单位处理 | P2 |
| 9.4 | `test_unit_out_of_range` | 验证超出范围单位处理 | P2 |
| 9.5 | `test_multiple_nameplates_overlap` | 验证重叠姓名板处理 | P2 |
| 9.6 | `test_rapid_double_clicks` | 验证快速双击处理 | P2 |
| 9.7 | `test_addon_reload_mid_interaction` | 验证重载界面中断处理 | P3 |
| 9.8 | `test_nameplate_removed_mid_click` | 验证姓名板移除中断处理 | P3 |

### 10. API安全性和兼容性测试

| 序号 | 测试用例 | 测试目的 | 优先级 |
|------|----------|----------|--------|
| 10.1 | `test_setraidtarget_is_secure` | 验证SetRaidTarget安全性 | P0 |
| 10.2 | `test_api_compatibility_wow_12_0` | 验证12.0版本API兼容 | P0 |
| 10.3 | `test_protected_function_check` | 验证受保护函数检查 | P1 |
| 10.4 | `test_taint_prevention` | 验证污染预防 | P1 |

---

## 测试执行顺序

```
Phase 1: 基础核心功能 (P0)
├── 1. 双击检测测试 → 2. 轮盘UI测试 → 3. 标记设置测试

Phase 2: 交互增强 (P1)
├── 4. 右键取消测试 → 5. 标记移除测试 → 9. 边界情况测试(部分)

Phase 3: 配置系统 (P2)
├── 6. 配置管理测试 → 7. 快捷键测试

Phase 4: 高级功能 (P3)
├── 8. 标记同步测试 → 9. 剩余边界情况测试

Phase 5: 集成和兼容性
├── 10. API安全测试 → Integration测试
```

---

## 测试数据准备

### 模拟对象 (Mocks)

```lua
-- 需要Mock的WoW API
MockSetRaidTarget(unit, index)
MockGetUnitName(unit)
MockUnitExists(unit)
MockC_NamePlate.GetNamePlates()
MockCreateFrame(type, name, parent, template)
MockGetCursorPosition()
MockGetScreenWidth()
MockGetScreenHeight()

-- 需要Mock的游戏状态
MockInCombatState
MockUnitHealth
MockPlayerPermissions(raidleader/assistant)
```

### 测试辅助函数

```lua
-- 模拟双击事件
function SimulateDoubleClick(nameplate, deltaTime)

-- 模拟右键点击
function SimulateRightClick(frame)

-- 验证轮盘位置
function AssertWheelPosition(expectedX, expectedY)

-- 验证标记设置
function AssertMarkerSet(unit, markerIndex)
```

---

## 通过标准

| 阶段 | 测试数量 | 最低通过率 | 备注 |
|------|----------|------------|------|
| Phase 1 (P0) | 17 | 100% | 核心功能必须全部通过 |
| Phase 2 (P1) | 8 | 95% | 交互功能允许1个失败 |
| Phase 3 (P2) | 14 | 90% | 配置功能允许1-2个失败 |
| Phase 4 (P3) | 7 | 85% | 高级功能可有弹性 |
| Phase 5 | 8 | 100% | API安全必须全部通过 |

---

## 测试运行命令

```bash
# 运行所有测试
/wowtest run all

# 运行特定模块
/wowtest run NamePlateDetector
/wowtest run WheelUI
/wowtest run Core

# 运行特定阶段
/wowtest run phase1
/wowtest run phase2

# 生成测试报告
/wowtest report --html
/wowtest report --coverage
```

---

## 注意事项

1. **WoW API限制**: 12.0版本对插件API有限制，需确保使用安全API
2. **SetRaidTarget是安全API**: 可直接调用，不受战斗限制
3. **姓名板事件**: 使用安全模板监听事件，不直接修改姓名板
4. **测试环境**: 使用WoW Lua测试框架或模拟环境
5. **持续集成**: 建议每次提交前运行Phase 1测试
