class SymbolTable
  def initializer
    @static_table = {}
    @field_table = {}
    @arg_table = {}
    @var_table = {}
  end

  def start_subroutine
    @arg_table = {}
    @var_table = {}
  end

  def define(name, type, kind)
    symbol = {
      type: type,
      kind: kind,
      index: index
    }

    select_table(kind)[name] = symbol
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

  def index_of
    select_table_by_name(name)[:index]
  end

  private

  def select_table(kind)
    case kind
    when 'STATIC'
      then @static_table
    when 'FIELD'
      then @field_table
    when 'ARG'
      then @arg_table
    when 'VAR'
      then @var_table
    end
  end

  def select_table_by_name(name)
    @static_table[name] || @field_table[name] || @arg_table[name] || @var_table[name] || nil
  end
end
