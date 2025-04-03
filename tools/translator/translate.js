// - authenticate with ADC: https://cloud.google.com/docs/authentication/set-up-adc-local-dev-environment
// - put the tables to translate into ./meaning_tables/en
// - run node ./translate.js <language>
// - the output will be in ./meaning_tables/<language>

const { Translate } = require('@google-cloud/translate').v2;
const fs = require('fs').promises;

// get language from command line
if (process.argv.length != 3) {
  console.log('Invalid arguments: specify the language only');
  process.exit();
}
const language = process.argv[2];

// translate the tables
translateTables(language);

/**
 * Translates the tables in `./meaning_tables/en` to the specified language
 * and writes it to `./meaning_tables/<language>`.
 *
 * @param {string} language
 */
async function translateTables(language) {
  const inputDirectory = './meaning_tables/en';

  const outputDirectory = `./meaning_tables/${language}`;
  await fs.mkdir(outputDirectory, { recursive: true });

  const translate = new Translate();

  const tableFiles = await fs.readdir(inputDirectory);
  for (const tableFile of tableFiles.filter(_ => _.endsWith('.json'))) {
    // read the table object
    const tableJson = await fs.readFile(`${inputDirectory}/${tableFile}`, 'utf8');
    const table = JSON.parse(tableJson);

    // translate the table
    const translatedTable = await translateTable(translate, table, language);

    // write the translated table
    await fs.writeFile(
      `${outputDirectory}/${table.id}.json`,
      JSON.stringify(translatedTable, null, '\t'),
      'utf8');
  }
}

/**
 * Translates a table to the specified language.
 *
 * @param {Translate} translator
 * @param table The table object.
 * @param {string} language
 * @returns The translated table object.
 */
async function translateTable(translator, table, language) {
  const translateOptions = {
    from: 'en',
    to: language
  };

  let translations = await translate(translator, [table.name, ...table.entries], translateOptions);

  const translatedTable = {
    id: table.id,
    name: translations[0],
    entries: translations.slice(1),
    entries2: undefined,
  };

  // max number of strings for translate() is 128,
  // so get entries2 with another call
  if (table.entries2) {
    translations = await translate(translator, table.entries2, translateOptions);
    translatedTable.entries2 = translations;
  }

  return translatedTable;
}

const translationsCache = new Map();

/// Translates the specified values using a cache of already translated values.
async function translate(translator, values, options) {
  const translations = [];
  const toTranslate = [];

  // initialize the translations with cached translations
  for (const value of values) {
    const translatedValue = translationsCache[value];
    if (translatedValue) {
      translations.push(translatedValue);
    } else {
      translations.push(undefined);
      toTranslate.push(value);
    }
  }

  // get the new translations
  if (toTranslate.length > 0) {
    let [newTranslations] = await translator.translate(toTranslate, options);

    // update the translations with the new translations
    let newTranslationsIndex = 0;
    for (let i = 0; i < translations.length; i++) {
      const translatedValue = translations[i];

      if (translatedValue === undefined) {
        translations[i] = newTranslations[newTranslationsIndex];

        translationsCache[values[i]] = translations[i];

        newTranslationsIndex++;
      }
    }
  }

  return translations;
}
