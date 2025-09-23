require "dxruby_wasm"

version = DXRubyWasm::VERSION
JS.global[:document].getElementById("dxruby-out")[:innerText] = "DXRubyWasm ver.#{version}"

class Gage < Sprite
  ORIG_IMAGE = Image.load("./200x200.png")
  FLAME_IMAGE = Image.new(100, 20, C_BLACK)
  CURRENT_IMAGE = Image.new(100, 20, C_RED)
  TRIANGLE_IMAGE = Image.new(8, 16).tap { |img|
    img.triangle_fill(0, 0, 8, 16, 0, 16, [120, 120, 120])
  }

  attr_reader :target_image

  def initialize(x, y, init_val)
    super(x, y, FLAME_IMAGE)
    @current = Sprite.new(self.x, self.y, CURRENT_IMAGE)
    @current.z = 10
    @current.center_x = 0
    @current.scale_x = init_val
    @current.collision_enable = false
    @cursor = Sprite.new(self.x, self.y + 20, TRIANGLE_IMAGE)
    calc_cursor_x
    @target_image = ORIG_IMAGE.dup
  end

  def draw
    super
    @current.draw
    @cursor.draw
  end

  def current_scale_x
    @current.scale_x
  end

  def current_scale_x=(v)
    @current.scale_x = v
    calc_cursor_x
  end

  def apply_filter(h, l, s)
    @target_image.copy_rect(0, 0, ORIG_IMAGE)
    @target_image.change_hls(h, l, s)
  end

  def calc_cursor_x
    @cursor.x = self.x + @current.scale_x * self.image.width
  end
end

class MousePointer < Sprite
  def initialize(gage_1, gage_2, gage_3)
    img = Image.new(1, 1)
    super(0, 0, img)
    self.visible = false
    @gage_1 = gage_1
    @gage_2 = gage_2
    @gage_3 = gage_3
  end

  def shot(obj)
    len = self.x - obj.x
    len = 0 if len < 0
    obj.current_scale_x = len / 100.0

    @gage_1.apply_filter(@gage_1.current_scale_x * 360, 0, 0)
    @gage_2.apply_filter(@gage_1.current_scale_x * 360,
                         @gage_2.current_scale_x * 200 - 100, 0)
    @gage_3.apply_filter(@gage_1.current_scale_x * 360,
                         @gage_2.current_scale_x * 200 - 100,
                         @gage_3.current_scale_x * 200 - 100)
  end
end

orig_img = Sprite.new(220, 0, Gage::ORIG_IMAGE.dup)
orig_img.center_y = 0
orig_img.scale_x = 0.3
orig_img.scale_y = 0.3

gage_1 = Gage.new(50, 350, 0)
gage_2 = Gage.new(270, 350, 0.5)
gage_3 = Gage.new(490, 350, 0.5)
gages = [gage_1, gage_2, gage_3]

draw_targets = [orig_img, gage_1, gage_2, gage_3]

pointer = MousePointer.new(*gages)

arrow_image = Image.new(12, 30).tap { |img|
  img.triangle_fill(0, 0, 12, 15, 0, 30, [120, 120, 120])
}

font_1 = Font.new(15)
font_2 = Font.new(20)
labels = [
  ["Original", 290, 65, font_1],
  ["Hue", 80, 305, font_2],
  ["Luminance", 270, 305, font_2],
  ["Saturation", 480, 305, font_2],
]

Window.fps = 30
Window.bgcolor = C_WHITE
Window.loop do
  if Input.mouse_down?(M_LBUTTON)
    pointer.x = Input.mouse_x
    pointer.y = Input.mouse_y
  else
    pointer.x = 0
    pointer.y = 0
  end

  labels.each do |text, x, y, font|
    Window.draw_font(x, y, text, font, color: C_BLACK)
  end
  Window.draw(0, 100, gage_1.target_image)
  Window.draw(205, 170, arrow_image)
  Window.draw(220, 100, gage_2.target_image)
  Window.draw(425, 170, arrow_image)
  Window.draw(440, 100, gage_3.target_image)

  Sprite.check(pointer, gages)
  Sprite.draw(draw_targets)
end
