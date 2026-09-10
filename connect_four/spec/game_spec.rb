require_relative '../lib/game'

RSpec.describe Game do
  let(:player_one) { Player.new('Alice', 'X') }
  let(:player_two) { Player.new('Bob', 'O') }
  subject(:game)   { described_class.new(player_one, player_two) }

  describe '#initialize' do
    it 'starts with the first player' do
      expect(game.current_player).to be(player_one)
    end

    it 'has an empty board' do
      expect(game.board.grid.flatten.compact).to be_empty
    end
  end

  describe '#switch_player' do
    it 'alternates between the two players' do
      expect { game.switch_player }.to change { game.current_player }
        .from(player_one).to(player_two)
    end

    it 'switches back again' do
      game.switch_player
      expect(game.switch_player).to be(player_one)
    end
  end

  describe '#game_over?' do
    it 'is false at the start' do
      expect(game).not_to be_game_over
    end

  
    it 'is true when the board reports a winner' do
      fake_board = double('Board', winner?: true, full?: false)
      game = described_class.new(player_one, player_two, fake_board)

      expect(game).to be_game_over
    end

    it 'is true when the board is full' do
      fake_board = double('Board', winner?: false, full?: true)
      game = described_class.new(player_one, player_two, fake_board)

      expect(game).to be_game_over
    end
  end

  describe '#winner' do
    it 'returns the player whose symbol won' do
      4.times { |i| game.board.drop(i, 'X') }
      expect(game.winner).to be(player_one)
    end

    it 'returns nil when nobody has won' do
      expect(game.winner).to be_nil
    end
  end

  describe '#player_input' do
   
    before do
      allow(game).to receive(:print)
      allow(game).to receive(:puts)
    end

    it 'converts the typed column to a zero-based index' do
      allow(game).to receive(:gets).and_return("4\n")
      expect(game.player_input).to eq(3)
    end

    
    it 'asks again after an invalid column' do
      allow(game).to receive(:gets).and_return("99\n", "0\n", "4\n")
      expect(game.player_input).to eq(3)
    end

    it 'rejects a full column' do
      6.times { game.board.drop(0, 'X') }
      allow(game).to receive(:gets).and_return("1\n", "2\n")

      expect(game.player_input).to eq(1)
    end
  end

  describe '#play_turn' do
    before do
      allow(game).to receive(:display_board)
      allow(game).to receive(:player_input).and_return(3)
    end

    it 'drops the current player\'s piece' do
      expect { game.play_turn }.to change { game.board.grid[5][3] }.from(nil).to('X')
    end

    it 'passes the turn to the other player' do
      expect { game.play_turn }.to change { game.current_player }
        .from(player_one).to(player_two)
    end

    it 'does not switch players after a winning move' do
      3.times { game.board.drop(3, 'X') }   
      game.play_turn                        

      expect(game.current_player).to be(player_one)
    end
  end

  describe '#announce_result' do
    
    it 'announces the winner' do
      4.times { |i| game.board.drop(i, 'X') }

      expect { game.announce_result }.to output(/Alice.*wins/).to_stdout
    end

    it 'announces a draw when nobody won' do
      allow(game.board).to receive(:winner).and_return(nil)

      expect { game.announce_result }.to output(/draw/).to_stdout
    end
  end

  describe '#play' do
  
    it 'plays turns until the game is over' do
      allow(game).to receive(:introduce)
      allow(game).to receive(:display_board)
      allow(game).to receive(:announce_result)
      allow(game).to receive(:player_input).and_return(0, 1, 0, 1, 0, 1, 0)

      expect(game).to receive(:play_turn).at_least(:once).and_call_original
      game.play

      expect(game).to be_game_over
    end
  end
end