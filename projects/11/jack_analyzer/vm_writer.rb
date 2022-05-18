class VMWriter
  SEGMENTS = %w(
    constant
    local
    argument
    static
    this
    that
    temp
    pointer
  ).freeze

  ARISMETICS = %w(
    add
    sub
    neg
    eq
    gt
    lt
    and
    or
    not
  )

  def initialize(output_file)
    @output_file = File.open(output_file, 'w')
  end

  def write_push(segment, index)
    unless SEGMENTS.include?(segment)
      raise "Invalid segment: #{segment}"
    end

    @output_file.puts("push #{segment} #{index}")
  end

  def write_pop(segment, index)
    unless SEGMENTS.include?(segment)
      raise "Invalid segment: #{segment}"
    end

    @output_file.puts("pop #{segment} #{index}")
  end

  def write_arithmetic(command)
    unless ARISMETICS.include?(command)
      raise "Invalid command: #{command}"
    end

    @output_file.puts(command)
  end

  def write_label(label)
    @output_file.puts("label #{label}")
  end

  def write_goto(label)
    @output_file.puts("goto #{label}")
  end

  def write_if(label)
    @output_file.puts("if-goto #{label}")
  end

  def write_call(name, number_of_args)
    @output_file.puts("call #{name} #{number_of_args}")
  end

  def write_function(name, number_of_locals)
    @output_file.puts("function #{name} #{number_of_locals}")
  end

  def write_return
    @output_file.puts('return')
  end

  def close
    @output_file.close
  end
end
