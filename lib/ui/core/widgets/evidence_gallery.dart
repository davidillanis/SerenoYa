import 'package:flutter/material.dart';
import 'package:sereno_ya/data/models/citizen/incident_evidence.dart';
import 'package:sereno_ya/ui/core/theme/colors.dart';

// Galería reutilizable: muestra todas las evidencias, no solo la primera.
// Principal con PageView y contador «i / N», miniaturas para saltar y
// pantalla completa con zoom al tocar.
class EvidenceGallery extends StatefulWidget {
  const EvidenceGallery({
    super.key,
    required this.evidences,
    this.height = 240,
  });

  final List<IncidentEvidence> evidences;
  final double height;

  @override
  State<EvidenceGallery> createState() => _EvidenceGalleryState();
}

class _EvidenceGalleryState extends State<EvidenceGallery> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evidences = [
      for (final item in widget.evidences)
        if (item.fileUrl.isNotEmpty) item,
    ];
    if (evidences.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('No hay evidencia disponible.'),
      );
    }
    if (evidences.length == 1) {
      return _EvidenceImage(
        url: evidences.single.fileUrl,
        height: widget.height,
        onTap: () => _openFullscreen(context, evidences, 0),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            SizedBox(
              height: widget.height,
              child: PageView.builder(
                controller: _controller,
                itemCount: evidences.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (_, page) => _EvidenceImage(
                  url: evidences[page].fileUrl,
                  height: widget.height,
                  onTap: () => _openFullscreen(context, evidences, page),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.modal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_index + 1} / ${evidences.length}',
                  style: TextStyle(
                    color: context.appColors.textInverse,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: evidences.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, thumb) {
              final selected = thumb == _index;
              return GestureDetector(
                onTap: () {
                  _controller.animateToPage(
                    thumb,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? context.appColors.primary
                          : context.appColors.borderVariant,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    evidences[thumb].fileUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.image_not_supported_outlined,
                      color: context.appColors.textTertiary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openFullscreen(
    BuildContext context,
    List<IncidentEvidence> evidences,
    int initial,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: _FullscreenGallery(evidences: evidences, initial: initial),
      ),
    );
  }
}

class _EvidenceImage extends StatelessWidget {
  const _EvidenceImage({
    required this.url,
    required this.height,
    required this.onTap,
  });

  final String url;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: context.appColors.surfaceVariant,
          child: Image.network(
            url,
            height: height,
            width: double.infinity,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  ),
            errorBuilder: (_, _, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No se pudo mostrar la evidencia.')),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  const _FullscreenGallery({required this.evidences, required this.initial});

  final List<IncidentEvidence> evidences;
  final int initial;

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initial;
    _controller = PageController(initialPage: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Evidencia ${_index + 1} de ${widget.evidences.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Flexible(
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.evidences.length,
                onPageChanged: (value) => setState(() => _index = value),
                itemBuilder: (_, page) => InteractiveViewer(
                  child: Image.network(
                    widget.evidences[page].fileUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Center(
                      child: Text('No se pudo mostrar la evidencia.'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
