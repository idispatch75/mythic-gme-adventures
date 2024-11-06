import 'package:get/get.dart';

import '../../helpers/dialogs.dart';
import '../../helpers/utils.dart';
import '../../persisters/meaning_tables_persister.dart';
import 'adventure_index_ctl.dart';

extension AdventureIndexControllerX on AdventureIndexController {
  Future<void> uploadMeaningTables() async {
    // ask confirmation
    if (!await Dialogs.showConfirmation(
      title: 'Upload Custom Meaning Tables?',
      message: 'This will delete the Custom Meaning Tables'
          ' in your online storage and upload the meaning tables in the selected file.\n\n'
          'You may need to restart the application for the changes to take effect.',
      userManualAnchor: 'custom-meaning-tables',
    )) {
      return;
    }

    // pick a zip file
    final zipContent = await pickFileAsBytes(
      dialogTitle: 'Meaning Tables Zip file',
      extension: 'zip',
    );
    if (zipContent == null) {
      return;
    }

    // upload the tables
    try {
      meaningTableTransferProgress.value = 0;
      isMeaningTableUploading.value = true;

      final meaningTables = Get.find<MeaningTablesPersisterService>();
      await meaningTables.importZipToRemote(
          zipContent, meaningTableTransferProgress);
    } catch (e) {
      handleError('upload', e);
    }

    isMeaningTableUploading.value = false;
  }
}
