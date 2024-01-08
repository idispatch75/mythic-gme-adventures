// - launch from a directory containing ./meaning_tables/en and ./meaning_tables/<language>
// - run node ./export.js <language>
// - the output will be ./meaning-tables_<language>.csv

const fs = require('fs').promises;

// get command line arguments
if (process.argv.length < 3) {
	console.log('Missing arguments. Usage: node ./export.js <language> [<CSV delimiter>]');
	process.exit();
}
const language = process.argv[2];
const csvDelimiter = process.argv.length > 3 ? process.argv[3] : ';';

// export the tables
exportTables(language);


/**
 * Exports the tables in ./meaning_tables/<language>.
 * 
 * @param {string} language
 */
async function exportTables(language) {
	const file = await fs.open(`./meaning-tables_${language}.csv`, 'w');
	const bomMarker = '\ufeff'
	await appendRow(file, bomMarker + 'table', 'index', 'english', 'translation');

	// append translations for each translated table
	const translatedTablesDirectory = `./meaning_tables/${language}`;
	const translatedTableFiles = await fs.readdir(translatedTablesDirectory);

	for (const tableFileName of translatedTableFiles.filter(_ => _.endsWith('.json'))) {
		// read the translated table
		const translatedTableJson = await fs.readFile(`${translatedTablesDirectory}/${tableFileName}`, 'utf8');
		const translatedTable = JSON.parse(translatedTableJson);

		if (translatedTable.entries.length == 0) {
			continue;
		}

		// read the reference table
		const referenceTableJson = await fs.readFile(`./meaning_tables/en/${tableFileName}`, 'utf8');
		const referenceTable = JSON.parse(referenceTableJson);

		await exportTable(referenceTable, translatedTable, file);
	}

	await file.close();
}

/**
 * Writes info for a table.
 * 
 * @param referenceTable 
 * @param translatedTable 
 * @param {fs.FileHandle} file 
 */
async function exportTable(referenceTable, translatedTable, file) {
	async function writeEntries(referenceEntries, translatedEntries, isEntries2) {
		for (let i = 0; i < referenceEntries.length && i < translatedEntries.length; i++) {
			const referenceEntry = referenceEntries[i];
			const translatedEntry = translatedEntries[i];

			const tableId = isEntries2 ? `${referenceTable.id}.entries2` : referenceTable.id;
			await appendRow(file, tableId, i, referenceEntry, translatedEntry);
		}
	}

	// name
	await appendRow(file, referenceTable.id, 'name', `${referenceTable.name}`, `${translatedTable.name}`);

	// entries
	await writeEntries(referenceTable.entries, translatedTable.entries);

	// entries2
	if (referenceTable.entries2 != null && translatedTable.entries2 != null) {
		await writeEntries(referenceTable.entries2, translatedTable.entries2, true);
	}
}

function appendRow(file, tableId, index, english, translation) {
	return fs.appendFile(file, [tableId, index, english, translation].join(csvDelimiter) + '\n', 'utf8');
}