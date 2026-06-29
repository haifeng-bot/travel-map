# 模板使用说明

这个文件夹包含新旅行项目的骨架 HTML 文件，填充占位符后用就可以了。

## 快速开始

```bash
cp TEMPLATE/map.html.tmpl Ivan-2027-Japan-Travel/map.html
cp TEMPLATE/map_en.html.tmpl Ivan-2027-Japan-Travel/map_en.html
```

## 需要替换的占位符

完整的替换步骤见根目录 `README.md` 的「从零搭新项目」章节。

| 占位符 | 替换为（示例） |
|--------|--------------|
| `{{TRIP_TITLE_CN}}` | 日本行 2027 |
| `{{TRIP_DATES_CN}}` | 2027 年春季·13 站·16 天 |
| `{{NUM_STOPS}}` | 13 |
| `{{NUM_DAYS}}` | 16 |
| `{{ORIGIN_CODE}}` | TYO |
| `{{CITIES_JSON}}` | 你的城市数据 |
| `{{LEGS_JSON}}` | 你的行程段数据 |
| `{{TRANSPORT_NODES_JSON}}` | 你的交通节点数据 |
| `{{HSR_ROUTES_JSON}}` | 你的高铁路径或 `{}` |
| `{{ORDER_JSON}}` | 城市顺序数组 |
| `{{ATTRACTIONS_JSON}}` | 景点推荐或 `{}` |
| `{{CITY_TO_NODES_JSON}}` | 城市→节点连接数组 |
| `{{ARC_OUTBOUND}}` | 去程洲际弧坐标数组 |
| `{{ARC_RETURN}}` | 回程洲际弧坐标数组 |

## 英文版额外注意

英文版 `map_en.html.tmpl` 有两个额外需要改的地方：

1. **tileLayer**：把 OSM 注释掉，改 CartoDB Voyager（否则中国城市显示中文）
2. **所有 `name` 字段**：城市名和节点名翻译成英文

## 参考实现

`Ivan-2026-China-Travel/map.html` 是完整的可用实现，不熟时可以对照参考。
