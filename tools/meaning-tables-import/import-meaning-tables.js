const fs = require('fs');
require('./table.js');

// create file ./table.js containing:
// source = `<copy/paste from pdf>`
//
// node ./import-meaning-tables.js

const lines = source.split('\n');
const hasMultipleTables = lines.length > 200;

for (let sourceTableIndex = 0; sourceTableIndex < 3; sourceTableIndex++) {
  let entries = [];

  const firstEntryIndex = hasMultipleTables
    ? sourceTableIndex * 201 + 1
    : 0;

  let i;
  for (i = firstEntryIndex; i < firstEntryIndex + 200; i += 2) {
    entries.push(lines[i + 1]);
  }

  if (hasMultipleTables) {
    const tableName = lines[firstEntryIndex - 1].toLowerCase();
    const table = {
      id: tableName.replaceAll(' ', '_'),
      name: tableName.charAt(0).toUpperCase() + tableName.slice(1),
      entries: entries,
    }

    console.log(`Creating table: ${table.id} with ${entries.length} entries`);

    fs.writeFile(table.id + '.json', JSON.stringify(table, undefined, '\t'), err => {
      if (err) {
        console.error(err);
      }
    });
  } else {
    const jsonTable = JSON.stringify(entries);
    console.log('"entries": [' + jsonTable.substring(1, jsonTable.length - 1) + ']');
  }

  if (i >= lines.length) {
    break;
  }
}
