# frozen_string_literal: true

module DXRubyWasm
  module Window
    extend DXRubyWasm::RenderMethods

    @width = 640
    @height = 480
    @block = nil
    @image = nil
    @bgcolor = Constants::Colors::C_BLACK
    @fps = 60
    @real_fps = 0

    # Start main loop
    def self.loop(&block)
      already_running = !!@block
      @block = block
      return if already_running

      Fiber.new { _loop }.transfer
    end

    def self.width
      @width
    end

    def self.width=(w)
      @width = w || JS.global[:window][:innerWidth].to_i
      canvas = _root_canvas
      canvas[:width] = @width
      canvas[:style][:width] = @width
    end

    def self.height
      @height
    end

    def self.height=(w)
      @height = w || JS.global[:window][:innerHeight].to_i
      canvas = _root_canvas
      canvas[:height] = @height
      canvas[:style][:height] = @height
    end

    def self.fps
      @fps
    end

    def self.fps=(fps)
      @fps = fps
    end

    def self.real_fps
      @real_fps
    end

    def self._root_canvas
      JS.global[:document].getElementById("dxruby-canvas")
    end

    def self._loop
      @image ||= _init

      interval = 1000.0 / @fps
      last_time = 0.0

      # For FPS calculation
      frame_count = 0
      last_fps_update_time = 0.0

      while true
        current_time = _animation_frame_promise.await.to_f
        if last_time == 0.0
          last_time = current_time
          last_fps_update_time = current_time
        end

        delta = current_time - last_time

        if delta >= interval
          last_time = current_time - (delta % interval)

          Input._on_tick

          @draw_queue = []

          @block.call

          @image.box_fill(0, 0, @width, @height, @bgcolor)
          drain_draw_queue
          RenderTarget._late_tick_all

          # FPS calculation
          frame_count += 1
          if (current_time - last_fps_update_time) >= 1000.0
            @real_fps = frame_count
            frame_count = 0
            last_fps_update_time += 1000.0
          end
        end
      end
    end

    def self._animation_frame_promise
      JS.global[:Promise].new do |resolve|
        JS.global[:window].requestAnimationFrame do |timestamp|
          resolve.apply(timestamp)
        end
      end
    end

    def self._init
      canvas = _root_canvas
      ctx = canvas.getContext("2d")
      self.width = @width
      self.height = @height
      img = Image.new(self.width, self.height, canvas: canvas)
      Input._init(canvas)
      img
    end
  end
end
