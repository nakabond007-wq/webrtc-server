import 'package:flutter/material.dart';
import 'dart:math';

class MinesweeperGame extends StatefulWidget {
  const MinesweeperGame({super.key});

  @override
  State<MinesweeperGame> createState() => _MinesweeperGameState();
}

class _MinesweeperGameState extends State<MinesweeperGame> {
  static const int rows = 10;
  static const int cols = 10;
  static const int minesCount = 15;

  late List<List<Cell>> grid;
  bool gameOver = false;
  bool won = false;
  int flagsLeft = minesCount;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    grid = List.generate(
      rows,
      (i) => List.generate(cols, (j) => Cell(i, j)),
    );

    // Place mines randomly
    var random = Random();
    var minesPlaced = 0;
    while (minesPlaced < minesCount) {
      var row = random.nextInt(rows);
      var col = random.nextInt(cols);
      if (!grid[row][col].isMine) {
        grid[row][col].isMine = true;
        minesPlaced++;
      }
    }

    // Calculate adjacent mines
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        if (!grid[i][j].isMine) {
          grid[i][j].adjacentMines = _countAdjacentMines(i, j);
        }
      }
    }

    gameOver = false;
    won = false;
    flagsLeft = minesCount;
  }

  int _countAdjacentMines(int row, int col) {
    var count = 0;
    for (var i = -1; i <= 1; i++) {
      for (var j = -1; j <= 1; j++) {
        var newRow = row + i;
        var newCol = col + j;
        if (newRow >= 0 &&
            newRow < rows &&
            newCol >= 0 &&
            newCol < cols &&
            grid[newRow][newCol].isMine) {
          count++;
        }
      }
    }
    return count;
  }

  void _revealCell(int row, int col) {
    if (gameOver || grid[row][col].isRevealed || grid[row][col].isFlagged) {
      return;
    }

    setState(() {
      grid[row][col].isRevealed = true;

      if (grid[row][col].isMine) {
        gameOver = true;
        _revealAllMines();
        return;
      }

      if (grid[row][col].adjacentMines == 0) {
        _revealAdjacentCells(row, col);
      }

      _checkWin();
    });
  }

  void _revealAdjacentCells(int row, int col) {
    for (var i = -1; i <= 1; i++) {
      for (var j = -1; j <= 1; j++) {
        var newRow = row + i;
        var newCol = col + j;
        if (newRow >= 0 &&
            newRow < rows &&
            newCol >= 0 &&
            newCol < cols &&
            !grid[newRow][newCol].isRevealed &&
            !grid[newRow][newCol].isFlagged) {
          _revealCell(newRow, newCol);
        }
      }
    }
  }

  void _revealAllMines() {
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        if (grid[i][j].isMine) {
          grid[i][j].isRevealed = true;
        }
      }
    }
  }

  void _toggleFlag(int row, int col) {
    if (gameOver || grid[row][col].isRevealed) return;

    setState(() {
      if (grid[row][col].isFlagged) {
        grid[row][col].isFlagged = false;
        flagsLeft++;
      } else if (flagsLeft > 0) {
        grid[row][col].isFlagged = true;
        flagsLeft--;
      }
      _checkWin();
    });
  }

  void _checkWin() {
    var allNonMinesRevealed = true;
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        if (!grid[i][j].isMine && !grid[i][j].isRevealed) {
          allNonMinesRevealed = false;
          break;
        }
      }
      if (!allNonMinesRevealed) break;
    }

    if (allNonMinesRevealed) {
      won = true;
      gameOver = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border.all(color: const Color(0xFF2D2D2D), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🚩 $flagsLeft',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (gameOver)
                  Text(
                    won ? '🎉 WIN!' : '💥 GAME OVER',
                    style: TextStyle(
                      color: won ? const Color(0xFF4CAF50) : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                GestureDetector(
                  onTap: () => setState(_initializeGame),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D2D),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '🔄 NEW',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Game grid
          Padding(
            padding: const EdgeInsets.all(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                itemCount: rows * cols,
                itemBuilder: (context, index) {
                  var row = index ~/ cols;
                  var col = index % cols;
                  var cell = grid[row][col];

                  return GestureDetector(
                    onTap: () => _revealCell(row, col),
                    onLongPress: () => _toggleFlag(row, col),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cell.isRevealed
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFF2D2D2D),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: _buildCellContent(cell),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellContent(Cell cell) {
    if (cell.isFlagged) {
      return const Text('🚩', style: TextStyle(fontSize: 12));
    }

    if (!cell.isRevealed) {
      return const SizedBox.shrink();
    }

    if (cell.isMine) {
      return const Text('💣', style: TextStyle(fontSize: 12));
    }

    if (cell.adjacentMines == 0) {
      return const SizedBox.shrink();
    }

    return Text(
      '${cell.adjacentMines}',
      style: TextStyle(
        color: _getNumberColor(cell.adjacentMines),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Color _getNumberColor(int number) {
    switch (number) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.orange;
      case 6:
        return Colors.cyan;
      case 7:
        return Colors.pink;
      case 8:
        return Colors.yellow;
      default:
        return Colors.white;
    }
  }
}

class Cell {
  final int row;
  final int col;
  bool isMine = false;
  bool isRevealed = false;
  bool isFlagged = false;
  int adjacentMines = 0;

  Cell(this.row, this.col);
}
