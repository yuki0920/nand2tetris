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

  BASE_ADDRESSES = ['LCL', 'ARG', 'THIS', 'THAT'].freeze

  def initialize(file)
    @file = File.open(file, 'w')
    @label_num = 0
    @return_label_num = 0
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

  def write_init
    write_codes([
      '@256',
      'D=A',
      '@SP',
      'M=D'
    ])
    write_call('Sys.init', 0)
  end

  def write_label(label)
    write_code("(#{function_name_label(label)})")
  end

  def write_goto(label)
    write_codes([
      "@#{function_name_label(label)}",
      '0;JMP'
    ])
  end

  def write_if(label)
    write_codes([
      '@SP',
      'AM=M-1', # SP--, A = *(SP-1)
      'D=M',
      "@#{function_name_label(label)}",
      'D;JNE'
    ])
  end

  def write_call(function_name, num_args)
    label = get_new_return_label

    # 呼び出し元のアドレスをスタックに追加
    write_codes([
      "@#{label}",
      'D=A'
    ])
    write_push_from_d_register # リターンアドレスをスタックに入れる

    BASE_ADDRESSES.each do |address|
      write_codes([
        "@#{address}",
        'D=M'
      ])
      write_push_from_d_register
    end

    write_codes([
      "@#{num_args}",
      'D=A',
      '@5',
      'D=D+A', # D = num_args + 5
      '@SP',
      'D=M-D',
      '@ARG',
      'M=D', # ARG = SP - 5 - num_args
      '@SP',
      'D=M',
      '@LCL',
      'M=D' # LCL = SP
    ])

    write_codes([
      "@#{function_name}",
      '0;JMP',
      "(#{label})"
    ])
  end

  def write_function(function_name, num_args)
    @current_function_name = function_name

    write_codes([
      "(#{function_name})",
      'D=0'
    ])

    num_args.to_i.times do # 引数の個数分、スタックに0を入れる
      write_push_from_d_register
    end
  end

  def write_return
    write_codes([
      '@LCL',
      'D=M',
      '@R13',
      'M=D', # R13 = FRAME = LCL
      '@5',
      'A=D-A',
      'D=M',
      '@R14',
      'M=D', # R14 = RET = *(FRAME - 5)
      '@SP',
      'AM=M-1', # SP--, A = *(SP)
      'D=M', # D = RET = *(FRAME - 1)
      '@ARG',
      'A=M',
      'M=D', # *ARG = *(SP-1)
      '@ARG',
      'D=M+1',
      '@SP',
      'M=D' # SP = ARG + 1
    ])

    BASE_ADDRESSES.reverse.each do |address|
      write_codes([
        '@R13',
        'D=M-1',
        'AM=D', # R13 = FRAME = LCL - 1, A = *(FRAME - 1)
        'D=M',
        "@#{address}",
        'M=D' # *address = *(FRAME-n)
      ])
    end

    write_codes([
      '@R14',
      'A=M',
      '0;JMP' # goto return-address
    ])
  end

  def close
    @file.close
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

  def get_new_if_label
    @if_label_num += 1
    "_IF_LABEL_#{@if_label_num}"
  end

  def get_new_return_label
    @return_label_num += 1
    "_RETURN_LABEL_#{@return_label_num}"
  end

  def function_name_label(label)
    "#{@current_function_name}$#{label}"
  end
end
