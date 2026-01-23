# 项目设置指南

## 在 Xcode 中创建项目

1. 打开 Xcode
2. 选择 "Create a new Xcode project"
3. 选择 "iOS" > "App"
4. 填写项目信息：
   - Product Name: `SummitR`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - 取消勾选 "Include Tests"（可选）
5. 选择保存位置（建议选择当前目录的父目录）
6. 创建项目后，将项目文件夹移动到当前目录

## 添加文件到项目

在 Xcode 中，有两种方式添加文件：

### 方式一：一次性添加整个文件夹（推荐）

1. 右键点击项目导航器中的项目名称
2. 选择 "Add Files to SummitR..."
3. 导航到项目目录，选择整个 `SummitR` 文件夹
4. **重要**：确保勾选以下选项：
   - ✅ "Create groups"（创建组，不是文件夹引用）
   - ✅ "Add to targets: SummitR"（添加到目标）
   - ✅ "Copy items if needed"（如果需要的话复制项目）
5. 点击 "Add"

**优点**：一次性添加所有文件，包括 `Models/` 文件夹和所有子文件夹，Xcode 会自动保持文件夹结构。

### 方式二：逐个添加文件

如果选择逐个添加文件，需要添加以下内容：

1. 右键点击项目导航器中的项目名称
2. 选择 "Add Files to SummitR..."
3. 依次选择：
   - `SummitRApp.swift`
   - `ContentView.swift`
   - `Info.plist`
   - `Models/` 文件夹（**必须添加**，包含 `ExerciseType.swift`）
   - `Views/` 文件夹（包含所有视图文件）

**为什么需要 Models 文件夹？**
- `PersonView.swift` 使用了 `ExerciseType` 和 `Gender` 枚举
- 这些枚举定义在 `Models/ExerciseType.swift` 中
- 如果不添加 Models 文件夹，代码会编译失败，提示找不到 `ExerciseType` 和 `Gender` 类型

## 配置项目设置

1. 选择项目文件（蓝色图标）
2. 在 "General" 标签页：
   - 确保 "Deployment Target" 设置为 iOS 16.0 或更高
   - Bundle Identifier: `com.yourname.SummitR`（替换为你的标识符）

3. 在 "Info" 标签页：
   - 确保 "Info.plist" 文件已正确关联

## 运行项目

1. 选择目标设备或模拟器（iPhone 14 Pro 推荐）
2. 点击运行按钮 (⌘R) 或按快捷键
3. 应用将启动并显示像素风格的 CrossFit 封面页面

## 项目结构说明

```
SummitR/
├── SummitRApp.swift          # 应用入口点
├── ContentView.swift          # 主内容视图
├── Info.plist                 # 应用配置文件
├── Models/
│   └── ExerciseType.swift     # 运动类型和性别枚举（必需）
└── Views/
    ├── HomeCoverView.swift    # 封面页面主视图
    ├── GymBackgroundView.swift # 健身房背景组件
    └── PersonView.swift       # 像素风格人物动画组件
```

**重要说明**：
- `Models/ExerciseType.swift` 定义了 `ExerciseType` 和 `Gender` 枚举
- `PersonView.swift` 依赖这些枚举类型
- 如果 Models 文件夹未添加到 Xcode 项目，会导致编译错误

## 功能说明

### 封面页面 (HomeCoverView)
- 显示多个动态的 CrossFit 运动人物
- 包含健身房背景
- 所有动画自动循环播放
- 使用 `PersonView` 组件展示不同运动

### 像素风格人物 (PersonView)
支持以下运动类型（定义在 `Models/ExerciseType.swift`）：
- **Squat**: 杠铃深蹲 - 人物上下运动
- **Deadlift**: 杠铃硬拉 - 前倾拉举动作
- **Plank**: 平板支撑 - 水平支撑姿势
- **Pushup**: 俯卧撑 - 手臂上下运动
- **Pullup**: 引体向上 - 垂直拉举动作
- **Rowing**: 划船 - 前后划船动作
- **Bike**: 单车 - 蹬车动作

### 模型定义 (Models/ExerciseType.swift)
- `ExerciseType` 枚举：定义所有运动类型
- `Gender` 枚举：定义性别（male/female）
- 这些类型被 `PersonView` 使用，是项目的核心数据模型

### 健身房背景 (GymBackgroundView)
- 像素风格的地板网格
- 墙壁纹理
- 健身器材装饰（杠铃架、杠铃片）

## 自定义

### 修改颜色
在 `PersonView.swift` 中修改各人物的颜色值：
- 男性：`Color(red: 0.2, green: 0.4, blue: 0.8)` (蓝色)
- 女性：`Color(red: 0.8, green: 0.3, blue: 0.5)` (粉色)

### 调整动画速度
在 `PersonView.swift` 中修改动画持续时间：
```swift
Animation.linear(duration: 2.0)  // 改为其他值，如 1.5 或 3.0
```

### 添加更多人物
在 `HomeCoverView.swift` 的 `HStack` 中添加更多 `PersonView` 实例：
```swift
PersonView(exercise: .squat, gender: .male, delay: 0.8)
```

### 添加新的运动类型
1. 在 `Models/ExerciseType.swift` 的 `ExerciseType` 枚举中添加新类型
2. 在 `PersonView.swift` 的 `switch` 语句中添加对应的视图组件

## 故障排除

### 如果文件无法编译

**常见错误：找不到 ExerciseType 或 Gender**
- 原因：`Models/` 文件夹未添加到 Xcode 项目
- 解决：按照上面的"添加文件到项目"步骤，确保添加 `Models/` 文件夹

**其他编译问题**：
1. 确保所有文件都已添加到 Xcode 项目中（包括 Models 文件夹）
2. 检查文件的目标成员资格（Target Membership）
   - 选中文件，在右侧检查器中查看 "Target Membership"
   - 确保 "SummitR" 已勾选
3. 清理构建文件夹：Product > Clean Build Folder (⇧⌘K)
4. 重新构建：Product > Build (⌘B)
5. 如果仍有问题，尝试删除 DerivedData：
   - Xcode > Settings > Locations > Derived Data
   - 删除项目对应的 DerivedData 文件夹

### 如果动画不流畅
1. 检查模拟器性能设置
2. 在真机上测试以获得最佳性能
3. 调整动画持续时间

### 如果背景显示不正确
1. 确保 `GymBackgroundView.swift` 已正确添加到项目
2. 检查视图层级结构
3. 验证 `ignoresSafeArea()` 修饰符已应用
