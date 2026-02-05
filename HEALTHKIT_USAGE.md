# iOS HealthKit 使用文档

本文档说明 HealthKit 提供的基础数据类型、可推导的衍生数据及常用推导公式，便于在 SummitR 等应用中正确请求权限、读取数据并计算衍生指标。

---

## 一、HealthKit 基础数据类型概览

HealthKit 通过以下对象类型提供健康与健身数据：

| 类型 | 说明 | 典型用途 |
|------|------|----------|
| **HKQuantityType** | 数值型（心率、步数、距离、能量等） | 心率、步数、卡路里、体重、血糖等 |
| **HKCategoryType** | 分类型（睡眠、站立、月经等） | 睡眠分析、站立小时、月经、正念等 |
| **HKCharacteristicType** | 用户特征（出生日期、性别、血型等） | 一次性或很少变更的生理特征 |
| **HKWorkoutType** | 锻炼记录 | 体能训练、路线、时长、消耗等 |
| **HKSeriesType** | 序列型（路线、心电图等） | 健身路线、ECG 等 |

以下按「基础数据」与「可推导数据」分类，并给出常用推导公式。

---

## 二、基础数据：HealthKit 直接提供的数据

### 2.1 身体测量（Body Measurements）

| 标识符 | 中文名 | 单位 | 说明 |
|--------|--------|------|------|
| `height` | 身高 | m, cm, in | 离散型 |
| `bodyMass` | 体重 | kg, lb | 离散型 |
| `bodyMassIndex` | 体重指数 BMI | 标量 | 可写入，也可由身高+体重推导 |
| `bodyFatPercentage` | 体脂率 | % (0–1) | 离散型 |
| `leanBodyMass` | 去脂体重 | kg | 离散型 |
| `waistCircumference` | 腰围 | m, cm | 离散型 |

### 2.2 活动与运动（Activity & Fitness）

| 标识符 | 中文名 | 单位 | 说明 |
|--------|--------|------|------|
| `stepCount` | 步数 | count | 累计型 |
| `distanceWalkingRunning` | 步行+跑步距离 | m, km, mi | 累计型 |
| `distanceCycling` | 骑行距离 | m, km | 累计型 |
| `distanceWheelchair` | 轮椅距离 | m, km | 累计型 |
| `distanceSwimming` | 游泳距离 | m, km | 累计型 |
| `swimmingStrokeCount` | 游泳划水次数 | count | 累计型 |
| `flightsClimbed` | 爬楼层数 | count | 累计型 |
| `basalEnergyBurned` | 静息能量消耗 | kcal, kJ | 累计型 |
| `activeEnergyBurned` | 活动能量消耗 | kcal, kJ | 累计型 |
| `appleExerciseTime` | 锻炼时长 | min | 累计型 |
| `pushCount` | 轮椅推次 | count | 累计型 |
| `vo2Max` | 最大摄氧量 | mL/(kg·min) | 离散型（多为设备/算法估算） |
| `distanceDownhillSnowSports` | 雪上滑行距离 | m, km | 累计型 |
| `nikeFuel` | Nike Fuel | count | 累计型（历史） |

### 2.3 心率与呼吸（Heart & Respiratory）

| 标识符 | 中文名 | 单位 | 说明 |
|--------|--------|------|------|
| `heartRate` | 心率 | count/min (bpm) | 离散型 |
| `restingHeartRate` | 静息心率 | count/min | 离散型 |
| `walkingHeartRateAverage` | 步行平均心率 | count/min | 离散型 |
| `heartRateVariabilitySDNN` | 心率变异性 SDNN | ms | 离散型 |
| `respiratoryRate` | 呼吸频率 | count/min | 离散型 |
| `oxygenSaturation` | 血氧饱和度 | % (0–1) | 离散型 |

### 2.4 生命体征与血液（Vital Signs & Blood）

