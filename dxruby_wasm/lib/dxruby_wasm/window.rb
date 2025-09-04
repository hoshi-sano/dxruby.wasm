# frozen_string_literal: true

module DXRubyWasm
  module Window
    extend DXRubyWasm::RenderMethods

    @width = 640
    @height = 480
    @block = nil
    @image = nil
    @bgcolor = Constants::Colors::C_BLACK

    # Start main loop
    def self.loop(&block)
      already_running = !!@block
      @block = block
      return if already_running
      JS.global[:window].requestAnimationFrame { |time| _loop(time) }
    end

    def self.width
      @width
    end

    def self.width=(w)
      @width = w || JS.global[:window][:innerWidth]
      canvas = _root_canvas
      canvas[:width] = @width
      canvas[:style][:width] = @width
    end

    def self.height
      @height
    end

    def self.height=(w)
      @height = w || JS.global[:window][:innerHeight]
      canvas = _root_canvas
      canvas[:height] = @height
      canvas[:style][:height] = @height
    end

    def self._root_canvas
      JS.global[:document].getElementById("dxruby-canvas")
    end

    def self._loop(timestamp)
      @image ||= _init

      Input._on_tick

      @draw_queue = []

      @block.call

      @image.box_fill(0, 0, @width, @height, @bgcolor)
      drain_draw_queue
      RenderTarget._late_tick_all

      JS.global[:window].requestAnimationFrame { |time| _loop(time) }
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
