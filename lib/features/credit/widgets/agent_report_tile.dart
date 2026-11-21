import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/cash_advance.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/feedback.dart';
import '../../../shared/widgets/surfaces.dart';

/// Agent report tile: pick agents as chips, then print their rows as a flat
/// list ([onPrintItems]) or grouped by staff ([onPrintByStaff]).
/// The selection is cleared after either report is printed.
class AgentReportTile extends StatefulWidget {
  const AgentReportTile({
    super.key,
    required this.rows,
    required this.onPrintItems,
    required this.onPrintByStaff,
  });

  /// Rows the agents can be picked from.
  final List<CashAdvance> rows;
  final Future<void> Function(List<CashAdvance> selected) onPrintItems;
  final Future<void> Function(List<CashAdvance> selected) onPrintByStaff;

  @override
  State<AgentReportTile> createState() => _AgentReportTileState();
}

class _AgentReportTileState extends State<AgentReportTile> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  /// Selected agents: code → display name, in pick order.
  final Map<String, String> _agents = {};
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<CashAdvance> get _selectedRows => widget.rows.where((r) => _agents.containsKey(r.agentcode ?? '')).toList();

  /// Unique, not-yet-picked agents whose code or name matches the typed text.
  ///
  /// Materialised with `toList()`: the filter has a side effect (`seen.add`),
  /// and Autocomplete iterates the result several times (length, elementAt),
  /// so a lazy iterable came back empty from the second pass on and no agent
  /// could ever be picked.
  Iterable<CashAdvance> _options(TextEditingValue value) {
    final query = value.text.trim();
    if (query.isEmpty) return const [];
    final seen = <String>{..._agents.keys};
    return widget.rows.where((r) => r.matchesAgent(query) && seen.add(r.agentcode ?? '')).take(30).toList();
  }

  void _add(CashAdvance agent) {
    setState(() => _agents[agent.agentcode ?? ''] = agent.agentname ?? '');
    _controller.clear();
    _focusNode.requestFocus();
  }

  Future<void> _print(Future<void> Function(List<CashAdvance>) report) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await report(_selectedRows);
      if (mounted) setState(_agents.clear);
    } catch (e) {
      debugPrint('Agent report failed: $e');
      if (mounted) showToast(context, 'สร้างรายงานไม่สำเร็จ', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _agents.isNotEmpty;
    const reason = 'เพิ่มเอเย่นต์อย่างน้อย 1 รายก่อน';

    return GlassCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('รายงานตามเอเย่นต์', style: AppText.body(13, color: AppColors.muted, weight: FontWeight.w500)),
          const SizedBox(width: 8),
          Text('AGENT REPORT', style: AppText.caption()),
          const Spacer(),
          if (hasSelection) Text('${_selectedRows.length} รายการ', style: AppText.body(12, color: AppColors.muted)),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.chipBorder),
            ),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final e in _agents.entries)
                    _AgentChip(code: e.key, name: e.value, onRemove: () => setState(() => _agents.remove(e.key))),
                  SizedBox(
                    width: 220,
                    child: RawAutocomplete<CashAdvance>(
                      textEditingController: _controller,
                      focusNode: _focusNode,
                      optionsBuilder: _options,
                      displayStringForOption: (o) => '${o.agentcode} ${o.agentname}',
                      onSelected: _add,
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) => TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onSubmitted: (_) => onSubmitted(), // Enter picks the highlighted option
                        style: AppText.body(13),
                        decoration: InputDecoration(
                          hintText: '+ เพิ่มเอเย่นต์ รหัสหรือชื่อ…',
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintStyle: AppText.body(12.5, color: AppColors.faint),
                        ),
                      ),
                      optionsViewBuilder: (context, onSelected, options) => _AgentOptions(
                        options: options,
                        onSelected: onSelected,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          PillButton(
            label: 'PDF รายการของเอเย่นต์',
            icon: Icons.picture_as_pdf_outlined,
            onPressed: hasSelection ? () => _print(widget.onPrintItems) : null,
            busy: _busy,
            disabledReason: reason,
          ),
          PillButton(
            label: 'รายงานแยกตามรายชื่อ',
            icon: Icons.groups_2_outlined,
            style: PillStyle.white,
            onPressed: hasSelection ? () => _print(widget.onPrintByStaff) : null,
            disabledReason: reason,
          ),
        ]),
      ]),
    );
  }
}

class _AgentChip extends StatelessWidget {
  const _AgentChip({required this.code, required this.name, required this.onRemove});

  final String code;
  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(color: AppColors.magentaSoft, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(code, style: AppText.display(11.5, color: AppColors.magentaDark)),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Text(name,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(12.5, color: AppColors.magentaDark, weight: FontWeight.w500)),
        ),
        IconButton(
          tooltip: 'นำออก',
          visualDensity: VisualDensity.compact,
          iconSize: 15,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 24, height: 24),
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded, color: AppColors.magentaDark),
        ),
      ]),
    );
  }
}

class _AgentOptions extends StatelessWidget {
  const _AgentOptions({required this.options, required this.onSelected});

  final Iterable<CashAdvance> options;
  final AutocompleteOnSelected<CashAdvance> onSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 12,
        shadowColor: const Color(0x55781E46),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 360),
          child: ListView.builder(
            padding: const EdgeInsets.all(6),
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options.elementAt(index);
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                hoverColor: AppColors.magentaSoft,
                onTap: () => onSelected(option),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(children: [
                    SizedBox(
                        width: 64,
                        child: Text(option.agentcode ?? '', style: AppText.display(12, color: AppColors.muted))),
                    Expanded(child: Text(option.agentname ?? '', style: AppText.body(13.5))),
                  ]),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