| 标识符 | 中文名 | 单位 | 说明 |
|--------|--------|------|------|
| `bodyTemperature` | 体温 | °C, °F | 离散型 |
| `basalBodyTemperature` | 基础体温 | °C | 离散型 |
| `bloodPressureSystolic` | 收缩压 | mmHg | 离散型 |
| `bloodPressureDiastolic` | 舒张压 | mmHg | 离散型 |
| `bloodGlucose` | 血糖 | mg/dL, mmol/L | 离散型 |
| `bloodAlcoholContent` | 血液酒精浓度 | % (0–1) | 离散型 |
| `peripheralPerfusionIndex` | 外周灌注指数 | % (0–1) | 离散型 |
| `electrodermalActivity` | 皮肤电活动 | μS | 离散型 |

### 2.5 呼吸功能与用药（Respiratory & Medication）

| 标识符 | 中文名 | 单位 | 说明 |
|--------|--------|------|------|
| `forcedVitalCapacity` | 用力肺活量 | L | 离散型 |
| `forcedExpiratoryVolume1` | 第一秒用力呼气量 | L | 离散型 |
| `peakExpiratoryFlowRate` | 峰流速 | L/min | 离散型 |
| `inhalerUsage` | 吸入器使用 | count | 累计型 |
| `insulinDelivery` | 胰岛素输注 | IU | 累计型 |

### 2.6 营养（Nutrition）

| 标识符 | 中文名 | 单位 | 说明 |
|--------|--------|------|------|
| `dietaryEnergyConsumed` | 膳食能量 | kcal, kJ | 累计型 |
| `dietaryCarbohydrates` | 碳水化合物 | g | 累计型 |
| `dietaryProtein` | 蛋白质 | g | 累计型 |
| `dietaryFatTotal` | 总脂肪 | g | 累计型 |
| `dietaryFatSaturated` | 饱和脂肪 | g | 累计型 |
| `dietaryFatMonounsaturated` | 单不饱和脂肪 | g | 累计型 |
| `dietaryFatPolyunsaturated` | 多不饱和脂肪 | g | 累计型 |
| `dietaryCholesterol` | 胆固醇 | mg | 累计型 |
| `dietarySodium` | 钠 | g, mg | 累计型 |
| `dietaryFiber` | 膳食纤维 | g | 累计型 |
| `dietarySugar` | 糖 | g | 累计型 |
| `dietaryWater` | 饮水量 | mL, L | 累计型 |
| `dietaryCaffeine` | 咖啡因 | mg | 累计型 |
| `dietaryVitaminA/B6/B12/C/D/E/K` | 维生素 | 视类型 | 累计型 |
| `dietaryCalcium` / `dietaryIron` / … | 矿物质等 | g, mg | 累计型 |

### 2.7 其他数量类型

| 标识符 | 中文名 | 说明 |
|--------|--------|------|
| `numberOfTimesFallen` | 跌倒次数 | 累计型 |
| `uvExposure` | 紫外线暴露 | 离散型 |

### 2.8 分类类型（HKCategoryType）

| 标识符 | 中文名 | 说明 |
|--------|--------|------|
| `sleepAnalysis` | 睡眠分析 | 入睡/醒来/阶段等 |
| `appleStandHour` | 站立小时 | 每小时是否站立 |
| `highHeartRateEvent` | 高心率事件 | 事件型 |
| `lowHeartRateEvent` | 低心率事件 | 事件型 |
| `irregularHeartRhythmEvent` | 心律不齐事件 | 事件型 |
| `mindfulSession` | 正念时段 | 时段 |
| `menstrualFlow` | 月经 | 流量等级 |
| `cervicalMucusQuality` | 宫颈粘液 | 质量等级 |
| `ovulationTestResult` | 排卵试纸 | 结果 |
| `sexualActivity` | 性生活 | 是/否 |
| `intermenstrualBleeding` | 经间期出血 | 是/否 |
| `audioExposureEvent` | 音频暴露事件 | 事件型 |

### 2.9 用户特征（HKCharacteristicType）

