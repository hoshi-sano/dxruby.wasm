# frozen_string_literal: true

require "base64"

module DXRubyWasm
  module Input
    def self._init(canvas)
      @@tick = 0
      @@pressing_keys = Hash.new(-1)
      @@mouse_x = 0
      @@mouse_y = 0
      @@pressing_buttons = Hash.new(-1)

      _init_key_events(canvas)
      _init_mouse_events(canvas)
    end

    # Called on every frame from Window
    def self._on_tick
      @@tick += 1
    end

    def self._init_key_events(canvas)
      canvas.setAttribute("tabindex", 0)
      canvas.addEventListener("keydown") do |event|
        @@pressing_keys[event[:code].to_s] = @@tick
        event.preventDefault
        event.stopPropagation
      end
      canvas.addEventListener("keyup") do |event|
        @@pressing_keys[event[:code].to_s] = -@@tick
        event.preventDefault
        event.stopPropagation
      end
    end

    def self._init_mouse_events(canvas)
      canvas.addEventListener("mousemove") do |event|
        @@mouse_x = event[:offsetX].to_i
        @@mouse_y = event[:offsetY].to_i
      end
      canvas.addEventListener("mousedown") do |event|
        @@pressing_buttons[event[:button].to_i] = @@tick
      end
      canvas.addEventListener("mouseup") do |event|
        @@pressing_buttons[event[:button].to_i] = -@@tick
      end
      canvas.addEventListener("contextmenu") do |event|
        event.preventDefault
      end
    end

    def self.x(_pad_number = 0)
      ret = 0
      ret += 1 if key_down?(K_RIGHT)
      ret -= 1 if key_down?(K_LEFT)
      ret
    end

    def self.y(_pad_number = 0)
      ret = 0
      ret += 1 if key_down?(K_DOWN)
      ret -= 1 if key_down?(K_UP)
      ret
    end

    def self.key_down?(code)
      @@pressing_keys[code] > 0
    end

    def self.key_push?(code)
      @@pressing_keys[code] == @@tick - 1
    end

    def self.key_release?(code)
      @@pressing_keys[code] == -(@@tick - 1)
    end

    def self.keys
      @@pressing_keys.select { |code, v| v > 0 }.keys
    end

    def self.mouse_x
      @@mouse_x
    end

    def self.mouse_y
      @@mouse_y
    end

    def self.mouse_down?(button)
      @@pressing_buttons[button] > 0
    end

    def self.mouse_push?(button)
      @@pressing_buttons[button] == @@tick - 1
    end

    def self.mouse_release?(button)
      @@pressing_buttons[button] == -(@@tick - 1)
    end
  end
end
