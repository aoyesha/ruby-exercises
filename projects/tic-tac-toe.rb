module Displayable
    def clear_screen
        system('clean') || system('cls')
    end


def joinor(array, delimeter = ', ', word = 'or')
    case array.size
    when 0 
        then ''
    when 1 
        then array.first.to_s
    else 
        "#{array[0..-2].join(delimeter)}#{delimeter}#{word}#{array[-1]}"
        end
    end
end

class InvalidMoveError < StandardError; 

end

class Square
    INITIAL_MARKER = ' '.freeze #constant, shared by all squares

    attr_accessor :marker

    def initialize(marker = INITIAL_MARKER)
        @marker = marker
    end
    def unmarked?
        marker == INITIAL_MARKER
    end
    def marked?
        !unmarked?
    end
    def to_s
        marker
    end
end

class Board
    WINNING_LINES = [
        [1, 2, 3], [4, 5, 6], [7, 8, 9],   # rows
        [1, 4, 7], [2, 5, 8], [3, 6, 9],   # columns
        [1, 5, 9], [3, 5, 7]               # diagonals
].freeze

    CENTER = 5

    def initialize
        @squares = {}
        reset
    end

    def reset 
        (1..9).each{|key| @squares[key] = Square.new}
    end

    def [](key)
        @squares[key]
    end

    def []=(key, marker)
    raise InvalidMoveError, "Square #{key} does not exist" unless @squares.key?(key)
    raise InvalidMoveError, "Square #{key} is already taken" if @squares[key].marked?

    @squares[key].marker = marker
  end
  def unmarked_keys
    @squares.select { |_key, square| square.unmarked? }.keys
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !winning_marker.nil?
  end

   def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)    # the three Square objects
      markers = squares.select(&:marked?).collect(&:marker)

      next unless markers.size == 3                    # line not full, skip
      return markers.first if markers.uniq.size == 1   # all three same = win
    end
    nil    # checked every line, nobody has won
  end
  def count_marker_in_line(line, marker)
    @squares.values_at(*line).count { |square| square.marker == marker }
  end

  # Finds a square that would immediately win (or block) for this marker.
  # Returns the square number, or nil if there is no such square.
  def at_risk_square(marker)
    WINNING_LINES.each do |line|
      next unless count_marker_in_line(line, marker) == 2

      empty = line.select { |key| @squares[key].unmarked? }
      return empty.first if empty.size == 1
    end
    nil
  end

  def draw
    puts
    puts '     |     |'
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts '     |     |'
    puts '-----+-----+-----'
    puts '     |     |'
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts '     |     |'
    puts '-----+-----+-----'
    puts '     |     |'
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts '     |     |'
    puts
  end

  def self.draw_key
    puts
    puts '  Squares are numbered:'
    puts '  1  |  2  |  3'
    puts '-----+-----+-----'
    puts '  4  |  5  |  6'
    puts '-----+-----+-----'
    puts '  7  |  8  |  9'
    puts
  end
end

class Player
    attr_reader :marker, :name
    attr_accessor :score


    def initialize(marker, name)
        @marker = marker
        @name = name
        @score = 0
    end

    def choose_move(_board)
        raise NotImplementedError,"#{self.class} must define choose move"
    end
    def to_s
        name
    end
end


    class Human < Player
  include Displayable

  def choose_move(board)
    choice = nil

    # loop do keeps asking until the input is valid.
    loop do
      print "#{name}, choose a square (#{joinor(board.unmarked_keys)}): "
      input = gets

      # gets returns nil if input runs out (Ctrl+D, or piped input).
      # Without this, the next line would crash with NoMethodError on nil.
      return board.unmarked_keys.sample if input.nil?

      choice = input.chomp.to_i
      break if board.unmarked_keys.include?(choice)

      puts '  Sorry, that is not a valid choice.'
    end

    choice
  end
end

