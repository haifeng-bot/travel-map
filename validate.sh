#!/usr/bin/env bash
# validate.sh - 部署前验证脚本
# 用法: ./validate.sh <map.html> [<map_en.html> ...]
#
# 检查项:
#   1. JS 语法合法性 (node -c)
#   2. 所有硬编码的 LEGS[N] 索引 N 都在数组范围内
#   3. from_loc / to_loc 引用的 key 都在 TRANSPORT_NODES/CITIES 里
#   4. HSR_ROUTES key 格式正确 (FROM→TO)
#   5. LEGS 数量 = ORDER 数量 + 1
#   6. cityToNodes 引用的 city 和 node 都存在

set -e

if [ $# -eq 0 ]; then
  echo "用法: $0 <map.html> [<map_en.html> ...]"
  echo ""
  echo "示例: $0 Ivan-2026-China-Travel/map.html Ivan-2026-China-Travel/map_en.html"
  exit 1
fi

FAILED=0

check_file() {
  local FILE=$1
  echo ""
  echo "=== $FILE ==="
  if [ ! -f "$FILE" ]; then
    echo "  ✗ 文件不存在"
    FAILED=1
    return
  fi

  # Extract script content to temp file
  local TMP=$(mktemp --suffix=.js)
  node -e "
const fs = require('fs');
const lines = fs.readFileSync('$FILE','utf8').split('\n');
let inScript = false;
let content = '';
for (const line of lines) {
  if (line.includes('<script>')) inScript = true;
  else if (line.includes('</script>') && inScript) inScript = false;
  else if (inScript) content += line + '\n';
}
fs.writeFileSync('$TMP', content);
" 2>/dev/null

  # 1. JS syntax check
  if node -c "$TMP" 2>/dev/null >/dev/null; then
    echo "  ✓ JS 语法合法"
  else
    local ERR=$(node -c "$TMP" 2>&1 | head -3)
    echo "  ✗ JS 语法错误:"
    echo "    $ERR"
    rm -f "$TMP"
    FAILED=1
    return
  fi

  # 2-6: All checks in one Node.js run
  node -e "
const fs = require('fs');
const script = fs.readFileSync('$TMP','utf8');
const errors = [];

// Helper: extract const array/object
function extractConst(name) {
  const re = new RegExp('const ' + name + ' = (.+?);', 's');
  const m = script.match(re);
  return m ? m[1] : null;
}

function extractObj(name) {
  const raw = extractConst(name);
  if (!raw) return null;
  try {
    return eval('({' + raw.slice(1, -1).replace(/(\\w+):/g, '\"\$1\":') + '})');
  } catch { return null; }
}

// Extract LEGS as array of strings
const legsRaw = extractConst('LEGS');
const legsCount = legsRaw && legsRaw !== ''
  ? (legsRaw.match(/\\{/g) || []).length
  : 0;

// Extract TRANSPORT_NODES keys
const tnRaw = extractConst('TRANSPORT_NODES');
const tnKeys = tnRaw
  ? [...tnRaw.matchAll(/\"([A-Z_0-9]+)\":\\s*\\{/g)].map(m => m[1])
  : [];

// Extract CITIES keys
const citiesRaw = extractConst('CITIES');
const cityKeys = citiesRaw
  ? [...citiesRaw.matchAll(/\"([A-Z]+)\":\\s*\\{/g)].map(m => m[1])
  : [];

// 2. Hard-coded LEGS[N] index
const legRefs = [...script.matchAll(/LEGS\\[(\\d+)\\]/g)].map(m => parseInt(m[1]));
if (legRefs.length === 0) {
  // ok
} else {
  const maxRef = Math.max(...legRefs);
  if (maxRef < legsCount) {
    // ok
  } else {
    errors.push('硬编码 LEGS[' + maxRef + '] 越界 (LEGS.length=' + legsCount + ')');
  }
}

// 3. from_loc / to_loc references
const locRefs = [...script.matchAll(/\"(from_loc|to_loc)\":\\s*\"([^\"]+)\"/g)].map(m => m[2]);
const badLocs = [...new Set(locRefs.filter(k => !tnKeys.includes(k) && !cityKeys.includes(k)))];
if (badLocs.length > 0) {
  errors.push('from_loc/to_loc 引用不存在: ' + badLocs.join(', '));
}

// 4. HSR_ROUTES key format
const hsrRaw = extractConst('HSR_ROUTES');
if (hsrRaw) {
  const hsrKeys = [...hsrRaw.matchAll(/\"([^\"]+)\":/g)].map(m => m[1]);
  const badHsr = hsrKeys.filter(k => !k.match(/^[A-Z]{3,5}\u2192[A-Z]{3,5}\$/));
  if (badHsr.length > 0) {
    errors.push('HSR_ROUTES key 格式错误: ' + badHsr.join(', ') + ' (应为 FROM→TO)');
  }
}

// 5. ORDER length vs LEGS length
const orderRaw = extractConst('ORDER');
const orderCount = orderRaw
  ? [...orderRaw.matchAll(/\"([A-Z0-9]+)\"/g)].length
  : 0;
const expectedOrder = legsCount - 1;
if (orderCount !== legsCount - 1) {
  errors.push('ORDER 长度 ' + orderCount + ' != LEGS.length-1 (' + expectedOrder + ')');
}

// 6. cityToNodes references
const ctnRaw = extractConst('cityToNodes');
if (ctnRaw) {
  const pairs = [...ctnRaw.matchAll(/\\[\"([A-Z]+)\",\\s*\"([A-Z_0-9]+)\"\\]/g)].map(m => [m[1], m[2]]);
  const badPairs = pairs.filter(([c, n]) => !cityKeys.includes(c) || !tnKeys.includes(n));
  if (badPairs.length > 0) {
    errors.push('cityToNodes 引用错误: ' + JSON.stringify(badPairs));
  }
}

if (errors.length === 0) {
  process.exit(0);
} else {
  errors.forEach(e => console.log('  ✗ ' + e));
  process.exit(1);
}
" 2>&1 && echo "  ✓ 所有数据校验通过"

  local RC=$?
  if [ $RC -ne 0 ]; then
    FAILED=1
  fi

  rm -f "$TMP"
}

for FILE in "$@"; do
  check_file "$FILE"
done

echo ""
if [ $FAILED -eq 0 ]; then
  echo "✅ 全部通过，可以 git push"
  exit 0
else
  echo "❌ 有错误，请修复后再 push"
  exit 1
fi
