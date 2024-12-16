import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/utils.dart';
import '../preferences/preferences.dart';
import '../random_events/random_event.dart';
import '../roll_log/roll_log.dart';
import '../styles.dart';
import '../widgets/button_row.dart';
import 'feature.dart';
import 'feature_edit_view.dart';

class FeaturesView extends GetView<FeaturesService> {
  const FeaturesView({super.key});

  @override
  Widget build(BuildContext context) {
    final features = controller.features;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Obx(() {
          final canRoll = features.length > 1;

          return ButtonRow(children: [
            // Roll button
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton.outlined(
                onPressed: canRoll ? () => _roll(context) : null,
                icon: AppStyles.rollIcon,
                tooltip: 'Roll a Feature in this list',
              ),
            ),

            // Create button
            IconButton.filled(
              onPressed: _create,
              icon: const Icon(Icons.add),
              tooltip: 'Create a Feature',
            ),
          ]);
        }),
        Expanded(
          child: Obx(
            () => defaultAnimatedListView(
              items: features(),
              itemBuilder: (_, item, __) {
                return _FeatureView(item);
              },
              removedItemBuilder: (_, item) {
                return _FeatureView(item, isDeleted: true);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _create() async {
    final feature = Feature(newId, '');

    final result = await Get.dialog<bool>(
      FeatureEditView(feature, canDelete: false),
      barrierDismissible: false,
    );

    if (result ?? false) {
      controller.add(feature);
    }
  }

  void _roll(BuildContext context) {
    if (getPhysicalDiceModeEnabled) {
      showFeaturesLookup(context);
      return;
    }

    final features = controller.features.where((e) => !e().isArchived).toList();
    final dieRoll = rollDie(features.length);

    Get.find<RollLogService>().addGenericRoll(
      title: 'Feature',
      value: features[dieRoll - 1].value.name,
      dieRoll: dieRoll,
    );
  }
}

class _FeatureView extends GetView<FeaturesService> {
  final Rx<Feature> _feature;
  final bool isDeleted;

  const _FeatureView(this._feature, {this.isDeleted = false});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        TextStyle? textStyle;
        if (_feature().isArchived) {
          textStyle = const TextStyle(color: AppStyles.archivedColor);
        }

        return ListTile(
          title: Text(
            _feature().name,
            style: textStyle,
          ),
          onTap: !isDeleted ? _edit : null,
        );
      },
    );
  }

  void _edit() async {
    final result = await Get.dialog<bool>(
      FeatureEditView(_feature(), canDelete: true),
      barrierDismissible: false,
    );

    if (result ?? false) {
      _feature.refresh();

      controller.requestSave();
    }
  }
}
