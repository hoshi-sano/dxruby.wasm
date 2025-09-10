# frozen_string_literal: true

require "base64"

module DXRubyWasm
  module Input
    def self._init(canvas)
      @@tick = 0
      @@pressing_keys = Hash.new(-1)
      _init_key_events(canvas)
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
  end
end
