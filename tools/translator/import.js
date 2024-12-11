// - launch from a directory containing ./meaning_tables/<language> and ./meaning-tables_<language>.csv
// - run node ./import.js <language>
// - the existing tables in ./meaning_tables/<language> are updated

const fs = require('fs');
const { parse } = require("csv-parse");

// get command line arguments
if (process.argv.length < 3) {
  console.log('Missing arguments. Usage: node ./import.js <language> [<CSV delimiter>]');
  process.exit();
}
const language = process.argv[2];
const csvDelimiter = process.argv.length > 3 ? process.argv[3] : ';';

// import the tables
importTables(language);

async function importTables(language) {
  const rows = [];

  fs.createReadStream(`./meaning-tables_${language}.csv`)
    .pipe(parse({ delimiter: csvDelimiter, from_line: 2, bom: true, encoding: 'utf8', trim: true }))
    .on('data', function (row) {
      rows.push(row);
    })
    .on('end', function () {
      // sort by table ID then index
      rows.sort((row1, row2) => {
        const tableId1 = row1[0];
        const tableId2 = row2[0];

        if (tableId1 == tableId2) {
          const index1 = row1[1];
          const index2 = row2[1];

          if (index1 == 'name') {
            return -1;
          } else if (index2 == 'name') {
            return 1;
          } else {
            return parseInt(index1) - parseInt(index2);
          }
        } else {
          return tableId1 < tableId2 ? -1 : 1;
        }
      });

      // update each table
      let tableFile;
      let table;
      let isEntries2 = false;

      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];

        // determine the table ID of the current row
        const newIsEntries2 = row[0].endsWith('.entries2');
        if (newIsEntries2 != isEntries2) {
          isEntries2 = newIsEntries2;
        }
        const tableId = isEntries2 ? row[0].split('.')[0] : row[0];

        // if the table ID changes,
        // write the current table
        // and read the new table for updating
        if (!table || table.id != tableId) {
          writeTable();

          tableFile = `./meaning_tables/${language}/${tableId}.json`;
          const tableJson = fs.readFileSync(tableFile, 'utf8');
          table = JSON.parse(tableJson);
        }

        // update the proper entry in the table
        const index = row[1];
        if (index == 'name') {
          table.name = row[3];
        } else {
          const entries = isEntries2 ? table.entries2 : table.entries;
          entries[parseInt(index)] = row[3];
        }
      }

      // write the last table
      writeTable();

      function writeTable() {
        if (table) {
          fs.writeFileSync(tableFile, JSON.stringify(table, null, '\t'), 'utf8');
        }
      }
    })
    .on("error", function (error) {
      console.log(error.message);
    });
}