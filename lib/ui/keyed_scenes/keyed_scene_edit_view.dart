import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get/get.dart';

import '../../helpers/input_validators.dart';
import '../../helpers/utils.dart';
import '../styles.dart';
import '../widgets/edit_dialog.dart';
import 'keyed_scene.dart';

class KeyedSceneEditView extends HookWidget {
  final KeyedScene _scene;
  final bool isNew;

  const KeyedSceneEditView(this._scene, {super.key, required this.isNew});

  @override
  Widget build(BuildContext context) {
    final triggerController = useTextEditingController(text: _scene.trigger);
    final eventController = useTextEditingController(text: _scene.event);

    final saveTrigger = false.obs;

    final counts = _scene.counts.map((e) => e.count.obs).toList();

    return EditDialog<bool>(
      itemTypeLabel: 'Keyed Scene',
      canDelete: !isNew,
      onSave: () {
        _scene.trigger = triggerController.text;
        _scene.event = eventController.text;
        _scene.counts =
            counts.map((e) => KeyedSceneCount(count: e.value)).toList();

        return Future.value(true);
      },
      saveTrigger: saveTrigger,
      onDelete: () {
        Get.find<KeyedScenesService>().delete(_scene);

        return Future.value();
      },
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // trigger
          TextFormField(
            controller: triggerController,
            validator: validateNotEmpty,
            minLines: 2,
            maxLines: null,
            decoration: const InputDecoration(labelText: 'Trigger'),
            autofocus: _scene.trigger.isEmpty,
          ),
          const SizedBox(height: 16),

          // event
          Flexible(
            fit: FlexFit.loose,
            child: TextFormField(
              controller: eventController,
              validator: validateNotEmpty,
              minLines: 3,
              maxLines: null,
              decoration: const InputDecoration(labelText: 'Event'),
            ),
          ),
          const SizedBox(height: 16),

          // counts
          const Text('Counts'),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 16,
            runSpacing: 8,
            children: counts.map((e) => _Count(count: e)).toList(),
          ),
          const SizedBox(height: 32),

          // roll buttons
          const Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              _RollButton(nbFaces: 6),
              _RollButton(nbFaces: 10),
              _RollButton(nbFaces: 20),
            ],
          )
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final RxInt count;

  const _Count({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // minus 1
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (count.value > 0) {
                    count.value--;
                  }
                },
              ),

              // value
              Obx(() => SizedBox(
                    width: 28,
                    child: Text(
                      count.value.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )),

              // plus 1
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => count.value++,
              ),
            ],
          ),
        ),

        // reset
        IconButton(
          onPressed: () => count.value = 0,
          icon: Icon(
            Icons.restart_alt,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          visualDensity: VisualDensity.compact,
          tooltip: 'Reset the count',
        ),
      ],
    );
  }
}

class _RollButton extends StatefulWidget {
  final int nbFaces;

  const _RollButton({required this.nbFaces});

  @override
  State<_RollButton> createState() => __RollButtonState();
}

class __RollButtonState extends State<_RollButton> {
  late Widget _icon;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _icon = _getRollIcon();
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: child,
        ),
        child: _icon,
      ),
      label: Text('1d${widget.nbFaces}'),
      onPressed: () {
        _timer?.cancel();

        final result = rollDie(widget.nbFaces);
        setState(() {
          _icon = _getResultIcon(result);
        });

        _timer = Timer(const Duration(seconds: 5), () {
          setState(() {
            _icon = _getRollIcon();
          });
        });
      },
    );
  }

  Widget _getRollIcon() {
    return AppStyles.rollIcon;
  }

  Widget _getResultIcon(int roll) {
    return SizedBox(
      key: UniqueKey(),
      width: 24,
      height: 24,
      child: Center(
        child: Text(
          roll.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
