class CodeWriter
  REFERENCED_SEGMENTS = {
    'local' => 'LCL',
    'argument' => 'ARG',
    'this' => 'THIS',
    'that' => 'THAT'
  }.freeze

  STATIC_SEGMENTS = {
    'pointer' => 3,
    'temp' => 5
  }.freeze

  def initialize(file)
    @file = File.open(file, 'w')
    @label_num = 0 # what
  end

  def set_file_name(file_name)
    @file_name = File.basename(file_name, '.vm')
  end

  def write_aristhmetic(command)
    case command
    when 'add', 'sub', 'and', 'or'
      write_binary_operation(command)
    when 'neg', 'not'
      write_unary_operation(command)
    when 'eq', 'gt', 'lt'
      write_comp_operation(command)
    end
  end

  def write_push(command, segment, index)
    if segment == 'constant'
      write_codes([
        "@#{index}",
        'D=A'
      ])
      write_push_from_d_register
    elsif REFERENCED_SEGMENTS.keys.include?(segment)
      write_push_from_referenced_segment(segment, index)
    elsif STATIC_SEGMENTS.keys.include?(segment)
      write_push_from_fixed_segment(segment, index)
    elsif segment == 'static'
      write_codes([
        "@#{@file_name}.#{index}",
        'D=M'
      ])
      write_push_from_d_register
    end
  end

  def write_pop(command, segment, index)
    if REFERENCED_SEGMENTS.keys.include?(segment)
      write_pop_to_referenced_segment(segment, index)
    elsif STATIC_SEGMENTS.keys.include?(segment)
      write_pop_to_fixed_segment(segment, index)
    elsif segment == 'static'
      write_pop_to_a_register
      write_codes([
        'D=M',
        "@#{@file_name}.#{index}",
        'M=D'
      ])
    end
  end

  private

  def write_binary_operation(command)
    write_pop_to_a_register
    write_code('D=M')
    write_pop_to_a_register

    case command
    when 'add'
      write_code('D=D+M')
    when 'sub'
      write_code('D=M-D')
    when 'and'
      write_code('D=D&M')
    when 'or'
      write_code('D=D|M')
    end
    write_push_from_d_register
  end

  def write_unary_operation(command)
    write_codes([
      '@SP',
      'A=M-1'
    ])

    case command
    when 'neg'
      write_code('M=-M')
    when 'not'
      write_code('M=!M')
    end
  end

  def write_comp_operation(command)
    write_pop_to_a_register
    write_code('D=M')
    write_pop_to_a_register
    l1 = get_new_label
    l2 = get_new_label

    case command
    when 'eq'
      comp_type = 'JEQ'
    when 'gt'
      comp_type = 'JGT'
    when 'lt'
      comp_type = 'JLT'
    end
    write_codes([
      'D=M-D',
      "@#{l1}",
      "D;#{comp_type}",
      'D=0',
      "@#{l2}",
      '0;JMP',
      "(#{l1})",
      'D=-1',
      "(#{l2})",
    ])
    write_push_from_d_register
  end

  def write_push_from_referenced_segment(segment, index)
    base_address = REFERENCED_SEGMENTS[segment]

    write_codes([
      "@#{base_address}",
      'A=M'
    ])
    index.to_i.times do
      write_code('A=A+1')
    end
    write_code('D=M')
    write_push_from_d_register
  end

  def write_pop_to_referenced_segment(segment, index)
    base_address = REFERENCED_SEGMENTS[segment]

    write_pop_to_a_register
    write_codes([
      'D=M',
      "@#{base_address}",
      'A=M'
    ])
    index.to_i.times do
      write_code('A=A+1')
    end
    write_code('M=D')
  end

  def write_push_from_fixed_segment(segment, index)
    base_address = STATIC_SEGMENTS[segment]

    write_code("@#{base_address}")
    index.to_i.times do
      write_code('A=A+1')
    end
    write_code('D=M')
    write_push_from_d_register
  end

  def write_pop_to_fixed_segment(segment, index)
    base_address = STATIC_SEGMENTS[segment]

    write_pop_to_a_register
    write_codes([
      'D=M',
      "@#{base_address}"
    ])
    index.to_i.times do
      write_code('A=A+1')
    end
    write_code('M=D')
  end

  def write_push_from_d_register # スタックに格納されたアドレスへ移動しDレジスタの値を格納。スタックポインタを進める
    write_codes([
      '@SP',
      'A=M',
      'M=D',
      '@SP',
      'M=M+1'
    ])
  end

  def write_pop_to_a_register # スタックポインタを戻し、スタックに格納されたアドレスへ移動
    write_codes([
      '@SP',
      'M=M-1',
      'A=M'
    ])
  end

  def close
    @file.close
  end

  def write_code(code)
    @file.write("#{code}\n")
  end

  def write_codes(codes)
    codes.each do |code|
      write_code(code)
    end
  end

  def get_new_label
    @label_num += 1
    "LABEL#{@label_num}"
  end
end
