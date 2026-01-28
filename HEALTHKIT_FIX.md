# HealthKit 权限配置问题修复指南

## 错误分析

**错误信息**：
```
NSHealthShareUsageDescription must be set in the app's Info.plist in order to request read authorization for the following types: HKQuantityTypeIdentifierStepCount, HKQuantityTypeIdentifierHeartRate
```

**原因**：
虽然 `Info.plist` 文件中已经添加了 `NSHealthShareUsageDescription`，但 Xcode 项目可能没有正确读取或关联该文件。

## 解决方案

### 方法一：在 Xcode 中手动添加（推荐）

1. 打开 Xcode 项目
2. 选择项目文件（蓝色图标）
3. 选择 **Target** > **SummitR**
4. 切换到 **Info** 标签页
5. 在 **Custom iOS Target Properties** 部分，点击 **+** 按钮
6. 添加以下键值对：

   **键名**：`Privacy - Health Share Usage Description`
   **类型**：String
   **值**：`需要访问您的健康数据以展示心率和步数信息`

   **键名**：`Privacy - Health Update Usage Description`
   **类型**：String
   **值**：`需要访问您的健康数据以展示心率和步数信息`

### 方法二：检查 Info.plist 文件路径

1. 在 Xcode 中选择项目文件
2. 选择 **Target** > **SummitR** > **Build Settings**
3. 搜索 `Info.plist File`
4. 确保路径为：`SummitR/Info.plist`（相对于项目根目录）

### 方法三：验证 Info.plist 格式

确保 `Info.plist` 文件格式正确，键名使用正确的格式：
- `NSHealthShareUsageDescription`（在 Info.plist 中）
- 或 `Privacy - Health Share Usage Description`（在 Xcode Info 标签页中）

## 验证步骤

1. 清理构建：Product > Clean Build Folder (⇧⌘K)
2. 重新构建：Product > Build (⌘B)
3. 在真机上运行应用
4. 检查是否还会出现权限错误

## 注意事项

- 权限说明必须用中文或英文清晰说明用途
- 如果应用需要写入健康数据，也需要 `NSHealthUpdateUsageDescription`
- 当前应用只需要读取权限，所以 `NSHealthUpdateUsageDescription` 可以设置为相同的值
