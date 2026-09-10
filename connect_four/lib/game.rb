require_relative 'board'
require_relative 'player'

class Game
  RED    = '●'.freeze
  YELLOW = '○'.freeze

  attr_reader :board, :players, :current_player


  def initialize(player_one = Player.new('Player 1', RED),
                 player_two = Player.new('Player 2', YELLOW),
                 board = Board.new)
    @players        = [player_one, player_two]
    @board          = board
    @current_player = @players.first
  end

  def play
    introduce
    play_turn until game_over?
    display_board
    announce_result
  end

  def play_turn
    display_board
    column = player_input
    board.drop(column, current_player.symbol)
    switch_player unless game_over?
  end

  def switch_player
    @current_player = (current_player == players.first ? players.last : players.first)
  end

  def game_over?
    board.winner? || board.full?
  end

  def winner
    players.find { |player| player.symbol == board.winner }
  end

  # Keeps asking until it gets a legal column. Returns a 0-based index.
  def player_input
    loop do
      print "#{current_player.name} (#{current_player.symbol}), choose a column (#{prompt_options}): "
      input = gets
      return board.available_columns.sample if input.nil? # end of input

      column = input.strip.to_i - 1                       # players type 1-7
      return column if board.available_columns.include?(column)

      puts '  That is not an available column.'
    end
  end

  def prompt_options
    board.available_columns.map { |c| c + 1 }.join(', ')
  end

  def display_board
    puts
    puts board
    puts
  end

  def announce_result
    if winner
      puts ">> #{winner.name} (#{winner.symbol}) wins!"
    else
      puts '>> It is a draw.'
    end
  end

  def introduce
    puts '=============================='
    puts '        CONNECT FOUR'
    puts '=============================='
    puts "#{players.first} vs #{players.last}"
    puts 'Drop four in a row - across, down, or diagonally.'
  end
end