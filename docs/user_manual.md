---
layout: page
title: 'User manual'
permalink: /user_manual/
---

## Discovery

On smartphone, you can long-press a button to show a tooltip.

On desktop, you can hover the mouse over a button to show a tooltip.

## Adventures list

The first screen of the application allows you to create/delete/edit/restore an Adventure.

The list of adventures is retrieved from your local storage.  
If you enable the online storage, the list is also retrieved from this storage
and only the most recent version of each Adventure in these lists will be displayed.  
For instance, if you are on your desktop on which you played an Adventure 5 days ago,
and you played the same Adventure on your smartphone 2 days ago,
the online version from 2 days ago will be displayed.
If you open it and save it, then the local version will be updated,
and the local and online versions will be the same.

If you use an online storage and plan to play offline, e.g. on your smartphone,
consider synchronizing the storages from your smartphone,
or opening and saving the adventure you plan to play offline.

If something went wrong while saving an Adventure,
you can *Restore* it from a backup
(typically from a previous version on your online storage).  
Just put the backup Adventure file somewhere on your local drive and select it when restoring
(see [Storage](#storage) to learn how to find the Adventure file, i.e. in `index.json`).  
If you want to import a completely new Adventure from a file,
just create a new empty Adventure, *Restore* it from the file,
and continue when warned about an Adventure mismatch,
which occurs when the ID of the Adventure in the file does not match
the ID of the Adventure you are restoring.

On the Web, there is *Backup* button that allows to backup all your Adventures.

## Adventure screen

On smartphone, the App is split in 3 sections:
- Oracles: where you can roll on the Fate chart, Meaning tables and dice. This should be your go-to tab while you play a scene.
- Scenes: where you can manage your adventure using the Mythic tools: the Threads and Characters lists, the Chaos factor and the Scenes. This is where you should go to start a new scene.
- More: where you manage the data of your adventure: the threads and characters you created to fill the Mythic lists, player characters and notes.

## Threads and Characters lists

There are two lists for Threads/Characters: 
- the *active* list is the list as in the Mythic book, where you can have several instances of the same thread/character, which is represented by a counter on the right that you can modify accordingly. This representation was chosen to save space.  
This list can be found in the "Scenes > Threads/Characters" on smartphone, or on the top of the screen on desktop in full screen.
- the *management* list lists the individual threads/characters, which will still be available even if they are no more present in the *active* list. This allows you to have a history of all your threads/characters, even if they are no more active in the Mythic sense.  
You can click on the "+ list" icon to add them to the *active* list or increment their counter if they are already there.  
This list is used for managing threads/characters in the App and is not part of the Mythic workflow.  
It can be found in "More > Threads/Characters" on smartphone, or in the Threads/Characters tab on desktop in full screen.

You can create a thread/character from both lists.  
If you create it from the *active* list, it will be added to the *management* list and also added to the *active* list with a counter of 1.  
If you create it from the *management* list, you have to manually add it to the *active* list with the "+ list" icon.

If you decrement a thread/character to 0 in the *active* list, it will be removed from this list but not from the *management* list, where you can add it back to the *active* list if need be.

## Random events

The Random events with a focus of NPC or Thread are rolled on the *active* Threads/Characters lists.  
If a list is empty and the focus of the event is related to this list, then the focus is switched to CurrentContext. 
For instance if "NPC Negative" is rolled and the *active* Characters list is empty, the event focus will become CurrentContext.

When a focus is related to a list, the impacted Thread/Character is rolled according to Mythic rules, which may yield a result of "Choose".  
If you don't like to choose, you can disallow this result in the Global Settings.

## Roll Log

You can copy to the clipboard the result of a Meaning Table roll by pressing the roll result at least 1 second.  
This is available in the Roll log and in the bottom sheet displayed when rolling on smartphones.

## Global Settings

- *Allow to roll "Choose" in the Characters and Threads lists*  
  In Mythic rules, when you roll on a List,
	you may end up rolling an entry that does not have a thread or character,
	in which case you have to Choose an item yourself.  
	If you don't want to have to choose and always want to roll a valid entry,
	then uncheck this setting.

## Web App

Each browser where you open the Web version is its own App with its own local storage.
So the list of adventures and the settings will be blank the first time you open the site on a specific browser.  
If you use a remote storage, you can synchronize the adventures to update your local storage.
Otherwise, you can "import" existing adventures from your data folder or a backup as new Adventures as described in [Adventures list](#adventures-list).

The local storage of the App is not accessible. This is a restriction of the browser platform.  
You are encouraged to make backups of your adventures from the *Adventures list* view.

The Application tracks information about the browser that loads it (OS and browser). This allows to have an idea of how many people use the Web version. This kind of metric is provided by Google out of the box on Android but must be implemented explicitly for the Web version.  
No personal data is stored.

### Installation

The Web version can be "installed" as an application on desktop and mobile.  
It will appear on your home screen on mobile or on your Desktop/taskbar on desktop.  
The recommended browser is Chrome or Edge.

This feature is provided by the browser **and** the OS and is implemented differently depending on the platform:

* **Desktop**: when on the web site, click the "Install" icon **in** the navigation bar, on the right, and follow the instructions.
* **iOS**: TODO

## Storage

Your adventure and global settings are always saved locally,
and optionally on an online storage.

A save occurs 5 seconds after the last modification to an adventure or setting.
The last saved date of an adventure is indicated in the interface.  
Only the currently opened adventure is saved.

Here is the layout of the saved data in the application folder:
- `settings.json`: the global settings
- `adventures`: the folder where adventures are stored 
	- `index.json`: the list of adventures.
	You can lookup the ID of an Adventure from its name in this file.
	- `<adventure ID>.json`: the content of each Adventure
- `meaning_tables`: the folder containing the Custom Meaning Tables if any

On Windows, the *Preferences* are saved in `C:\Users\<user>\AppData\Roaming\IDispatch\Mythic GME Adventures\shared_preferences.json`,
and the online storage refresh token is stored in the encrypted file `C:\Users\<user>\AppData\Roaming\IDispatch\Mythic GME Adventures\flutter_secure_storage.dat`

### Local storage

The data is saved by default in the platform-specific user folder.  
You can change this folder in the *Preferences*.  
On the Web, the local storage is hidden by the browser and cannot be accessed or changed.  

On desktop, if you are not using the online storage,
consider setting this folder to your local Google Drive / OneDrive / Dropbox folder
to get backup and versioning for free.  
If you are using the online storage in the application,
you **MUST NOT** set this folder to your local online folder
for the reasons explained in the section below: your synchronization application will write
the local files to the online storage and, since `Mythic GME Adventures` can see
only the files it created, it won't be able to read these files,
and you may end-up having two copies of the same file,
the one from the application and the one from your synchronization application.  
Of course, if you use 2 different online storages, e.g. Google Drive and Dropbox,
there is no issue with setting the Dropbox folder as local data folder.

### Online storage

In addition to saving the data to your local drive,
you can also save it to Google Drive.
It will be saved in the folder `Mythic GME Adventures` at the root of your Drive.

When you activate the online storage,
the application will request access to your Drive with very restrictive permissions:
it will be able to see only the files/folders it created.  
This is obviously desirable for confidentiality reasons but it has some drawbacks:
you cannot update/customize the application files yourself because the application
won't be able to see them, even the files in `Mythic GME Adventures`.
And there is no way for you to give permission to the application to see a specific file or folder.
This is why you must use the application to upload Custom Meaning Tables to the online storage.

When uploading Custom Meaning Tables, you must select the folder that contains
the language folders.  
On the Web, you must select a zip file containing the language folders.

When you use the online storage, beware of having several applications opened at the same time
on your different devices, as these may overwrite each other's data.

When online storage is enabled, you have the option to *Disable local storage*.  
This might be useful if you want to make the online version of an Adventure
more recent than its local version.  
For instance, you recently saved an Adventure on your smartphone online,
and when you come back to your desktop, which you kept offline,
you mistakenly saved the same Adventure, with obsolete data because the most current data is online.
In this case, if you go back online on your desktop,
the most recent version will be the local one, which is not correct.
The solution here is to disable the local storage,
and save the Adventure's online version to update its save date and make it the most current.
Then you can re-enable the local storage.

## Custom Meaning Tables

All the Meaning Tables from the book are available in English and embedded in the application.

You can create your own tables or customize existing ones or create translations.
The customized tables must be put in your local data directory if you do not use an online storage,
or uploaded via the application otherwise (see [Online storage](#online-storage)).  
If you use the online storage, only the tables in the online storage will be used,
and not the ones in the local storage.

The custom tables are stored in `<data_folder>/meaning_tables/<language>`
where `<language>` is an [ISO-639-1 code](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes),
e.g. `en` for English and `<data_folder>` is the folder defined in the Preferences dialog.  
On the Web, the data folder is not accessible, so you must import a zip file containing the language folders at the root.

The language folder must contain one JSON file per table, with this format:
```json
{
	"id": "actions",
	"name": "Actions",
	"order": 10,
	"characterTrait": null,
	"entries": [
		"Abandon",
		"Accompany",
		"Activate",
		"Agree",
	],
	"entries2": [
		"Advantage",
		"Adversity",
		"Agreement",
		"Animal",
	]
}
```
- `id`: the ID of the table. When customizing or creating a translation for an existing table
it must be the same ID as the customized/translated table.
- `name`: the text displayed in the application.
	Mandatory if you create a new table, optional if you customize or translate.
- `order`: the display order in the list. It overrides the alphabetical order.
	It is optional and can be customized.
- `characterTrait`: the label of the trait when rolling the traits in the Notes of a Character, e.g. `"Motivation"`.
	If not null, the table is displayed in the available traits to roll for a Character.
	It can be an empty string.
	If it is null in a customization of a stock table, it removes the table from the traits list.
- `entries`: the entries in the table.
Mandatory if you create a new table, optional if you customize or translate.
- `entries2`: an optional additional list of entries for the second Meaning Table roll.
	If not present the 2 rolls will be done on `entries`.

The tables can have an arbitrary number of entries and not necessarily 100.

The table file can be named as you wish but must end with `.json`.
It's better to name it using the ID of the table though, e.g. `actions.json`.

The tables in the application are sorted by favorite, then `order`, then alphabetically.

Examples:

- To create a new table `custom_table`, create the file `meaning_tables/en/custom_table.json`:
```json
{
	"id": "custom_table",
	"name": "Custom table",
	"entries": [
		"Entry 1",
		"Entry 2"
		...
	]
}
```

- To translate the `descriptions` table to French, create the file `meaning_tables/fr/descriptions.json`:
```json
{
	"id": "descriptions",
	"name": "Description",
	"entries": [
		"Aventureux",
		"Agressivement",
		"Anxieusement",
		...
	],
	"entries2": [
		"Anormal",
		"Amusant",
		"Artificiel",
		...
	]
}
```

- To customize the order of `character_traits_flaws`, create the file `meaning_tables/en/character_traits_flaws.json`:
```json
{
	"id": "character_traits_flaws",
	"order": 1
}
```

Here are the IDs of the tables shipped with the application:
```
actions
army_descriptors
cavern_descriptors
character_actions_combat
character_actions_general
character_appearance
character_background
character_conversations
character_descriptors
character_identity
character_motivations
character_personality
character_skills
character_traits_flaws
characters
city_descriptors
civilization_descriptors
creature_descriptors
cryptic_message
curses
descriptions
domicile_descriptors
dungeon_descriptors
dungeon_traps
forest_descriptors
gods
legends
locations
magic_item_descriptors
mutation_descriptors
names
noble_house
objects
plot_twists
powers
scavenging_results
smells
sounds
spell_effects
starship_descriptors
terrain_descriptors
undead_descriptors
visions_dreams
```
The tables `actions`, `descriptions`, `characters`, `locations`, `objects`
have the order 10, 20, 30, 40, 50 respectively.