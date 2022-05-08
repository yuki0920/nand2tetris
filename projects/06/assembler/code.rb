class Code
  COMP = {
    '0' => '0101010',
    '1' => '0111111',
    '-1' => '0111010',
    'D' => '0001100',
    'A' => '0110000',
    '!D' => '0001101',
    '!A' => '0110001',
    '-D' => '0001111',
    '-A' => '0110011',
    'D+1' => '0011111',
    'A+1' => '0110111',
    'D-1' => '0001110',
    'A-1' => '0110010',
    'D+A' => '0000010',
    'D-A' => '0010011',
    'A-D' => '0000111',
    'D&A' => '0000000',
    'D|A' => '0010101',
    'M' => '1110000',
    '!M' => '1110001',
    '-M' => '1110011',
    'M+1' => '1110111',
    'M-1' => '1110010',
    'D+M' => '1000010',
    'D-M' => '1010011',
    'M-D' => '1000111',
    'D&M' => '1000000',
    'D|M' => '1010101'
  }.freeze

  JUMP = {
    'JGT' => '001',
    'JEQ' => '010',
    'JGE' => '011',
    'JLT' => '100',
    'JNE' => '101',
    'JLE' => '110',
    'JMP' => '111'
  }.freeze

  def initialize(parser)
    @parser = parser
  end

  def generate_compute_command
    "111#{comp}#{dest}#{jump}"
  end

  def dest
    str = '000'
    return str if @parser.dest.nil?

    @parser.dest.each_char do |c|
      case c
      when 'A'
        str[0] = '1'
      when 'D'
        str[1] = '1'
      when 'M'
        str[2] = '1'
      end
    end

    str
  end

  def comp
    COMP[@parser.comp]
  end

  def jump
    return '000' if @parser.jump.nil?

    JUMP[@parser.jump]
  end
end