class Computer < Player
  attr_writer :opponent_marker

  def choose_move(board)
    # 1. Can I win right now? Then win.
    square = board.at_risk_square(marker)
    return square if square

    # 2. Is the opponent about to win? Then block them.
    square = board.at_risk_square(opponent_marker)
    return square if square

    # 3. The center is the strongest square. Take it if free.
    return Board::CENTER if board.unmarked_keys.include?(Board::CENTER)

    # 4. Otherwise pick at random.
    board.unmarked_keys.sample
  end

  private

  # Private: only this object can call it. Nothing outside a Computer
  # has any business asking about its internal strategy.
  def opponent_marker
    @opponent_marker
  end
end

# It owns the board and the players, and runs the main loop. Notice how
# little it does itself: it mostly asks other objects to do their own
# jobs. That is what good OOP looks like.
class TTTGame
  include Displayable

  HUMAN_MARKER    = 'X'.freeze
  COMPUTER_MARKER = 'O'.freeze
  WINNING_SCORE   = 3   # first to 3 wins the match

  def initialize
    @board    = Board.new
    @human    = Human.new(HUMAN_MARKER, 'You')
    @computer = Computer.new(COMPUTER_MARKER, 'Ruby-bot')

    # The computer needs to know what to block. One object handing
    # information to another.
    @computer.opponent_marker = HUMAN_MARKER

    @current_player = @human
  end

  def play
    display_welcome

    loop do
      play_one_round
      break if someone_reached_winning_score?
      break unless play_again?
    end

    display_match_result
    puts
    puts 'Thanks for playing!'
  end

  private

  attr_reader :board, :human, :computer

  def play_one_round
    board.reset
    @current_player = @human
    display_board

    loop do
      current_player_moves
      break if board.someone_won? || board.full?

      display_board
    end

    display_board
    award_point
    display_round_result
  end

  # The polymorphic heart of the game. It does not know or care whether
  # @current_player is a Human or a Computer - it just asks for a move.
  # Adding a third kind of player would need NO change here.
  def current_player_moves
    square = @current_player.choose_move(board)

    begin
      board[square] = @current_player.marker
    rescue InvalidMoveError => e
      # Should not happen, since both players pick from unmarked_keys.
      # But if a bug ever produced a bad square, this explains it clearly
      # instead of corrupting the board.
      puts "Invalid move: #{e.message}"
      return
    end

    switch_player
  end

  def switch_player
    @current_player = (@current_player == @human ? @computer : @human)
  end

  def winner
    case board.winning_marker
    when HUMAN_MARKER    then human
    when COMPUTER_MARKER then computer
    end
  end

  def award_point
    winner.score += 1 if winner
  end

  def someone_reached_winning_score?
    human.score >= WINNING_SCORE || computer.score >= WINNING_SCORE
  end

  def match_winner
    return human    if human.score >= WINNING_SCORE
    return computer if computer.score >= WINNING_SCORE

    nil
  end

  def display_welcome
    clear_screen
    puts ('=================================')
    puts "  Tic Tac Toe - first to #{WINNING_SCORE} wins"
    puts ('=================================')
    puts
    puts "  #{human.name}: #{human.marker}     #{computer.name}: #{computer.marker}"
    Board.draw_key
  end

  def display_board
    puts "Score  -  #{human.name}: #{human.score}   #{computer.name}: #{computer.score}"
    board.draw
  end

  def display_round_result
    if winner
      puts ">> #{winner.name} won this round!"
    else
      puts '>> This round is a tie.'
    end
    puts
  end

  def display_match_result
    puts ('=================================')
    if match_winner
      puts "  MATCH OVER - #{match_winner.name} wins #{human.score}-#{computer.score}!"
    else
      puts "  Final - #{human.name}: #{human.score}  #{computer.name}: #{computer.score}"
    end
    puts ('=================================')
  end

  def play_again?
    answer = nil

    loop do
      print 'Play another round? (y/n): '
      input = gets
      return false if input.nil?

      answer = input.chomp.downcase
      break if %w[y yes n no].include?(answer)

      puts '  Please answer y or n.'
    end

    answer.start_with?('y')
  end
end

TTTGame.new.play