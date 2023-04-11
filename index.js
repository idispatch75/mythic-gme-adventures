import { Elm } from "./src/Main.elm";
import * as TaskPort from 'elm-taskport';
import * as LocalStorage from 'elm-localstorage';

// translations
import meaning_tables_en from './assets/tables/en/index'

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
