import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/api_service.dart';

class MoleculeImage extends StatelessWidget {
  final String smiles;
  final double width;
  final double height;

  const MoleculeImage({
    super.key,
    required this.smiles,
    this.width = 300,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (smiles.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(child: Text('No molecule')),
      );
    }
    final url = ApiService.imageUrl(smiles, w: width.toInt(), h: height.toInt());
    return SvgPicture.network(
      url,
      width: width,
      height: height,
      placeholderBuilder: (_) => SizedBox(
        width: width,
        height: height,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
