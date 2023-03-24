import { Elm } from "./src/Main.elm";
import * as TaskPort from 'elm-taskport';
import * as LocalStorage from 'elm-localstorage';

TaskPort.install();
LocalStorage.install(TaskPort);

Elm.Main.init({ node: document.getElementById("root") });
