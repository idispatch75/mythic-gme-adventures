import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../styles.dart';
import '../widgets/header.dart';
import 'meaning_table.dart';

class MeaningTableLookupView extends StatefulWidget {
  final MeaningTable table;

  const MeaningTableLookupView(this.table, {super.key});

  @override
  State<MeaningTableLookupView> createState() => _MeaningTableLookupViewState();
}

class _MeaningTableLookupViewState extends State<MeaningTableLookupView> {
  late String _tableName;
  late List<_Entry> _entries;
  List<_Entry>? _entries2;

  @override
  void initState() {
    super.initState();

    _buildState();
  }

  void _buildState() {
    final meaningTables = Get.find<MeaningTablesService>();

    _tableName = meaningTables.getMeaningTableName(widget.table.id);

    List<_Entry> generateEntries(int tableIndex, int entryCount) {
      return List.generate(entryCount, (index) {
        final roll = index + 1;
        final text = meaningTables.getMeaningTableEntry(
            '${widget.table.id}_$tableIndex', roll);

        return _Entry(text, roll);
      });
    }

    _entries = generateEntries(1, widget.table.entryCount1);

    if (widget.table.entryCount2 != null) {
      _entries2 = generateEntries(2, widget.table.entryCount2!);
    } else {
      _entries2 = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget entries = _buildEntries(_entries);
    if (_entries2 != null) {
      entries = Expanded(
        child: Row(
          children: [
            entries,
            _buildEntries(_entries2!),
          ],
        ),
      );
    }

    return Column(
      children: [
        Header(_tableName),
        entries,
      ],
    );
  }

  Widget _buildEntries(List<_Entry> entries) {
    return Expanded(
      child: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (_, index) {
          return Container(
              color: index.isEven
                  ? AppStyles.meaningTableColors.background
                  : AppStyles.meaningTableColors.background.withOpacity(0.5),
              child: _EntryView(entries[index]));
        },
      ),
    );
  }

  @override
  void didUpdateWidget(MeaningTableLookupView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.table != widget.table) {
      _buildState();
    }
  }
}

class _Entry {
  final String text;
  final int value;

  const _Entry(this.text, this.value);
}

class _EntryView extends StatelessWidget {
  final _Entry _entry;

  const _EntryView(this._entry);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: SizedBox(
            width: 34,
            child: Text(
              _entry.value.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: Text(
            _entry.text,
            softWrap: false,
            overflow: TextOverflow.clip,
          ),
        ),
      ],
    );
  }
}
