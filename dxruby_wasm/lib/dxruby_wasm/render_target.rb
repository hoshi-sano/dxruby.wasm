# frozen_string_literal: true

require "weakref"

module DXRubyWasm
  class RenderTarget
    include RenderMethods

    def self._push_instance(rt)
      @all_instances ||= []
      @all_instances << WeakRef.new(rt)
    end

    # Called at the end of every frame from Window
    def self._late_tick_all
      @all_instances ||= []
      @all_instances.select!(&:weakref_alive?)
      @all_instances.each do |i|
        i._force_discard
      rescue WeakRef::RefError
        next
      end
    end

    attr_reader :width, :height, :bgcolor, :x, :y

    def initialize(width, height, bgcolor = C_DEFAULT)
      @width = width
      @height = height
      @bgcolor = bgcolor
      @image = Image.new(@width, @height)
      @draw_queue = []
      @x = 0
      @y = 0
      self.class._push_instance(self)
    end

    def canvas
      @image.canvas
    end

    def update
      @image.clear
      @image.box_fill(0, 0, @width, @height, @bgcolor)
      drain_draw_queue
    end

    def to_image
      @image.dup
    end

    def _force_discard
      @draw_queue = []
    end

    def _render_pos(x, y)
      @x = x
      @y = y
    end
  end
end
