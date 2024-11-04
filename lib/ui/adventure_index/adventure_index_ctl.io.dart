import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../helpers/dialogs.dart';
import '../../persisters/meaning_tables_persister.dart';
import 'adventure_index_ctl.dart';

extension AdventureIndexControllerX on AdventureIndexController {
  Future<void> uploadMeaningTables() async {
    // ask confirmation
    if (!await Dialogs.showConfirmation(
      title: 'Upload Custom Meaning Tables?',
      message: 'This will delete the Custom Meaning Tables'
          ' in your online storage and upload the meaning tables in the selected directory.\n\n'
          'You may need to restart the application for the changes to take effect.',
      withUserManual: true,
    )) {
      return;
    }

    // pick a source directory
    final localDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Custom Meaning Tables folder',
      lockParentWindow: true,
    );
    if (localDirectory == null) {
      return;
    }

    // upload the tables
    try {
      meaningTableTransferProgress.value = 0;
      isMeaningTableUploading.value = true;

      final meaningTables = Get.find<MeaningTablesPersisterService>();
      await meaningTables.importDirectoryToRemote(
        localDirectory,
        meaningTableTransferProgress,
      );
    } catch (e) {
      handleError('upload', e);
    }

    isMeaningTableUploading.value = false;
  }
}
