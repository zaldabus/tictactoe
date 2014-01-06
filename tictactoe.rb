class Board
  attr_reader :rows

  def self.blank_grid
    Array.new(3) { Array.new(3) }
  end

  def initialize(rows = self.class.blank_grid)
    @rows = rows
  end

  def [](pos)
    x, y = pos[1], pos[0]
    @rows[x][y]
  end

  def []=(pos, mark)
    raise "mark already placed there!" unless empty?(pos)

    x, y = pos[1], pos[0]
    @rows[x][y] = mark
  end

  def cols
    cols = [[], [], []]
    @rows.each do |row|
      row.each_with_index do |mark, col_idx|
        cols[col_idx] << mark
      end
    end

    cols
  end

  def diagonals
    down_diag = [[0, 0], [1, 1], [2, 2]]
    up_diag = [[0, 2], [1, 1], [2, 0]]

    [down_diag, up_diag].map do |diag|
      diag.map { |x, y| @rows[x][y] }
    end
  end

  def dup
    duped_rows = rows.map(&:dup)
    self.class.new(duped_rows)
  end

  def empty?(pos)
    self[pos].nil?
  end

  def tied?
    return false if won?

    @rows.all? { |row| row.none? { |el| el.nil? }}
  end

  def over?
    won? || tied?
  end

  def winner
    (rows + cols + diagonals).each do |triple|
      return :x if triple == [:x, :x, :x]
      return :o if triple == [:o, :o, :o]
    end

    nil
  end

  def won?
    !winner.nil?
  end
end

class TicTacToe
  class IllegalMoveError < RuntimeError
  end

  attr_reader :board, :players, :turn

  def initialize(player1, player2)
    @board = Board.new
    @players = { :x => player1, :o => player2 }
    @turn = :x
  end

  def run
    until self.board.over?
      play_turn
    end

    if self.board.won?
      winning_player = self.players[self.board.winner]
      show
      puts "#{winning_player.name} won the game!"
    else
      show
      puts "No one wins!"
    end
  end

  def show
    self.board.rows.each { |row| p row }
  end

  private
  def place_mark(pos, mark)
    if self.board.empty?(pos)
      self.board[pos] = mark
      true
    else
      false
    end
  end

  def play_turn
    while true
      current_player = self.players[self.turn]
      pos = current_player.move(self, self.turn)

      break if place_mark(pos, self.turn)
    end

    @turn = ((self.turn == :x) ? :o : :x)
  end
end

class HumanPlayer
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def move(game, mark)
    game.show
    while true
      puts "#{@name}: please select your space"
      x, y = gets.chomp.split(",").map(&:to_i)
      if HumanPlayer.valid_coord?(x, y)
        return [x, y]
      else
        puts "Invalid coordinate!"
      end
    end
  end

  private
  def self.valid_coord?(x, y)
    [x, y].all? { |coord| (0..2).include?(coord) }
  end
end

class ComputerPlayer
  attr_reader :name

  def initialize
    @name = "Tandy 400"
  end

  def move(game, mark)
    winner_move(game, mark) || random_move(game)
  end

  private
  def winner_move(game, mark)
    (0..2).each do |x|
      (0..2).each do |y|
        board = game.board.dup
        pos = [x, y]

        next unless board.empty?(pos)
        board[pos] = mark

        return pos if board.winner == mark
      end
    end

    nil
  end

  def random_move(game)
    board = game.board
    while true
      range = (0..2).to_a
      pos = [range.sample, range.sample]

      return pos if board.empty?(pos)
    end
  end
end

class SuperComputerPlayer < ComputerPlayer
  def move(game, mark)
    parent = TicTacToeNode.new(game.board, mark)

    best_children_node = nil
    parent.children.each do |children_node|

      if best_children_node.nil?
        best_children_node = children_node
      elsif best_children_node.losing_node?(mark) &&
        !(children_node.losing_node?(mark))
        best_children_node = children_node
      elsif children_node.winning_node?(mark)
        best_children_node = children_node
      end
    end

    best_children_node.prev_move_pos
  end
end

class TicTacToeNode
  attr_reader :board, :next_player, :prev_move_pos

  def initialize(board, next_player, prev_move_pos = nil)
    @board, @next_player, @prev_move_pos = board, next_player, prev_move_pos
  end

  def losing_node?(player)
    if board.over?
      return board.winner == (player == :x ? :o : :x)
    end

    if next_player == player
      self.children.all? {|node| node.losing_node?(player)}
    else
      self.children.any? {|node| node.losing_node?(player)}
    end
  end

  def winning_node?(player)
    if board.over?
      return board.winner == player
    end

    if next_player == player
      self.children.any? {|node| node.winning_node?(player)}
    else
      self.children.all? {|node| node.winning_node?(player)}
    end
  end

  def children
    children = []

    (0..2).each do |x|
      (0..2).each do |y|
        pos = [x,y]

        next unless board.empty?(pos)

        new_board = board.dup
        new_board[pos] = next_player

        children << TicTacToeNode.new(
          new_board,
          (next_player == :x ? :o : :x),
          pos
            )
      end
    end

    children
  end
end

if __FILE__ == $PROGRAM_NAME
  hp = HumanPlayer.new("Ryan")
  cp = SuperComputerPlayer.new

  TicTacToe.new(hp, cp).run
end