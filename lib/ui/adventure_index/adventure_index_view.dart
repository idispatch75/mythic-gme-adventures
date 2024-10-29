import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/get_extensions.dart';
import '../../helpers/inline_link.dart';
import '../../helpers/utils.dart';
import '../adventure/adventure.dart';
import '../adventure/adventure_edit_view.dart';
import '../fate_chart/fate_chart.dart';
import '../layouts/layout.dart';
import '../preferences/preferences.dart';
import '../widgets/actions_menu.dart';
import '../widgets/button_row.dart';
import '../widgets/header.dart';
import '../widgets/progress_indicators.dart';
import '../widgets/sub_label.dart';
import 'adventure_index_ctl.dart';

class AdventureIndexView extends GetView<AdventureIndexController> {
  final _preferences = Get.find<LocalPreferencesService>();

  AdventureIndexView({super.key}) {
    Get.replaceForced(AdventureIndexController());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return protectClose(
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(builder: (_, constraints) {
            final isPhone = constraints.maxWidth <= kPhoneBreakPoint;
            bool isDarkMode = false;
            if (isPhone) {
              isDarkMode = Get.find<LocalPreferencesService>().enableDarkMode();
            }

            final Widget content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Obx(() {
                    // choose between the list or the loader
                    Widget? list;
                    if (controller.status().isSuccess) {
                      list = defaultListView(
                        itemCount: controller.adventures.length,
                        itemBuilder: (_, index) {
                          final adventure = controller.adventures[index];
                          return _IndexAdventureView(adventure);
                        },
                      );
                    } else if (controller.status().isLoading) {
                      list = loadingIndicator;
                    } else if (controller.status().isEmpty) {
                      list = const Center(
                        child: Text(
                          'Click the "+" button above to create an Adventure',
                        ),
                      );
                    }

                    // valid list content
                    if (list != null) {
                      final Widget listView = Column(
                        children: [
                          // header
                          const Header('Adventures'),
                          ButtonRow(
                            children: [
                              if (_preferences.enableGoogleStorage() &&
                                  _preferences.enableLocalStorage())
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: controller.isSynchronizing()
                                      ? loadingIndicator
                                      : IconButton.outlined(
                                          onPressed: controller
                                                  .status()
                                                  .isSuccess
                                              ? controller.synchronizeAdventures
                                              : null,
                                          icon: const Icon(
                                              Icons.cloud_sync_outlined),
                                          tooltip:
                                              'Synchronize local and online storages',
                                        ),
                                ),
                              IconButton.filled(
                                onPressed: !controller.status().isLoading
                                    ? _create
                                    : null,
                                icon: const Icon(Icons.add),
                                tooltip: 'Create an Adventure',
                              ),
                            ],
                          ),

                          // list
                          Expanded(
                            child: list,
                          ),
                        ],
                      );

                      return isPhone ? listView : getZoneDecoration(listView);
                    } else {
                      // error message
                      return Center(
                        child: Card(
                          color: theme.colorScheme.errorContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  controller.status().errorMessage ??
                                      'Unexpected error.',
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: FilledButton(
                                    onPressed: controller.reload,
                                    child: const Text('Retry'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  }),
                ),

                if (isPhone)
                  if (isDarkMode)
                    const Divider(
                      height: 2,
                      thickness: 2,
                    )
                  else
                    Material(
                      elevation: 3,
                      child: Container(
                        margin: const EdgeInsets.only(top: 4),
                      ),
                    ),

                // Use Google
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Switch.adaptive(
                                  value: _preferences.enableGoogleStorage(),
                                  onChanged: controller.enableGoogleStorage,
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Text('Use Google Drive'),
                                ),
                              ],
                            ),

                            // sign out
                            if (_preferences.enableGoogleStorage())
                              TextButton.icon(
                                onPressed: controller.googleSignOut,
                                icon: const Icon(Icons.logout),
                                label: const Text('Sign out'),
                              ),
                          ],
                        ),
                        if (_preferences.enableGoogleStorage()) ...[
                          // read user manual
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Please read the ',
                                  style: SubLabel.getTextStyle(theme),
                                ),
                                getInlineLink(
                                  text: 'User Manual',
                                  url:
                                      'https://idispatch75.github.io/mythic-gme-adventures/user_manual/',
                                ),
                                TextSpan(
                                  text: ' to understand how storage works.',
                                  style: SubLabel.getTextStyle(theme),
                                ),
                              ],
                            ),
                          ),

                          // online options
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 8, 0, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // meaning tables
                                Row(
                                  children: [
                                    const Text('Custom Meaning Tables'),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),

                                      // upload
                                      child: _meaningTablesUpload(),
                                    ),

                                    // download
                                    _meaningTablesDownload(context),
                                  ],
                                ),

                                // disable local storage
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Disable local storage'),
                                    Switch.adaptive(
                                      value: !_preferences.enableLocalStorage(),
                                      onChanged: controller.disableLocalStorage,
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    'This might be useful if you want to make the online version of an Adventure'
                                    ' more recent than its local version.',
                                    style: theme.textTheme.labelMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // preferences
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: OutlinedButton(
                      onPressed: controller.showPreferences,
                      child: const Text('Preferences'),
                    ),
                  ),
                ),
              ],
            );

            if (isPhone) {
              return content;
            } else {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: content,
                  ),
                ),
              );
            }
          }),
        ),
      ),
    );
  }

  void _create() async {
    final adventure = AdventureService(
      id: newId,
      name: '',
      fateChartType: FateChartType.standard,
    );

    final result = await Get.dialog<bool>(
      AdventureEditView(adventure),
      barrierDismissible: false,
    );

    if (result ?? false) {
      await controller.addAdventure(adventure);
    }
  }

  Widget _meaningTablesUpload() {
    return Obx(
      () => controller.isMeaningTableUploading()
          ? Obx(
              () => StackedProgressIndicator(
                child: Text(
                  controller.meaningTableTransferProgress().toString(),
                ),
              ),
            )
          : IconButton.outlined(
              onPressed: controller.isMeaningTableDownloading()
                  ? null
                  : controller.uploadMeaningTables,
              icon: const Icon(Icons.upload),
            ),
    );
  }

  Widget _meaningTablesDownload(BuildContext context) {
    return Obx(
      () => controller.isMeaningTableDownloading()
          ? Obx(
              () => StackedProgressIndicator(
                child: Text(
                  controller.meaningTableTransferProgress().toString(),
                ),
              ),
            )
          : IconButton.outlined(
              onPressed: controller.isMeaningTableUploading()
                  ? null
                  : () => controller.downloadMeaningTables(context),
              icon: const Icon(Icons.download),
            ),
    );
  }
}

class _IndexAdventureView extends GetView<AdventureIndexController> {
  final IndexAdventureVM _adventure;

  const _IndexAdventureView(this._adventure);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(_adventure.source.name, softWrap: true),
      subtitle: Text(
        _adventure.saveDateText,
        style: theme.textTheme.labelSmall,
      ),
      trailing: ActionsMenu([
        // restore
        MenuItemButton(
          onPressed: _restoreAdventure,
          leadingIcon: const Icon(Icons.restore),
          child: const Text('Restore'),
        ),

        // delete
        MenuItemButton(
          onPressed: () => controller.deleteAdventure(_adventure),
          leadingIcon: Icon(
            Icons.delete_forever,
            color: theme.colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ]),
      onTap: () => controller.showAdventure(context, _adventure),
    );
  }

  Future<void> _restoreAdventure() async {
    final json = await pickFileAsJson(dialogTitle: 'Adventure file');
    if (json == null) return;

    return controller.restoreAdventure(json, _adventure);
  }
}
