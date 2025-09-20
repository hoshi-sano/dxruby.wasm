# frozen_string_literal: true

require "base64"

module DXRubyWasm
  module Input
    JS_FALSE = JS.eval("return false")

    def self._init(canvas)
      @@tick = 0
      @@pressing_keys = {}
      @@mouse_x = 0
      @@mouse_y = 0
      @@pressing_buttons = {}

      _init_key_events(canvas)
      _init_mouse_events(canvas)
      _init_touch_events(canvas)
    end

    # Called on every frame from Window
    def self._on_tick
      @@tick += 1
      _reset_cache
    end

    def self._init_key_events(canvas)
      canvas.setAttribute("tabindex", 0)
      canvas.addEventListener("keydown") do |event|
        @@pressing_keys[event[:code].to_s] = @@tick if event[:repeat] == JS_FALSE
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

    def self._init_touch_events(canvas)
      canvas_id = canvas[:id]
      JS.eval(<<~JAVASCRIPT)
        window._touchPoints = [];

        function updateTouchPoints(event) {
          event.preventDefault();
          const rect = canvas.getBoundingClientRect();
          window._touchPoints = Array.from(event.touches).map(touch => {
            return { x: touch.clientX - rect.left, y: touch.clientY - rect.top };
          });
        }

        canvas = document.getElementById("#{canvas_id}");

        canvas.addEventListener('touchstart', updateTouchPoints, { passive: false });
        canvas.addEventListener('touchmove', updateTouchPoints, { passive: false });
        canvas.addEventListener('touchend', updateTouchPoints, { passive: false });
        canvas.addEventListener('touchcancel', updateTouchPoints, { passive: false });

        window.getTouchPoints = () => {
          return window._touchPoints;
        };
      JAVASCRIPT
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
      (@@pressing_keys[code] || 0) > 0
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
      (@@pressing_buttons[button] || 0) > 0
    end

    def self.mouse_push?(button)
      @@pressing_buttons[button] == @@tick - 1
    end

    def self.mouse_release?(button)
      @@pressing_buttons[button] == -(@@tick - 1)
    end

    class Touch
      attr_reader :x, :y

      def initialize(x, y)
        @x = x
        @y = y
      end
    end

    def self.touches
      @touches ||= JS.global.getTouchPoints.to_a.map do |touch|
        Touch.new(touch[:x].to_i, touch[:y].to_i)
      end
    end

    def self.touch_count
      touches.length
    end

    def self.touch_pos_x
      touches.first&.x
    end

    def self.touch_pos_y
      touches.first&.y
    end

    def self._reset_cache
      @touches = nil
    end
  end
end
