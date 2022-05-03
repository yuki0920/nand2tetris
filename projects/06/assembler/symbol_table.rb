class SymbolTable
  attr_reader :entries

  def initialize
    @entries = {}
  end

  def add_entry(symbol, address)
    @entries[symbol] = address
  end

  def contains?(symbol)
    @entries.key?(symbol)
  end

  def get_address(symbol)
    @entries[symbol]
  end
end
