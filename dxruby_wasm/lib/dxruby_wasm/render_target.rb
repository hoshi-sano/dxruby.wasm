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

    def initialize(width, height, bgcolor = C_DEFAULT)
      @width = width
      @height = height
      @bgcolor = bgcolor
      @image = Image.new(@width, @height)
      @draw_queue = []
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

    def _force_discard
      @draw_queue = []
    end
  end
end
