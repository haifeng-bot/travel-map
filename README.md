# travel-map

个人旅行地图合集。每个子项目是一次独立旅行。

## 子项目

- **[Ivan-2026-China-Travel](./Ivan-2026-China-Travel/)** — 2026 年 9-10 月中国旅行（深圳 → 澳门 → 香港 → 上海 → 杭州 → 芜湖 → 成都 → 重庆 → 张家界 → 西安 → 北京）

## 部署

每个子项目独立部署到 [Cloudflare Pages](https://pages.cloudflare.com/)（免费档），通过 GitHub 集成自动构建。

部署后访问：
- Ivan-2026-China-Travel: <https://ivan-2026-china-travel.pages.dev/map.html>

## 改版流程

```bash
# 1. 编辑 HTML（map.html / map_en.html）
# 2. 提交并推送
git add .
git commit -m "更新景点推荐"
git push
# 3. Cloudflare Pages 自动部署，1 分钟内生效
```

## 添加新的旅行子项目

```bash
mkdir Ivan-2027-Japan-Travel
# 把对应 HTML 文件放进去
git add Ivan-2027-Japan-Travel/
git commit -m "新增 2027 日本旅行项目"
git push
# 然后去 CF Pages 创建一个新项目，build output 指向对应子目录
```