| 标识符 | 中文名 | 说明 |
|--------|--------|------|
| `biologicalSex` | 生理性别 | 枚举 |
| `bloodType` | 血型 | 枚举 |
| `dateOfBirth` | 出生日期 | 日期 |
| `skinType` | 皮肤类型 | 枚举（需权限） |
| `wheelchairUse` | 是否使用轮椅 | 是/否 |
| `fitzpatrickSkinType` | 菲茨帕特里克皮肤类型 | 枚举 |

### 2.10 锻炼与序列

| 类型 | 说明 |
|------|------|
| **HKWorkoutType** | 单次锻炼（类型、开始/结束时间、时长、距离、活动能量等） |
| **HKSeriesType.workoutRoute()** | 与某次锻炼关联的路线坐标序列 |

---

## 三、可推导数据及推导公式

以下数据**并非** HealthKit 直接提供的独立类型，而是由上述基础数据计算得到。公式供应用内实现参考，具体系数可根据业务与文献调整。

### 3.1 身体成分与代谢

#### 体重指数 BMI

**公式：**

\[
\text{BMI} = \frac{\text{体重 (kg)}}{\text{身高 (m)}^2}
\]

**依赖：** `height`、`bodyMass`

**Swift 示例：**

```swift
// 身高单位：米；体重单位：千克
let bmi = bodyMassKg / (heightM * heightM)
```

---

#### 基础代谢率 BMR（Mifflin–St Jeor，推荐）

**公式：**

- 男性：\(\text{BMR} = 10 \times w + 6.25 \times h - 5 \times a + 5\)
- 女性：\(\text{BMR} = 10 \times w + 6.25 \times h - 5 \times a - 161\)

其中：\(w\) = 体重 (kg)，\(h\) = 身高 (cm)，\(a\) = 年龄（岁）。

**依赖：** `bodyMass`、`height`、出生日期（推算年龄）、`biologicalSex`

---

#### 每日总消耗 TDEE

**公式：**

\[
\text{TDEE} = \text{BMR} \times \text{活动系数}
\]

**活动系数：**

| 活动水平 | 系数 |
|----------|------|
| 久坐（几乎不运动） | 1.2 |
| 轻度（1–3 次/周） | 1.375 |
| 中度（3–5 次/周） | 1.55 |
| 高度（5–6 次/周） | 1.725 |
| 极高（几乎每天） | 1.9 |

**依赖：** BMR、`activeEnergyBurned` / `appleExerciseTime`（用于估算活动水平）

---

#### 去脂体重 FFM（由体脂率反推）

**公式：**

\[
\text{FFM (kg)} = \text{体重 (kg)} \times (1 - \text{体脂率})
\]

**依赖：** `bodyMass`、`bodyFatPercentage`

---

### 3.2 活动与能量

#### 从步数估算步行/跑步距离

**公式：**

\[
\text{距离 (m)} \approx \text{步数} \times \text{步长 (m)}
\]

常用步长估算：身高 (m) × 0.415 或 0.45–0.5 m（需按用户校准）。

**依赖：** `stepCount`、`height`（可选）

---

#### 从步数估算活动能量（经验公式）

**公式（示例）：**

\[
\text{活动能量 (kcal)} \approx \text{步数} \times \frac{\text{体重 (kg)}}{100} \times k
\]

\(k\) 约 0.04–0.05（慢走）到 0.06–0.07（快走/跑步），需根据速度或设备数据校准。

**依赖：** `stepCount`、`bodyMass`；若有 `distanceWalkingRunning` 可结合距离与时间得到强度再算能量。

---

#### MET 与能量换算

**关系：**

- 1 MET ≈ 3.5 mL/(kg·min) 耗氧量
- 1 MET ≈ 1 kcal/(kg·h)

**公式：**

\[
\text{能量 (kcal/min)} = \frac{\text{MET} \times 3.5 \times \text{体重 (kg)}}{200}
\]

**依赖：** 活动 MET（查表或设备）、`bodyMass`

---

#### 台阶/爬楼能量（ACSM 台阶公式简化）

**公式：**

\[
\text{VO}_2 \text{ (mL/(kg·min))} = (0.2 \times \text{步频}) + (1.33 \times 1.8 \times \text{台阶高 (m)} \times \text{步频}) + 3.5
\]

