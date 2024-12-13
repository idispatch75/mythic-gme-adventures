import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/utils.dart';
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
        ButtonRow(children: [
          IconButton.filled(
            onPressed: _create,
            icon: const Icon(Icons.add),
            tooltip: 'Create a Feature',
          ),
        ]),
        Expanded(
          child: Obx(
            () => defaultListView(
              itemCount: features.length,
              itemBuilder: (_, index) {
                return _FeatureView(features[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  void _create() async {
    final feature = Feature('');

    final result = await Get.dialog<bool>(
      FeatureEditView(feature, canDelete: false),
      barrierDismissible: false,
    );

    if (result ?? false) {
      controller.add(feature);
    }
  }
}

class _FeatureView extends GetView<FeaturesService> {
  final Rx<Feature> _feature;

  const _FeatureView(this._feature);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ListTile(
        title: Text(_feature().name),
        onTap: _edit,
      ),
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
