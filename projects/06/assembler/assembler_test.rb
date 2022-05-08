require_relative './assembler'
require 'minitest/unit'
require 'minitest/autorun'

class TestAssembler < MiniTest::Unit::TestCase
  def setup
    @assembler = Assembler.new
  end

  def test_add
    @assembler.execute('./projects/06/add/Add.asm')
    result = FileUtils.cmp('./projects/06/add/AddTest.hack', './projects/06/add/Add.hack')
    assert_equal true, result
  end

  def test_maxl
    @assembler.execute('./projects/06/max/MaxL.asm')
    result = FileUtils.cmp('./projects/06/max/MaxLTest.hack', './projects/06/max/MaxL.hack')
    assert_equal true, result
  end

  def test_max
    @assembler.execute('./projects/06/max/Max.asm')
    result = FileUtils.cmp('./projects/06/max/MaxTest.hack', './projects/06/max/Max.hack')
    assert_equal true, result
  end

  def test_pongl
    @assembler.execute('./projects/06/pong/PongL.asm')
    result = FileUtils.cmp('./projects/06/pong/PongLTest.hack', './projects/06/pong/PongL.hack')
    assert_equal true, result
  end

  def test_pong
    @assembler.execute('./projects/06/pong/Pong.asm')
    result = FileUtils.cmp('./projects/06/pong/PongTest.hack', './projects/06/pong/Pong.hack')
    assert_equal true, result
  end

  def test_rectl
    @assembler.execute('./projects/06/rect/RectL.asm')
    result = FileUtils.cmp('./projects/06/rect/RectLTest.hack', './projects/06/rect/RectL.hack')
    assert_equal true, result
  end

  def test_rect
    @assembler.execute('./projects/06/rect/Rect.asm')
    result = FileUtils.cmp('./projects/06/rect/RectTest.hack', './projects/06/rect/Rect.hack')
    assert_equal true, result
  end
end
