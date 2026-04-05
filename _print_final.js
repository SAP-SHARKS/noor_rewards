const fs = require('fs');
const current = JSON.parse(fs.readFileSync('_current_morning.json', 'utf-8'));
const byId = {};
current.forEach(c => byId[c.id] = c);

// Read the migration file and extract the morning array
const code = fs.readFileSync('_morning_migration.js', 'utf-8');
// Find the array between "const morning = [" and the matching "];"
const startIdx = code.indexOf('const morning = [');
const arrayStart = code.indexOf('[', startIdx);

// Count brackets to find the matching close
let depth = 0;
let endIdx = -1;
for (let i = arrayStart; i < code.length; i++) {
  if (code[i] === '[') depth++;
  if (code[i] === ']') depth--;
  if (depth === 0) { endIdx = i + 1; break; }
}

const arrayCode = code.substring(arrayStart, endIdx);
const morning = eval(arrayCode);

morning.forEach((item, i) => {
  let ar = item.arabic || '';
  if (!ar && item.reuse && byId[item.reuse]) ar = byId[item.reuse].arabic;
  let tr = item.transliteration || '';
  if (!tr && item.reuse && byId[item.reuse]) tr = byId[item.reuse].transliteration;
  const firstAr = (ar || '').replace(/\n/g, ' ').substring(0, 80).trim();
  const firstTr = (tr || '').split('.').slice(0, 2).join('.').trim();
  console.log(`${i + 1}. [x${item.recommended_count}] ${item.reward}`);
  console.log(`   ${firstAr}...`);
  console.log(`   ${firstTr}`);
  console.log('');
});
