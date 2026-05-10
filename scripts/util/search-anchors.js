const fs = require('fs');
const c = fs.readFileSync('d:/Test/trae-unlock/unpacked/index.beautified.js', 'utf8');

function findContext(search, radius = 100) {
  const idx = c.indexOf(search);
  if (idx >= 0) {
    const start = Math.max(0, idx - radius);
    const end = Math.min(c.length, idx + search.length + radius);
    console.log(`\n=== "${search}" at ${idx} ===`);
    console.log(c.substring(start, end));
  } else {
    console.log(`\n=== "${search}" NOT FOUND ===`);
  }
}

findContext('localize("continue"', 200);
findContext('efx = [Ib.SERVER_CRASH', 200);
findContext('isOlderCommercialUser', 200);
findContext('AutoRunMode.WHITELIST', 300);
findContext('setBadgesBySessionId', 100);
findContext('provideUserResponse', 200);
findContext('ViewFiles', 200);

console.log('\n=== Searching for Unconfirmed ===');
const unconfirmedIdx = c.indexOf('Unconfirmed');
if (unconfirmedIdx >= 0) {
  console.log(c.substring(unconfirmedIdx - 50, unconfirmedIdx + 100));
} else {
  const unconf2 = c.indexOf('"unconfirmed"');
  if (unconf2 >= 0) {
    console.log('"unconfirmed" found at', unconf2);
    console.log(c.substring(unconf2 - 100, unconf2 + 100));
  }
}

console.log('\n=== Searching for resume list pattern ===');
const resumePatterns = ['= [Ib.', '= [kg.', 'SERVER_CRASH'];
resumePatterns.forEach(p => {
  const idx = c.indexOf(p);
  if (idx >= 0) {
    console.log(`"${p}" at ${idx}: ${c.substring(idx, idx + 200)}`);
  }
});
