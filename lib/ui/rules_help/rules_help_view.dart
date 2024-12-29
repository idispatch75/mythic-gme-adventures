import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:formatted_text/formatted_text.dart';
import 'package:get/get.dart';

import '../chaos_factor/chaos_factor.dart';
import '../fate_chart/fate_chart.dart';
import '../widgets/responsive_dialog.dart';

class RulesHelpView extends HookWidget {
  static const title = 'Rules Help';

  final RulesHelpEntry? initialEntry;

  const RulesHelpView({this.initialEntry, super.key});

  @override
  Widget build(BuildContext context) {
    final selectedEntry = useState(initialEntry ?? fateChartHelp);

    final scrollController = useScrollController();

    final String content;
    if (selectedEntry.value == fateChartHelp) {
      content = _getFateChartContent();
    } else {
      content = selectedEntry.value.content;
    }

    return ResponsiveDialog.withAppBar(
      title: title,
      childBuilder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // rule selection
          Center(
            child: DropdownMenu<RulesHelpEntry>(
              initialSelection: selectedEntry.value,
              enableFilter: false,
              enableSearch: false,
              onSelected: (value) {
                if (value != null) {
                  selectedEntry.value = value;

                  scrollController.jumpTo(0);
                }
              },
              dropdownMenuEntries: [
                fateChartHelp,
                randomEventHelp,
                scenesHelp,
                threadProgressTrackHelp,
              ]
                  .map((e) => DropdownMenuEntry<RulesHelpEntry>(
                      value: e, label: e.label))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // rule content
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              child: FormattedText(
                content,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            child: Text(
              '* This abstract is not a reference and may contain errors.',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _getFateChartContent() {
    final chaosFactor = Get.find<ChaosFactorService>().chaosFactor.value;

    const probabilities = [
      Probability.certain,
      Probability.nearlyCertain,
      Probability.veryLikely,
      Probability.likely,
      Probability.fiftyFifty,
      Probability.unlikely,
      Probability.veryUnlikely,
      Probability.nearlyImpossible,
      Probability.impossible,
    ];

    final fateChartService = Get.find<FateChartService>();

    final probabilitiesBlock = probabilities.map((e) {
      final outcome = fateChartService.getOutcomeProbability(e);

      return '- _${e.text}:_ ${outcome.threshold}%';
    }).join('\n');

    return fateChartHelp.content
        .replaceFirst('{chaos_factor}', chaosFactor.toString())
        .replaceFirst('{probabilities_block}', probabilitiesBlock);
  }
}

class RulesHelpEntry {
  final String label;
  final String content;

  const RulesHelpEntry(this.label, this.content);
}

const fateChartHelp = RulesHelpEntry(
  'Fate Chart',
  'When asking a Fate Question, formulate it so that a Yes answer would invite more action or danger,'
      ' then evaluate the odds of this eventuality happening, and roll on the Fate Chart.'
      '\n'
      '\nThe answers to the question can be Exceptional Yes, Yes, No, Exceptional No.'
      '\nThe probabilities of each answer depends on the Odd you chose and the current Chaos Factor.'
      ' The greater the Chaos Factor, the more the probabilities are shifted toward the Yes.'
      '\nAn Exceptional answer is the same as a normal answer but pushed to the next logical level.'
      '\n'
      '\nFor the current Chaos Factor of {chaos_factor}, the probabilities for Yes or Exceptional Yes are:'
      '\n{probabilities_block}'
      '\n'
      '\nIf the roll is a double number (11, 22, 33, …) and this number is equal to or below the current Chaos Factor, a Random Event is triggered.',
);

const randomEventHelp = RulesHelpEntry(
  'Random Event',
  'A Random Event can be triggered by a double in a Fate Chart roll or by an Interrupted Scene.'
      '\n'
      '\nTo interpret an Event you need context, focus and meaning:'
      '\n- The context is everything that happened in the adventure up to this point, along with the Fate Question or the tested Scene.'
      '\n- The focus is rolled on the Random Event Focus table.'
      '\n- The meaning is rolled on a Meaning Table (usually Actions or Descriptions), and optionally refined with Fate Questions.'
      '\n'
      '\nExplanation of each Event Focus:'
      '\n- _Remote Event:_ Something has happened that your character did not witness and has just learned about.'
      ' This event is usually related to an existing Character or Thread.'
      '\n- _Ambiguous Event:_ Something happens that is not directly related to the current scene,'
      ' is neither harmful nor helpful, and may not even make sense right now.'
      ' It can be an occasion to explore this new intriguing event (ask Fate Questions), or it can be left alone and may resurface later.'
      '\n- _New NPC:_ A new NPC enters the adventure.'
      ' It plays a role in the current Scene and will likely be added to the Characters List when the Scene is over.'
      ' You can roll on the Meaning Tables to flesh it out.'
      '\n- _NPC Action:_ An existing Character does something that impacts the adventure.'
      '\n- _NPC/PC Negative or Positive:_ Something good or bad happens to a Character or a Player Character.'
      '\n- _Move toward a Thread:_ This event brings the PC one step closer to resolving an open Thread.'
      '\n- _Move away from a Thread:_ A new hurdle or setback hinders the PC\'s progress toward closing a Thread.'
      '\n- _Close a Thread:_ The event resolves a Thread or nullifies it somehow.'
      '\n- _Current Context:_ The focus is the context of the Fate Question or what is currently going on in the adventure.'
      ' The event adds a new layer to that.'
      '\n'
      '\nIf the rolled focus is related to a Character or a Thread and the respective List is empty,'
      ' then Current Context is used as focus.',
);

const scenesHelp = RulesHelpEntry(
  'Scene',
  'When starting a new Scene, first determine the Expected Scene, then Test it against the Chaos Factor for this new Scene.'
      ' The higher the Chaos Factor, the higher the chances the Scene won\'t happen as expected,'
      ' in which case it can be Altered or become an Interrupt Scene.'
      '\n'
      '\nFor an Altered Scene you can:'
      '\n- Switch to the next most expected scene.'
      '\n- Change any element of the Expected Scene (NPCs, location, action, …), using Meaning Tables if necessary.'
      '\n- Roll a Scene Adjustment. If the roll makes no sense for your Scene, roll again.'
      '\n'
      '\nScene Adjustments:'
      '\n- _Remove a Character:_ Choose the most logical Character to remove from the Expected Scene.'
      '\n- _Add a Character:_ Choose the most logical NPC on the Characters List and add them to the Scene.'
      '\n- _Reduce/Remove an Activity:_ Reduce the intensity of an active element in your Expected Scene,'
      ' or remove it completely if that makes more sense.'
      '\n- _Increase an Activity:_ Increase the intensity of an activity in the Expected Scene.'
      '\n- _Remove an Object:_ remove a significant object in your Expected Scene, choosing whichever object makes the most sense.'
      '\n- _Add an Object:_ Add a significant object to your Expected Scene.'
      ' If nothing logical comes to mind you can roll for inspiration on the Meaning Tables.'
      '\n- _Make 2 Adjustments:_ Make two adjustments to the Expected Scene instead of one,'
      ' rolling on the Scene Adjustment Table until you have determined both adjustments.'
      ' If this result is generated again, simply ignore it and reroll.'
      ' If you roll two results that conflict with each other, ignore the second roll and just use the first.'
      '\n'
      '\nFor an Interrupt Scene, roll a Random Event to create an entirely new Scene.'
      '\n'
      '\nWhen the Scene ends:'
      '\n1. Increment the List counter of Characters or Threads that were active and of import in the Scene (but do not go past 3).'
      '\n2. Add any new Character or Thread to their List.'
      '\n3. Remove from their List Characters and Threads that are no more relevant to the adventure.'
      '\n4. Update the Chaos Factor, subtracting 1 if the Player Character was in control in the Scene, or adding 1 otherwise.',
);

const threadProgressTrackHelp = RulesHelpEntry(
  'Thread Progress Track',
  'The Progress Track is split in phases of 5 Progress Points.'
      ' Each phase requires a Flashpoint to happen before moving to the next phase.'
      '\nA Flashpoint is a dramatic or important event involving the tracked Thread.'
      '\nWhen ending a Scene, if the Player Character moved significantly closer to resolving the Thread, mark +2 Progress.'
      ' You can also mark Progress during a Scene, which may trigger a Flashpoint event that should be resolved immediately.'
      '\nWhen a Flashpoint occurs during normal play, mark +2 Progress and mark a Flashpoint for the current phase.'
      ' No more Flashpoint can occur for this phase.'
      '\nIf a Flashpoint hasn\'t happened by the end of a phase, then a Flashpoint event is triggered:'
      ' treat it as a Random Event with Current Context as Focus.'
      ' It will involve the Thread without fully resolving it.'
      '\n'
      '\nWhen you run out of ideas on how to make progress in a Thread, you can make a Discovery Check:'
      ' think of an action for your PC that may move the Thread forward,'
      ' roll a Fate Question to determine whether this action is effective, and interpret the result as follows:'
      '\n- _Yes:_ Roll on the Thread Discovery Check Table.'
      '\n- _No:_ Nothing useful is found. There is no roll on the Thread Discovery Check Table.'
      '\n- _Exceptional Yes:_ Roll twice on the Thread Discovery Check Table, combining results.'
      '\n- _Exceptional No:_ Same as No, and you can\'t make another Discovery Check for the rest of this Scene.'
      '\n'
      '\nUse the Meaning Tables to interpret the result of the Thread Discovery Check Table.'
      '\n'
      '\nThread Discovery Check Table results:'
      '\n- _Progress +2/+3:_ You discover something that moves you closer to the Focus Thread, giving you 2 or 3 Progress Points.'
      '\n- _Flashpoint +2/+3:_ You discover something that involves the Focus Thread in an important and dramatic way,'
      ' giving you 2 or 3 Progress Points in the process.'
      '\n- _Track +1/+2:_ You didn\'t discover anything useful,'
      ' but just the act of trying moves you along the Thread Progress Track by 1 or 2 points.'
      '\n- _Strengthen Progress +1/+2:_ Some Progress previously made is reinforced, earning you 1 or 2 Progress Points.'
      '\n'
      '\nA Tracked Thread cannot be closed until it reaches its conclusion (the last Progress Point).'
      '\nTreat the conclusion as a Flashpoint.'
      '\nIf the conclusion is to happen in a new Scene, do not Test the Scene, it\'ll happen as Expected.',
);
