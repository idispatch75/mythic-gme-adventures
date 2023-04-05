import { Elm } from "./src/Main.elm";
import * as TaskPort from 'elm-taskport';
import * as LocalStorage from 'elm-localstorage';

// translations
import actions_en from './assets/tables/actions.en.json';
import descriptions_en from './assets/tables/descriptions.en.json';
import character_actions_combat from './assets/tables/character_actions_combat.en.json';

meaning_tables_en = {};
Object.assign(meaning_tables_en, actions_en);
Object.assign(meaning_tables_en, descriptions_en);
Object.assign(meaning_tables_en, character_actions_combat);

const translations = {
  meaning_tables: meaning_tables_en
};

// local storage
TaskPort.install();
LocalStorage.install(TaskPort);

Elm.Main.init({
  node: document.getElementById("root"),
  flags: translations
});
