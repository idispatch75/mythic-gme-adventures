import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../helpers/get_extensions.dart';
import '../../helpers/inline_link.dart';
import '../../helpers/list_view_utils.dart';
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
import 'adventure_index_ctl.io.dart'
    if (dart.library.html) 'adventure_index_ctl.web.dart';

class AdventureIndexView extends GetView<AdventureIndexController> {
  final _preferences = Get.find<LocalPreferencesService>();

  AdventureIndexView({super.key}) {
    Get.replaceForced(AdventureIndexController());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return protectClose(
      child: SafeArea(
        child: Scaffold(
          body: LayoutBuilder(
            builder: (_, constraints) {
              final isPhone = constraints.maxWidth <= kPhoneBreakPoint;
              bool isDarkMode = false;
              if (isPhone) {
                isDarkMode = Get.find<LocalPreferencesService>()
                    .enableDarkMode();
              }

              final Widget content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Obx(() {
                      // choose between the list or the loader
                      Widget? list;
                      if (controller.status().isSuccess) {
                        list = defaultAnimatedListView(
                          items: controller.adventures,
                          itemBuilder: (_, item, _) {
                            return _IndexAdventureView(item);
                          },
                          removedItemBuilder: (_, item) {
                            return _IndexAdventureView(item, isDeleted: true);
                          },
                          comparer: (a, b) => a.source.id == b.source.id,
                        );
                      } else if (controller.status().isLoading) {
                        list = loadingIndicator;
                      } else if (controller.status().isEmpty) {
                        list = const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Click the "+" button above to create an Adventure',
                            ),
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
                                // import meaning tables
                                if (_preferences.enableLocalStorage())
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: MenuAnchor(
                                      builder:
                                          (
                                            BuildContext context,
                                            MenuController menuController,
                                            Widget? child,
                                          ) {
                                            return TextButton(
                                              onPressed:
                                                  !controller.status().isLoading
                                                  ? () {
                                                      if (menuController
                                                          .isOpen) {
                                                        menuController.close();
                                                      } else {
                                                        menuController.open();
                                                      }
                                                    }
                                                  : null,
                                              child: const Text(
                                                'Custom Meaning Tables',
                                              ),
                                            );
                                          },
                                      menuChildren: [
                                        MenuItemButton(
                                          leadingIcon: const Icon(
                                            Icons.download,
                                          ),
                                          onPressed: controller
                                              .importLocalCustomMeaningTables,
                                          child: const Text('Import tables'),
                                        ),
                                        MenuItemButton(
                                          leadingIcon: const Icon(
                                            Icons.delete_forever,
                                          ),
                                          onPressed: controller
                                              .deleteLocalCustomMeaningTables,
                                          child: const Text('Delete tables'),
                                        ),
                                      ],
                                    ),
                                  ),

                                // backup adventures
                                if (_preferences.enableLocalStorage())
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: IconButton.outlined(
                                      tooltip: 'Backup local Adventures',
                                      onPressed: !controller.status().isLoading
                                          ? controller.backupLocalAdventures
                                          : null,
                                      icon: const Icon(Icons.save_alt_outlined),
                                    ),
                                  ),

                                // sync storages
                                if (_preferences.enableGoogleStorage() &&
                                    _preferences.enableLocalStorage())
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: controller.isSynchronizing()
                                        ? loadingIndicator
                                        : IconButton.outlined(
                                            onPressed:
                                                controller.status().isSuccess
                                                ? controller
                                                      .synchronizeAdventures
                                                : null,
                                            icon: const Icon(
                                              Icons.cloud_sync_outlined,
                                            ),
                                            tooltip:
                                                'Synchronize local and online storages',
                                          ),
                                  ),

                                // create adventure
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
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Please read the ',
                                    style: SubLabel.getTextStyle(theme),
                                  ),
                                  getUserManualLink(
                                    anchor: 'storage',
                                    textStyle: SubLabel.getTextStyle(theme),
                                  ),
                                  TextSpan(
                                    text: ' to understand how storages work.',
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

                                      // upload
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                        ),
                                        child: _meaningTablesUpload(),
                                      ),

                                      // download
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                        ),
                                        child: _meaningTablesDownload(context),
                                      ),
                                    ],
                                  ),

                                  // disable local storage
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Disable local storage'),
                                      Switch.adaptive(
                                        value: !_preferences
                                            .enableLocalStorage(),
                                        onChanged:
                                            controller.disableLocalStorage,
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      '${GetPlatform.isWeb ? 'It is mandatory on iOS: local storage does not work currently.\n' : ''}'
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
            },
          ),
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
              tooltip: 'Upload Custom Meaning Tables to the online storage',
              onPressed: controller.isMeaningTableDownloading()
                  ? null
                  : controller.uploadMeaningTables,
              icon: const Icon(Icons.backup_outlined),
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
              tooltip: 'Download Custom Meaning Tables from the online storage',
              onPressed: controller.isMeaningTableUploading()
                  ? null
                  : () => controller.downloadMeaningTables(),
              icon: const Icon(Icons.cloud_download_outlined),
            ),
    );
  }
}

class _IndexAdventureView extends GetView<AdventureIndexController> {
  final IndexAdventureVM _adventure;
  final bool isDeleted;

  const _IndexAdventureView(this._adventure, {this.isDeleted = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(_adventure.source.name, softWrap: true),
      subtitle: Text(
        _adventure.saveDateText,
        style: theme.textTheme.labelSmall,
      ),
      trailing: !isDeleted
          ? ActionsMenu([
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
            ])
          : null,
      onTap: !isDeleted
          ? () => controller.showAdventure(context, _adventure)
          : null,
    );
  }

  Future<void> _restoreAdventure() async {
    final json = await pickFileAsJson(dialogTitle: 'Adventure file');
    if (json == null) return;

    return controller.restoreAdventure(json, _adventure);
  }
}
