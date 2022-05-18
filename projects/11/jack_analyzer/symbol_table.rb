class SymbolTable
  KINDS = ['static', 'field', 'arg', 'var']

  def initialize
    @static_table = {}
    @field_table = {}
    @arg_table = {}
    @var_table = {}
  end

  def start_subroutine
    @arg_table = {}
    @var_table = {}
  end

  def define(name:, type:, kind:)
    unless KINDS.include?(kind)
      raise "Invalid kind: #{kind}"
    end

    table = select_table(kind)
    last_var = table.max_by { |_, v| v[:index] }
    index = last_var ? last_var[1][:index] + 1 : 0

    symbol = {
      type: type,
      kind: kind,
      index: index
    }

    table[name] = symbol
  end

  def var_count(kind)
    select_table(kind).length
  end

  def kind_of(name)
    symbol = select_table_by_name(name)
    symbol[:kind] if symbol
  end

  def type_of(name)
    select_table_by_name(name)[:type]
  end

  def index_of(name)
    select_table_by_name(name)[:index]
  end

  private

  def select_table(kind)
    case kind
    when 'static'
      then @static_table
    when 'field'
      then @field_table
    when 'arg'
      then @arg_table
    when 'var'
      then @var_table
    else
      raise "Invalid kind: #{kind}"
    end
  end

  def select_table_by_name(name)
    @static_table[name] || @field_table[name] || @arg_table[name] || @var_table[name] || nil
  end
end
