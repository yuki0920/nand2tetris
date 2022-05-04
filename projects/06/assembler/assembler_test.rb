require_relative './assembler'
require 'minitest/unit'
require 'minitest/autorun'

class TestAssembler < MiniTest::Unit::TestCase
  def setup
    @assembler = Assembler.new
  end

  def test_add
    @assembler.execute('./projects/06/add/Add.asm')
    result = FileUtils.cmp('./projects/06/add/Add.hack', './projects/06/add/Add1.hack')
    assert_equal true, result
  end

  def test_maxl
    @assembler.execute('./projects/06/max/MaxL.asm')
    result = FileUtils.cmp('./projects/06/max/MaxL.hack', './projects/06/max/MaxL1.hack')
    assert_equal true, result
  end

  def test_max
    @assembler.execute('./projects/06/max/Max.asm')
    result = FileUtils.cmp('./projects/06/max/Max.hack', './projects/06/max/Max1.hack')
    assert_equal true, result
  end

  def test_pongl
    @assembler.execute('./projects/06/pong/PongL.asm')
    result = FileUtils.cmp('./projects/06/pong/PongL.hack', './projects/06/pong/PongL1.hack')
    assert_equal true, result
  end

  def test_pong
    @assembler.execute('./projects/06/pong/Pong.asm')
    result = FileUtils.cmp('./projects/06/pong/Pong.hack', './projects/06/pong/Pong1.hack')
    assert_equal true, result
  end

  def test_rectl
    @assembler.execute('./projects/06/rect/RectL.asm')
    result = FileUtils.cmp('./projects/06/rect/RectL.hack', './projects/06/rect/RectL1.hack')
    assert_equal true, result
  end

  def test_rect
    @assembler.execute('./projects/06/rect/Rect.asm')
    result = FileUtils.cmp('./projects/06/rect/Rect.hack', './projects/06/rect/Rect1.hack')
    assert_equal true, result
  end
end
