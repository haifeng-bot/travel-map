# Travel Map 项目指南

> 个人旅行地图合集。每个子项目是一次独立旅行，独立部署到 Cloudflare Pages，**永久 URL**。
> 本文档是给"未来的自己"（或任何想搭类似地图的人）写的"踩坑全记录"——按这个指南走，可以 30 分钟内从零搭出同样风格的网页。

## 📑 目录

1. [5 分钟速览](#5-分钟速览)
2. [项目理念 & 技术栈](#项目理念--技术栈)
3. [仓库结构](#仓库结构)
4. [数据模型 (核心)](#数据模型-核心)
5. [从零搭新项目 (Step-by-step)](#从零搭新项目-step-by-step)
6. [常见修改场景](#常见修改场景)
7. [关键配置常量](#关键配置常量)
8. [代码架构](#代码架构)
9. [部署前验证](#部署前验证)
10. [踩过的坑 (必读)](#踩过的坑-必读)
11. [附录：坐标查询 / 资源链接](#附录坐标查询--资源链接)

---

## 5 分钟速览

**这是什么样的项目？**
- 一个 HTML 文件（+ 一个英文版），打开就是一张 Leaflet 地图，上面画旅行线路
- 点击左侧侧边栏的"航班/高铁/轮渡"卡片 → 地图自动 zoom 到对应段
- 每条线段端点是真实的机场/高铁站/码头，不是城市中心

**技术栈**：
- **Leaflet 1.9.4**（CDN 引入）—— 地图渲染
- **OpenStreetMap** / **CartoDB Voyager** 瓦片（CDN）—— 底图
- 纯 HTML/CSS/JS，**无构建步骤**，**无依赖管理**
- 部署：**Cloudflare Pages**（监听 GitHub push 自动部署）

**为什么不存数据库？**
- 一次旅行就 10-15 站，纯 JSON-like 常量嵌入 HTML 最简单
- 改完直接 git push，CF Pages 1-2 分钟自动部署生效
- 无服务器 = 零成本，永久 URL，不依赖任何 SaaS

---

## 项目理念 & 技术栈

| 决策 | 选择 | 理由 |
|------|------|------|
| 地图库 | Leaflet | 轻量、CDN 即用、不需要 API key |
| 瓦片源 | OSM (中文版) / CartoDB Voyager (英文版) | OSM 在中国境内是中文标签，英文版用 Voyager 看英文/拼音 |
| 部署平台 | Cloudflare Pages | 免费、自动 SSL、全球 CDN、监听 Git 推送自动部署 |
| 项目结构 | 一次旅行 = 一个子文件夹 = 一个 CF Pages 项目 | URL 干净（`/map` 而非 `/Ivan-2027-Japan/map.html`）、独立部署互不干扰 |
| 数据存储 | 嵌入 HTML 的 JS 常量 | 10-15 站完全够用，无需 DB |
| 双语 | 每旅行两个文件 (`map.html` 中文 + `map_en.html` 英文) | 一致的数据，独立的翻译层 |

---

## 仓库结构

```
travel-map/                                ← GitHub: haifeng-bot/travel-map
├── README.md                              ← 本文件（项目指南）
├── .gitignore                             ← 排除临时文件
├── validate.sh                            ← 改完后的验证脚本
├── TEMPLATE/                              ← 新项目模板
│   ├── map.html.tmpl                      ← 骨架 map.html（替换占位符即可用）
│   ├── map_en.html.tmpl                   ← 骨架英文版
│   └── README.md                          ← 模板使用说明
└── Ivan-2026-China-Travel/                ← 子项目 1：中国行 (2026-09 ~ 2026-10)
    ├── map.html                           ← 中文版 (~540 行)
    ├── map_en.html                        ← 英文版 (~530 行)
    └── preview.png                        ← 缩略图
```

未来扩展：
```
└── Ivan-2027-Japan-Travel/                ← 子项目 2：日本行
    ├── map.html
    ├── map_en.html
    └── preview.png
```

---

## 数据模型 (核心)

整个项目是数据驱动的——所有要展示的内容都来自 5 个常量结构。理解了这 5 个结构，剩下就是改数据。

### 1. `CITIES` —— 城市基础信息

```js
const CITIES = {
  "SHA": {name: "上海", lat: 31.234, lon: 121.475},
  // ...
};
```

| 字段 | 必填 | 说明 |
|------|------|------|
| key | ✅ | 3-5 字母代码，**全大写**。约定：SZX=深圳，HKG=香港，MFM=澳门，BCN=Barcelona，PVG=浦东机场，TFU=天府机场... |
| name | ✅ | 显示名（中文版用中文，英文版用英文） |
| lat / lon | ✅ | 真实经纬度，**必须是城市市中心地标**，不是机场（重要！） |

### 2. `LEGS` —— 行程段（航班/高铁/轮渡）

```js
const LEGS = [
  {date: "Sep 23", from: "BCN", to: "SZX", transport: "flight",
   no: "ZH866", dep: "12:20 CEST", arr: "07:10 CST (+1d)",
   dur: "12h 50m", note: "去程 → 宝安", to_loc: "SZX_AIR"},
  // ...
];
```

| 字段 | 必填 | 说明 |
|------|------|------|
| date | ✅ | 显示用日期，格式 "Sep 23"（注意是**字符串**，不是 Date 对象） |
| from / to | ✅ | 城市代码，必须在 `CITIES` 里 |
| transport | ✅ | `flight` / `train` / `ferry` |
| no | ✅ | 航班号/车次，轮渡用 `"—"` |
| dep / arr | ✅ | 出发/到达时间字符串。跨时区加 `(+1d)` 标记 |
| dur | ✅ | 时长字符串 |
| note | - | 备注 |
| from_loc / to_loc | - | **关键**：从/到的具体交通节点，必须在 `TRANSPORT_NODES` 里。如果省略，fallback 到 from/to 城市中心 |

⚠️ **位置 (Position) 规则**：
- 长航线（>60° 经度差）不画 from_loc/to_loc（保持城市坐标）
- 国内段必须有 from_loc/to_loc，否则线段端点会落在城市 marker 上（视觉错位）

### 3. `TRANSPORT_NODES` —— 交通节点 (机场/高铁站/码头)

```js
const TRANSPORT_NODES = {
  "PVG":  {name: "浦东机场", lat: 31.143, lon: 121.805, type: "airport"},
  "SHA_HQ": {name: "上海虹桥站", lat: 31.196, lon: 121.316, type: "station"},
  "SZX_PORT": {name: "蛇口邮轮中心", lat: 22.470, lon: 113.916, type: "port"},
  // ...
};
```

| 字段 | 必填 | 说明 |
|------|------|------|
| key | ✅ | 命名约定：`{CITY}_{TYPE}`，例如 `SHA_HQ` = 上海虹桥站，`SZX_AIR` = 深圳宝安机场 |
| name | ✅ | 显示名 |
| lat / lon | ✅ | 真实精确坐标 |
| type | ✅ | `airport` / `station` / `port`（决定 marker 颜色：蓝/绿/橙） |

⚠️ **命名约定**（避免混淆）：
- `_AIR` = 机场
- `_EAST/WEST/NORTH/SOUTH/HQ` = 高铁站方位
- `_PORT` = 轮渡/客运码头
- 复合：`CKG_EAST` = 重庆东站

### 4. `HSR_ROUTES` —— 高铁实际路径 waypoints

```js
const HSR_ROUTES = {
  "SHA→WHU": [
    [31.196, 121.316],  // 上海虹桥
    [31.30,  120.59],   // 苏州
    [31.78,  119.95],   // 常州
    // ...
    [31.350, 118.386],  // 芜湖站
  ],
};
```

| 字段 | 说明 |
|------|------|
| key | 格式 `"FROM→TO"`，必须跟 LEGS 中的 from/to 完全匹配 |
| value | **有序 waypoint 数组**，第一项 = 起点站，最后一项 = 终点站 |

⚠️ **首尾 waypoint 必须跟 `TRANSPORT_NODES` 里的坐标完全一致**，否则线段端点会跟 marker 错位。

### 5. `ATTRACTIONS` —— 景点推荐 (可选)

```js
const ATTRACTIONS = {
  SHA: ["外滩", "东方明珠", "豫园", "田子坊", "上海博物馆"],
  // ...
};
```

key 是 `CITIES` 里的城市代码。停 0 天的城市也建议列，方便以后参考。

---

## 从零搭新项目 (Step-by-step)

假设你要做 `Ivan-2027-Japan-Travel`（2027 日本行）。

### Step 1：本地创建子文件夹 + 复制模板

```bash
cd /path/to/travel-map
mkdir Ivan-2027-Japan-Travel
cp TEMPLATE/map.html.tmpl Ivan-2027-Japan-Travel/map.html
cp TEMPLATE/map_en.html.tmpl Ivan-2027-Japan-Travel/map_en.html
```

### Step 2：替换占位符

模板里有 `{{CITY_NAME}}` `{{LEG_DATE}}` 等占位符，用编辑器批量替换。或者直接照着 `Ivan-2026-China-Travel/map.html` 改——后者是完整可运行的例子。

**修改清单**：
1. 替换 `<title>` (中文/英文)
2. 改 `CITIES`：日本行 = TYO, OSA, KYO, FUK, ... 
3. 改 `LEGS`：填入你的实际行程
4. 改 `TRANSPORT_NODES`：东京成田/羽田机场、新大阪站、京都站、...
5. 改 `ATTRACTIONS`：景点列表
6. 改 `ORDER`：城市顺序数组
7. 改英文版的 `TRANSPORT_LABEL`、`dateToEn` 不变
8. **改英文版的 `L.tileLayer`** 用 CartoDB Voyager

### Step 3：本地验证

```bash
./validate.sh Ivan-2027-Japan-Travel/map.html Ivan-2027-Japan-Travel/map_en.html
```

脚本会检查：
- JS 语法合法性
- LEGS 数组的 from/to/from_loc/to_loc 都在合法集合里
- 所有硬编码的 `LEGS[N]` 索引 N 都在数组范围内

### Step 4：GitHub 推送

```bash
git add Ivan-2027-Japan-Travel/
git commit -m "新增 2027 日本旅行项目"
git push
```

### Step 5：在 Cloudflare 创建新 Pages 项目

1. 打开 https://dash.cloudflare.com/ → 左侧 **Workers & Pages** → **Create**
2. **选 Pages 卡片**（不是 Workers —— 长得像但完全不同）
3. **Connect to Git** → GitHub → 选 `haifeng-bot/travel-map`
4. **Project name**：`travel-map-jp`（**全局唯一**，热门名字基本都被占）
5. **Production branch**：`main`
6. **Framework preset**：**None**
7. **Build command**：**留空**
8. **Build output directory**：`Ivan-2027-Japan-Travel`（子目录名，不带斜杠）
9. **Save and Deploy**
10. 1-2 分钟后拿到 URL：`https://travel-map-jp.pages.dev/map`

### Step 6：更新本 README

加一行到"子项目"表格。

---

## 常见修改场景

### A. 加一个城市 (例如在 HKG 后插入 MFM)

```js
// 1. CITIES 加一项
"MFM": {name: "澳门", lat: 22.197, lon: 113.543},

// 2. LEGS 拆开一条 leg 为两条
// 原来: {from: "HKG", to: "SHA", ...}
// 改为:
//   {from: "HKG", to: "MFM", ..., to_loc: "MFM_PORT"}
//   {from: "MFM", to: "SHA", ..., from_loc: "MFM_PORT"}

// 3. ORDER 数组里在 HKG 后加 "MFM"
const ORDER = ["SZX", "MFM", "HKG", "SHA", ...];

// 4. TRANSPORT_NODES 加交通节点 (MFM_PORT 等)
"MFM_PORT": {name: "外港码头", lat: 22.197, lon: 113.560, type: "port"},

// 5. ATTRACTIONS 加 MFM
MFM: ["大三巴", "妈阁庙", ...],

// 6. 如果新 leg 是 HSR，加 HSR_ROUTES key (轮渡/航班不需要)
```

### B. 改一段航班的日期 / 时长

只改 `LEGS` 数组对应那一项的字段，**不需要**改 TRANSPORT_NODES 或 HSR_ROUTES（除非换航站楼）。

### C. 修一个城市的 marker 位置 (例如从机场移到市中心)

1. 改 `CITIES[code].lat/lon` 到市中心地标坐标
2. 重新计算所有 `from_loc` / `to_loc` 引用
3. 跑 `./validate.sh` 验证

### D. 修一个交通节点的坐标 (例如某机场偏了)

1. 改 `TRANSPORT_NODES[key].lat/lon`
2. 同步 `HSR_ROUTES` 里所有用到这个节点的 waypoint (第一项或最后一项)
3. 跑 `./validate.sh`

⚠️ 坐标精度：至少到小数点后 3 位（约 100m 精度）。小数点后 4 位更佳（约 10m）。**永远不要用整数经纬度**（精度只有 ~110km，错的离谱）。

### E. 加一段新的 HSR 段

1. 在 `LEGS` 加一项，`transport: "train"`，`from_loc`/`to_loc` 指向具体站
2. 在 `TRANSPORT_NODES` 加起点站和终点站（如果还没有）
3. 在 `HSR_ROUTES` 加 key，waypoint 数组至少包含起点+终点
4. 检查 `cityToNodes` 数组（每段 leg 的 from_loc/to_loc 所在城市都要有一条灰色虚线）

### F. 加一段新的轮渡段

1. 在 `LEGS` 加一项，`transport: "ferry"`
2. `from_loc`/`to_loc` 用 `_PORT` 节点
3. **不要**加 HSR_ROUTES key（轮渡直接画直线）
4. 在 `TRANSPORT_NODES` 加两个 `_PORT` 节点

---

## 关键配置常量

```js
const SIDEBAR_WIDTH = 322;     // 侧边栏在屏幕上占的总宽度（含 12px 边距）
const MARKER_HALF = 18;        // 城市 marker 半径（含边框）
const LEFT_PADDING = 450;      // 地图 zoom 时左 padding (px)
                              // = bounds 中心在屏幕中线右侧 ~265px
```

**调整 LEFT_PADDING 的影响**：
- 太小：marker 被侧边栏挡住
- 太大：bounds 中心过度右移，地图右侧内容被裁
- 公式：bounds 中心右移量 ≈ (LEFT_PADDING + 80) / 2 px
- 推荐值范围：400-600

⚠️ **Leaflet paddingTopLeft 格式陷阱**：
- `paddingTopLeft: [x, y]` 中 x=**水平**（左 padding），y=**垂直**（顶 padding）
- **不要**写成 `[y, x]`（这是常见错误，会导致水平方向不右移）
- 当前正确写法：`paddingTopLeft: [LEFT_PADDING, 80]` = 左 450px，顶 80px

---

## 代码架构

### 渲染顺序（修改时按这个顺序读代码）

```
1. CITIES, LEGS, ATTRACTIONS, TRANSPORT_NODES, HSR_ROUTES 常量定义
2. ARC_* 预计算大圆弧 (国际航线)
3. map = L.map('map')
4. tileLayer 加载底图
5. fitBounds 初始视图
6. drawLongArc() 画 2 条洲际弧 (BCN↔SZX, PEK↔BCN)
7. IN-CHINA ROUTE POLYLINES 循环：画每段国内线
8. TRANSPORT NODE MARKERS 画所有机场/车站/码头 marker
9. cityToNodes 灰色虚线连接线
10. CITY MARKERS 画所有城市数字 marker + popup
11. BARCELONA MARKER 单独画（特殊样式）
12. SIDEBAR LEG CARDS 渲染左侧侧边栏
13. 卡片 click handler 绑定地图 zoom 逻辑
```

### 关键函数

| 函数 | 作用 |
|------|------|
| `getLocCoords(leg, side)` | 获取 leg 端点坐标（优先 from_loc/to_loc，fallback 城市） |
| `getLocName(leg, side)` | 获取端点显示名（用于 popup） |
| `drawLongArc(points, color, leg, opacity)` | 画大圆弧 polyline |
| `dateToCn(dateStr)` / `dateToEn(dateStr)` | 日期字符串格式化 |
| `attractionsHtml(code)` | 景点列表 → HTML chips |

### Sidebar 点击 → 地图 zoom 逻辑

```js
// 长航线 (>60° 经度差)：fitBounds 覆盖起点和终点
// 国内段：fitBounds fromCoords/toCoords with LEFT_PADDING
if (lonSpan > 60) {
  map.fitBounds([fromCoords, toCoords], {
    paddingTopLeft: [LEFT_PADDING, 80],
    paddingBottomRight: [80, 80],
    maxZoom: 6
  });
} else {
  map.fitBounds([fromCoords, toCoords], {
    paddingTopLeft: [LEFT_PADDING, 80],
    paddingBottomRight: [80, 80],
    maxZoom: 9
  });
}
```

---

## 部署前验证

永远在 push 之前跑：

```bash
./validate.sh Ivan-2026-China-Travel/map.html Ivan-2026-China-Travel/map_en.html
```

检查项：
1. **JS 语法**：用 `new Function(scriptContent)` 测试整段 script
2. **LEGS 硬编码索引**：`LEGS[N]` 中所有 N 都 < LEGS.length
3. **跨引用合法性**：所有 from_loc/to_loc 都在 TRANSPORT_NODES 里
4. **HSR_ROUTES 起止点**：第一项和最后项与对应 TRANSPORT_NODES 坐标一致
5. **ORDER vs LEGS 长度**：LEGS.length === ORDER.length + 1 (+ 1 是因为 LEGS[0] 是去程长航线)

也可以直接用浏览器打开本地文件预览：
```bash
# 注意：CDN 资源（Leaflet / 瓦片）需要联网，本地不需要 server
open Ivan-2026-China-Travel/map.html
```

---

## 踩过的坑 (必读)

### ❌ 1. 不要点 CF dashboard 的 Workers 卡片

入口有 **Workers** 和 **Pages** 两个很像的卡片。**永远点 Pages**。

识别方法：
| 字段 | Pages | Workers |
|------|-------|---------|
| Build command | ✅ 有 | ✅ 有 |
| Build output directory | ✅ 有 | ❌ 没有 |
| Deploy command | ❌ 没有 | ✅ 有 |
| Version command | ❌ 没有 | ✅ 有 |

看到 `Deploy command` = 进错地方了，删掉重建。

### ❌ 2. CF Pages 项目名全局唯一

`travel-map` / `map` / `china-travel` 这类直觉名字基本都被全球其他人占用了。准备接受后缀（`-1qa` / `-2jp` / 之类）。CF 系统分配的，不是手填的。

### ❌ 3. 改 LEGS 数组长度时漏改硬编码索引

如果某条 leg 之后又删了一条，原先引用 `LEGS[10]` 的代码会指向 undefined，TypeError，整个 `<script>` 崩了。

**防御**：
- 部署前跑 `./validate.sh`（会扫所有 `LEGS[N]` 字面量）
- 改数组长度时**全文搜索** `LEGS[` 找所有硬编码引用

### ❌ 4. Leaflet paddingTopLeft 是 `[x, y]` 不是 `[y, x]`

**症状**：想右移地图（避开侧边栏），但写成 `paddingTopLeft: [80, 600]` 时根本没右移
**原因**：x=**水平**（左 padding），y=**垂直**（顶 padding）
**正确**：`paddingTopLeft: [600, 80]` = 左 600px，顶 80px

### ❌ 5. 城市 marker 放在机场位置

之前所有城市 marker 都在机场（SZX=宝安，CTU=双流，PEK=首都...），用户一打开就发现"北京"在顺义区。

**规则**：`CITIES[code].lat/lon` 必须是**城市市中心地标**（天安门、钟楼、解放碑），不是机场。机场/高铁站放在 `TRANSPORT_NODES` 里。

### ❌ 6. 用高德/百度地图坐标不是真实 GPS 坐标

国内地图用 **GCJ-02（火星坐标）** 坐标系，跟国际通用的 **WGS-84** 差几百米到几公里。如果用高德坐标，地图 marker 会偏移。

**正确做法**：用 **Wikipedia 官方坐标**（WGS-84），URL 格式：
```
https://geohack.toolforge.org/geohack.php?language=zh&pagename=<站名>&params=DD_MM_SS_N_DDD_MM_SS_E_type:railwaystation
```

Wikipedia 中文版的铁路车站条目顶部都有精确坐标。

### ❌ 7. OSM 瓦片在中文版显示中文，英文用户看不懂

OSM 在中国境内默认渲染本地语言标签（"上海" 不是 "Shanghai"）。如果做双语版，英文版必须换瓦片源。

**英文版推荐**：CartoDB Voyager
```js
L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png', {
  maxZoom: 18,
  subdomains: 'abcd',
  attribution: '© OSM contributors © CARTO'
}).addTo(map);
```
所有中国城市显示为 `SHANGHAI` / `PUDONG` / `Wuhu` 等英文/拼音。

**注意**：CartoDB 免费 tier 适合个人/小流量。流量大需要申请 API key。

### ❌ 8. OpenClaw exec 环境 redact CF token

`cfut_` 开头的 token 在 exec 命令里**永远**被替换成 `***`。
- ✅ **走 Git 集成**（推荐）：git push → CF 自动部署
- ❌ 用 wrangler + token：被 redaction 堵死
- ❌ 写文件再读：inline echo 也被 redaction

任何需要 CF API token 的自动化，**走 Git 集成**最稳。

### ❌ 9. CF Pages query string 可能拿到旧版

测试新版用 `?t=12345` cache buster，可能命中旧 CDN 节点。**等几秒重试**，或用 `view-source:` 看 HTML 头确认版本。

### ❌ 10. Leaflet fitBounds 对洲际航线会缩到全世界

如果 `lonSpan > 60°`（跨洲）还用 `fitBounds`，会把整张世界地图缩进来。处理：长航线要么 `setView` 到目的地，要么 `fitBounds` 加 `maxZoom: 6` 限制。

### ⚠️ 11. HSR_ROUTES 端点必须跟 TRANSPORT_NODES 一致

如果 `TRANSPORT_NODES["CKG_NORTH"]` 是 `(29.612, 106.547)`，那 `HSR_ROUTES["CTU→CKG"]` 的最后一项**也必须是** `[29.612, 106.547]`，否则线段端点跟 marker 错位。

### ⚠️ 12. 用 `depot` 不存在的 marker icon 类型

`type` 字段必须是 `airport` / `station` / `port` 之一，否则 marker 颜色 fallback 灰色，用户看不清。

---

## 附录：坐标查询 / 资源链接

### 📍 坐标查询

| 来源 | 用途 | URL |
|------|------|-----|
| Wikipedia 中文版 | 车站/机场/景点的 WGS-84 坐标（最准） | `zh.wikipedia.org/wiki/<站名>` |
| Geohack 解析工具 | Wikipedia 坐标 URL 解析器 | `geohack.toolforge.org` |
| Bigemap | 国内坐标（GCJ-02 火星坐标，**慎用**） | `bigemap.net` |
| 高德/百度地图 | 国内坐标（**火星坐标，慎用**） | - |
| Google Earth | 全球 WGS-84 坐标 | - |

⚠️ **坐标系警告**：中国境内地图服务（高德/百度/腾讯）使用 **GCJ-02** 坐标系，Wikipedia/Google/OpenStreetMap 使用 **WGS-84**。两者差几百米到几公里。如果用了高德坐标，地图 marker 会偏移。用 Wikipedia 坐标最稳。

### 🗺️ 瓦片源

| 瓦片 | URL | 用途 |
|------|-----|------|
| OpenStreetMap | `https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png` | 中文版默认，全球语言本地化 |
| CartoDB Voyager | `https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png` | 英文版，强制英文/拼音标签 |
| CartoDB Positron | `.../rastertiles/light_all/{z}/{x}/{y}.png` | 浅色主题 |
| Stadia Maps | `https://tiles.stadiamaps.com/...` | 多种风格，需 API key |

### 🔧 调试工具

- **本地预览**：直接用 `file://` 打开 HTML（CDN 资源会从网络加载）
- **Leaflet 调试**：浏览器控制台 `map.getZoom()` / `map.getCenter()` 看当前视图
- **坐标验证**：`http://geojson.io` 把坐标贴进去看位置

### 📚 参考

- [Leaflet 文档](https://leafletjs.com/reference-1.9.4.html)
- [Cloudflare Pages 文档](https://developers.cloudflare.com/pages/)
- [OSM 中文维基 - 火车站列表](https://zh.wikipedia.org/wiki/Category:中华人民共和国铁路车站)

---

## 🆘 常见问题

**Q: 想在地图上同时显示中英文标签？**
A: 做不到（瓦片源只能选一种）。所以才做两个文件 `map.html` + `map_en.html`。

**Q: 想加新城市但没机场？**
A: 只要 `CITIES[code]` 里有 lat/lon 就行，`TRANSPORT_NODES` 可以为空。例如 "丽江" 只有高铁站和公路。

**Q: HSR 中间站要不要 marker？**
A: 当前实现**不加**（避免地图太杂）。如需要可以在 `TRANSPORT_NODES` 加，然后通过 HSR_ROUTES 自动连线。

**Q: 想加备注（酒店名、餐厅推荐）？**
A: 加在 `LEGS` 数组的 `note` 字段，会显示在 sidebar 卡片和 popup 里。

**Q: 想支持点击 marker 自动滚到对应 leg 卡片？**
A: 当前没实现。可以加：在 city marker click handler 里 `legList.children[idx].scrollIntoView()`。

---

## 📂 子项目状态

| 子项目 | CF Pages 项目 | URL | 状态 |
|--------|-------------|-----|------|
| [Ivan-2026-China-Travel](./Ivan-2026-China-Travel/) | `travel-map-1qa` | <https://travel-map-1qa.pages.dev/map> / [/map_en](https://travel-map-1qa.pages.dev/map_en) | ✅ 已上线 |

> ⚠️ **CF Pages 项目名全局唯一**，后缀是 CF 分配的，不是手填。

---

**最后**：如果你改完代码想确认效果，最快的方式是把 HTML 直接拖到浏览器（CDN 资源联网加载）。不用起 server，不用 build，看完直接 git push 就行。
