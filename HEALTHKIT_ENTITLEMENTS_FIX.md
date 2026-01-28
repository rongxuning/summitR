# HealthKit Entitlements 配置指南

## 错误分析

**错误信息**：
```
Missing com.apple.developer.healthkit entitlement
```

**原因**：
应用缺少 HealthKit 的 entitlement 配置。在 iOS 中，要使用 HealthKit，不仅需要：
1. ✅ Info.plist 中的权限说明（已配置）
2. ❌ Entitlements 文件中的 HealthKit 权限（缺失）

## 解决方案

### 步骤 1：创建 Entitlements 文件

已创建 `SummitR.entitlements` 文件，包含：
- `com.apple.developer.healthkit` = true
- `com.apple.developer.healthkit.access` = 空数组（表示可以访问所有健康数据类型）

### 步骤 2：在 Xcode 中配置

1. **打开 Xcode 项目**

2. **启用 HealthKit Capability**（推荐方法）：
   - 选择项目文件（蓝色图标）
   - 选择 **Target** > **SummitR**
   - 切换到 **Signing & Capabilities** 标签页
   - 点击左上角的 **+ Capability** 按钮
   - 搜索并添加 **HealthKit**
   - Xcode 会自动：
     - 创建或更新 `.entitlements` 文件
     - 添加必要的权限配置
     - 关联到项目

3. **手动关联 Entitlements 文件**（如果自动关联失败）：
   - 选择 **Target** > **SummitR** > **Build Settings**
   - 搜索 `Code Signing Entitlements`
   - 设置值为：`SummitR/SummitR.entitlements`

### 步骤 3：验证配置

1. 检查 `.entitlements` 文件是否已添加到项目：
   - 在 Xcode 项目导航器中应该能看到 `SummitR.entitlements` 文件
   - 确保文件已添加到 Target Membership

2. 检查 Build Settings：
   - `Code Signing Entitlements` 应该指向 `SummitR/SummitR.entitlements`

3. 检查 Signing & Capabilities：
   - 应该能看到 **HealthKit** capability 已启用

### 步骤 4：清理并重新构建

1. 清理构建：Product > Clean Build Folder (⇧⌘K)
2. 删除 DerivedData（可选但推荐）
3. 重新构建：Product > Build (⌘B)
4. 在真机上重新运行

## 文件结构

```
SummitR/
├── SummitR.entitlements  ← 新创建的文件
├── Info.plist            ← 已包含权限说明
└── ...
```

## 注意事项

1. **Apple Developer 账号**：
   - 使用 HealthKit 需要有效的 Apple Developer 账号
   - 免费账号可能无法使用某些功能

2. **Provisioning Profile**：
   - 确保 Provisioning Profile 包含 HealthKit 权限
   - 在 Apple Developer 后台配置 App ID 时启用 HealthKit

3. **真机测试**：
   - HealthKit 必须在真机上测试
   - 模拟器可能无法正常工作

4. **Bundle Identifier**：
   - 确保 Bundle Identifier 在 Apple Developer 后台已启用 HealthKit

## 验证清单

- [ ] `SummitR.entitlements` 文件已创建
- [ ] 文件已添加到 Xcode 项目
- [ ] 文件已添加到 Target Membership
- [ ] Build Settings 中 `Code Signing Entitlements` 已配置
- [ ] Signing & Capabilities 中 HealthKit 已启用
- [ ] 已清理并重新构建项目
- [ ] 在真机上测试通过

## 如果仍然有问题

1. 检查 Apple Developer 后台：
   - 登录 https://developer.apple.com
   - 进入 Certificates, Identifiers & Profiles
   - 选择你的 App ID
   - 确保 HealthKit 已启用

2. 重新生成 Provisioning Profile：
   - 在 Apple Developer 后台重新生成 Provisioning Profile
   - 在 Xcode 中重新下载并配置

3. 检查签名配置：
   - 确保使用正确的 Team 和 Provisioning Profile
   - 检查证书是否有效