步频单位：步/分钟；再通过 MET/能量公式转为 kcal。

**依赖：** `flightsClimbed`（需假设每层高度与步频）、`bodyMass`、`height`

---

### 3.3 心率相关

#### 运动时心率储备百分比 %HRR

**公式：**

\[
\%\text{HRR} = \frac{\text{当前心率} - \text{静息心率}}{\text{最大心率} - \text{静息心率}} \times 100\%
\]

**依赖：** `heartRate`、`restingHeartRate`、最大心率（可用 220−年龄估算）

---

#### 最大心率（年龄估算）

**公式：**

\[
\text{HR}_{\max} \approx 220 - \text{年龄}
\]

（或 Tanaka：208 − 0.7×年龄 等，可替换。）

**依赖：** 出生日期（年龄）

---

#### 卡氏公式：目标心率区间

**公式：**

\[
\text{目标心率} = ((\text{HR}_{\max} - \text{HR}_{\text{rest}}) \times \text{强度\%}) + \text{HR}_{\text{rest}}
\]

强度% 如 0.6–0.8 对应 60–80% 强度。

**依赖：** `restingHeartRate`、年龄（HR_max）、目标强度

---

### 3.4 营养与能量平衡

#### 能量平衡（日）

**公式：**

\[
\text{能量平衡} = \text{dietaryEnergyConsumed} - \text{TDEE}
\]

（或 TDEE 用 BMR + `activeEnergyBurned` + 其他成分估算。）

**依赖：** `dietaryEnergyConsumed`、`basalEnergyBurned`、`activeEnergyBurned` 或 TDEE

---

#### 三大营养素供能占比

**公式：**

- 碳水化合物：\(\text{碳水 (g)} \times 4 \text{ kcal/g}\)
- 蛋白质：\(\text{蛋白质 (g)} \times 4 \text{ kcal/g}\)
- 脂肪：\(\text{脂肪 (g)} \times 9 \text{ kcal/g}\)

\[
\text{某营养素占比} = \frac{\text{该营养素供能 (kcal)}}{\text{dietaryEnergyConsumed}} \times 100\%
\]

**依赖：** `dietaryEnergyConsumed`、`dietaryCarbohydrates`、`dietaryProtein`、`dietaryFatTotal`

---

### 3.5 血压与血糖

#### 平均动脉压 MAP

**公式：**

\[
\text{MAP} \approx \text{舒张压} + \frac{1}{3}(\text{收缩压} - \text{舒张压})
\]

**依赖：** `bloodPressureSystolic`、`bloodPressureDiastolic`

---

#### 血糖单位换算

**公式：**

\[
\text{mmol/L} = \frac{\text{mg/dL}}{18.018}
\]

**依赖：** `bloodGlucose`（注意 HealthKit 中样本单位）

---

## 四、在 SummitR 中的使用建议

1. **权限**：在 `HealthKitManager` 的 `readTypes` 中只请求实际用到的类型（如当前已包含心率、步数、锻炼、路线）。
2. **衍生数据**：BMI、BMR、TDEE、从步数估算距离/能量等可在应用内用上述公式计算，无需写入 HealthKit（除非希望把 BMI 等写回健康 app）。
3. **单位**：从 HealthKit 读取时统一用 `HKUnit` 转换到 App 使用的单位（如 kg、m、bpm、kcal），再代入公式。
4. **日期与统计**：日/周/月统计用 `HKStatisticsQuery`、`HKStatisticsCollectionQuery` 或按时间谓词查询样本后自行聚合。

---

## 五、参考

- [Apple – HealthKit](https://developer.apple.com/documentation/healthkit)
- [HKQuantityTypeIdentifier](https://developer.apple.com/documentation/healthkit/hkquantitytypeidentifier)
- [HKCategoryTypeIdentifier](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier)
- ACSM 代谢公式、Mifflin–St Jeor BMR、Compendium of Physical Activities (MET) 等运动与营养学文献。
