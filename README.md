# travel-map

个人旅行地图合集。每个子项目是一次独立旅行，独立部署到 Cloudflare Pages。

## 子项目 & 部署状态

| 子项目 | CF Pages 项目 | URL | 状态 |
|--------|-------------|-----|------|
| [Ivan-2026-China-Travel](./Ivan-2026-China-Travel/) | `travel-map-1qa` | <https://travel-map-1qa.pages.dev/map> | ✅ 已上线 |

> ⚠️ **CF Pages 项目名是全局唯一的**，所以名字带后缀（`-1qa` 是因为 `travel-map` 早被全球其他人占了）。后缀是 CF 系统分配的，不是手填。

---

## 改版流程（已有项目）

```bash
# 1. 编辑 Ivan-2026-China-Travel/map.html 或 map_en.html
# 2. 提交并推送
cd travel_map/
git add .
git commit -m "更新景点推荐"
git push
# 3. Cloudflare Pages 监听到 push → 自动部署 → 1-2 分钟生效
```

---

## 添加新旅行子项目（**重要**：每旅行 = 独立 CF Pages 项目）

**为什么每旅行独立一个 CF Pages 项目**：

- URL 干净：`https://travel-map-jp.pages.dev/map` vs `https://travel-map-1qa.pages.dev/Ivan-2027-Japan-Travel/map.html`
- 部署独立：改日本项目不会触发中国项目 rebuild
- 失败隔离：某个项目构建失败不影响其他项目

### Step 1：本地加新子文件夹

```bash
cd travel_map/
mkdir Ivan-2027-Japan-Travel
# 把 map.html / map_en.html / preview.png 等文件放进去
# 模板可以参考 Ivan-2026-China-Travel/
```

### Step 2：提交到 GitHub

```bash
git add Ivan-2027-Japan-Travel/
git commit -m "新增 2027 日本旅行项目"
git push
```

### Step 3：在 CF dashboard 创建对应 Pages 项目（约 3 分钟）

1. 打开 https://dash.cloudflare.com/ → 左侧 **Workers & Pages** → **Create application**
2. **重要：选 **Pages** 卡片**（不是 Workers —— 长得像，但行为完全不同）
3. 选 **Connect to Git** → GitHub → 选 **`haifeng-bot/travel-map`**
4. **Project name**：`travel-map-jp`（或别的，全局唯一，自己想一个）
5. **Production branch**：`main`
6. **Framework preset**：**None**
7. **Build command**：**留空**
8. **Build output directory**：`Ivan-2027-Japan-Travel`（**注意是子目录名，不带斜杠**）
9. **Save and Deploy**
10. 等 1-2 分钟，拿到 URL：`https://travel-map-jp.pages.dev/map`

### Step 4：更新本 README 的"子项目"表格

加一行记录新项目的 URL，方便以后找。

---

## 仓库结构

```
travel-map/                       ← 这个仓库的根
├── README.md                     ← 本文件
├── .gitignore                    ← 排除临时文件
└── Ivan-2026-China-Travel/       ← 子项目 1（2026 中国行）
    ├── map.html                  ← 中文版
    ├── map_en.html               ← 英文版
    ├── preview.png
    └── serve.py                  ← 历史脚本（trycloudflare 临时部署用，现已废弃）
```

未来会加：
```
└── Ivan-2027-Japan-Travel/       ← 子项目 2（2027 日本行）
```

---

## 踩过的坑（避免重复踩）

### ❌ 不要在 CF dashboard 点 "Workers" 卡片

入口处有 Workers 和 Pages 两个很像的卡片。**永远点 Pages**。Workers 会让你填 `npx wrangler deploy`，然后报"找不到静态文件目录"。识别方法：

| 字段 | Pages | Workers |
|------|-------|---------|
| Build command | ✅ 有 | ✅ 有 |
| Build output directory | ✅ 有 | ❌ 没有 |
| Deploy command | ❌ 没有 | ✅ 有 |
| Version command | ❌ 没有 | ✅ 有 |

看到 `Deploy command` = 你进错地方了。

### ❌ 不要在项目里用 `*.html` URL 分享

CF Pages 会把 `/map.html` 308 重定向到 `/map`，浏览器能处理但少数情况会卡。直接用**不带后缀的版本**：`https://xxx.pages.dev/map`。

### ❌ 不要假设 CF Pages 项目名是账户内唯一

它是**全局唯一**。`travel-map` / `map` / `china-travel` 这些直觉名字基本都被占了，准备好接受后缀（`-1qa` / `-2jp` 之类）。
