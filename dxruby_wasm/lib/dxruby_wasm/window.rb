# frozen_string_literal: true

module DXRubyWasm
  module Window
    @@width = 640
    @@height = 480
    @@block = nil
    @@root_canvas_image = nil
    @@bgcolor = Constants::Colors::C_BLACK

    # Start main loop
    def self.loop(&block)
      already_running = !!@@block
      @@block = block
      return if already_running
      JS.global[:window].requestAnimationFrame { |time| _loop(time) }
    end

    def self.draw(x, y, image, z = 0)
      enqueue_draw(z, :image, x, y, image)
    end

    def self.draw_ex(x, y, image, options = {})
      z = options[:z] || 0
      enqueue_draw(z, :draw_ex, x, y, image, options)
    end

    def self.draw_font(x, y, text, font, options = {})
      z = options[:z] || 0
      enqueue_draw(z, :font, x, y, text, font, options)
    end

    def self.enqueue_draw(z, *args)
      @@draw_queue.push([z, @@draw_queue.length, *args])
    end

    def self.width
      @@width
    end

    def self.width=(w)
      @@width = w || JS.global[:window][:innerWidth]
      canvas = _root_canvas
      canvas[:width] = @@width
      canvas[:style][:width] = @@width
    end

    def self.height
      @@height
    end

    def self.height=(w)
      @@height = w || JS.global[:window][:innerHeight]
      canvas = _root_canvas
      canvas[:height] = @@height
      canvas[:style][:height] = @@height
    end

    def self.bgcolor
      @@bgcolor
    end

    def self.bgcolor=(color)
      @@bgcolor = color
    end

    def self._root_canvas
      JS.global[:document].getElementById("dxruby-canvas")
    end

    def self._loop(timestamp)
      @@root_canvas_image ||= _init

      Input._on_tick

      @@draw_queue = []

      @@block.call

      @@root_canvas_image.box_fill(0, 0, @@width, @@height, @@bgcolor)
      _drain_draw_queue

      JS.global[:window].requestAnimationFrame { |time| _loop(time) }
    end

    def self._init
      canvas = _root_canvas
      ctx = canvas.getContext("2d")
      self.width = @@width
      self.height = @@height
      img = Image.new(self.width, self.height, canvas: canvas)
      Input._init(canvas)
      img
    end

    def self._drain_draw_queue
      @@draw_queue.sort { |a, b|
        if a[0] == b[0]
          a[1] <=> b[1] # sort by queued order
        else
          a[0] <=> b[0] # sort by z
        end
      }.each { |item|
        args = item[3..]
        case item[2]
        when :image then @@root_canvas_image.draw(*args)
        when :draw_ex then @@root_canvas_image.draw_ex(*args)
        when :font then @@root_canvas_image.draw_font_ex(*args)
        end
      }
    end
  end
end
