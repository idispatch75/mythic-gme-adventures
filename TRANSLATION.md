# Meaning Tables translation

The App provides translations for Meaning Tables only.

There are about 4500 words to translate, some being duplicates.  
Translating all the tables takes a couple of hours.

A partial translation is possible, with mandatory and recommended tables.
- mandatory: actions, descriptions, characters, locations, objects.
- recommended (in order of priority): 
  1. character_appearance
  1. character_motivations
  1. character_personality
  1. character_traits_flaws
  1. character_descriptors
  1. character_identity
  1. character_background
  1. character_skills
  1. character_conversations

## Instructions

Here are the steps to add a translation into the App:
1. You contact me by e-mail at idispatch.dev@gmail.com, and tell me what kind of translation you want to do (language, full/partial)
1. I create a CSV file that you'll have to translate, using Google Translate to create an initial translation, and I send it to you.  
This translation will need a lot of amending because translating one word without context does not give great results. Also, English often uses the same word for a verb and a noun, which usually does not translate well to other languages.  
The CSV delimiter is a tabulation.
You can Open the file as Text file with Excel or Import it in Google Sheets.
The words to translate are in the `translation` column.
1. You translate the first 2 tables and send me back the CSV so I can check that everything is OK with the file and that you can continue translating the other tables.
1. You finish the translation and send me the final CSV file. Specify which tables were translated if you made a partial translation.
1. I send you a zip file containing the translated Meaning Tables as JSON, so you can see what it looks like in the App.  
To do so, you add them to the App as Custom Meaning Tables.
The easiest way is to use the Web version and then `Custom Meaning Tables` > `Import tables` in the Adventures List page. Then you enter an Adventure, select your language in the `Global Settings`, and `Enable Physical Dice Mode` to have a better view of all the words.
1. If you are happy with your work, you tell me if you want to be credited and with what name. Otherwise you send me the amended CSV and we repeat from the previous step.

## Recommendations

- The same word may be used in multiple tables, so try to be consistent.  
You can sort the lines in Excel to have a better view of the duplicates (beware to sort all the columns).
- Table names are sorted alphabetically in the UI, so you may want to define the names of character_background, character_conversations, etc. so they are displayed consecutively, e.g. "Personaje: Fondo", "Personaje: Conversaciones".
- Save often (in CSV format, not Excel), and make backups regularly.