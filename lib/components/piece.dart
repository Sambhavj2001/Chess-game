enum ChessPieceType { pawn, rook, knight, bishop, queen, king }

class ChessPiece {
  final ChessPieceType type;
  final String imagePath;
  final bool isWhite;

  ChessPiece({
    required this.type,
    required this.imagePath,
    required this.isWhite,
  });
}
