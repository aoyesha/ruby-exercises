class ColumnFullError < StandardError; end
class InvalidColumnError < StandardError; end

class Board
  ROWS    = 6
  COLUMNS = 7
  CONNECT = 4
  EMPTY   = nil

  attr_reader :grid

  def initialize(grid = nil)
    @grid = grid || Array.new(ROWS) { Array.new(COLUMNS, EMPTY) }
  end

  def valid_column?(column)
    column.is_a?(Integer) && column.between?(0, COLUMNS - 1)
  end

  def column_full?(column)
    raise InvalidColumnError, "column #{column} does not exist" unless valid_column?(column)

    !@grid[0][column].nil?
  end

  def available_columns
    (0...COLUMNS).reject { |c| column_full?(c) }
  end


  def drop(column, symbol)
    raise InvalidColumnError, "column #{column} does not exist" unless valid_column?(column)
    raise ColumnFullError, "column #{column} is full" if column_full?(column)

    row = lowest_empty_row(column)
    @grid[row][column] = symbol
    [row, column]
  end

  def full?
    @grid[0].none?(&:nil?)
  end

  def winner
    winning_line&.first_symbol
  end

  def winner?
    !winner.nil?
  end

  def winning_line
    each_line do |cells|
      symbols = cells.map { |r, c| @grid[r][c] }
      next if symbols.any?(&:nil?)
      next unless symbols.uniq.size == 1

      return Line.new(cells, symbols.first)
    end
    nil
  end

  def reset
    @grid = Array.new(ROWS) { Array.new(COLUMNS, EMPTY) }
    self
  end

  def to_s
    rows   = @grid.map { |row| '|' + row.map { |cell| cell || ' ' }.join('|') + '|' }
    header = ' ' + (1..COLUMNS).to_a.join(' ')
    (rows + ['+-+-+-+-+-+-+-+', header]).join("\n")
  end

  Line = Struct.new(:cells, :first_symbol)

  private

  def lowest_empty_row(column)
    (ROWS - 1).downto(0) { |row| return row if @grid[row][column].nil? }
    nil
  end


  def each_line
    directions = [[0, 1], [1, 0], [1, 1], [1, -1]] # right, down, down-right, down-left

    ROWS.times do |row|
      COLUMNS.times do |col|
        directions.each do |dr, dc|
          cells = (0...CONNECT).map { |i| [row + dr * i, col + dc * i] }
          next unless cells.all? { |r, c| r.between?(0, ROWS - 1) && c.between?(0, COLUMNS - 1) }

          yield cells
        end
      end
    end
    nil
  end
end