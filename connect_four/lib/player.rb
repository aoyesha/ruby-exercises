class Player
  attr_reader :name, :symbol

  def initialize(name, symbol)
    @name   = name
    @symbol = symbol
  end

  def to_s
    "#{name} (#{symbol})"
  end
end