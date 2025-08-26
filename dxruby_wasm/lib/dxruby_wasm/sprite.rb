# frozen_string_literal: true

module DXRubyWasm
  class Sprite
    attr_accessor :x
    attr_accessor :y
    attr_reader :image
    attr_accessor :z
    attr_accessor :angle
    attr_accessor :scale_x
    attr_accessor :scale_y
    attr_accessor :center_x
    attr_accessor :center_y
    attr_accessor :alpha
    attr_accessor :blend
    attr_accessor :shader
    attr_accessor :target
    attr_accessor :collision
    attr_accessor :collision_enable
    attr_accessor :collision_sync
    attr_accessor :visible

    # TODO:
    # def check(o_sprites, d_sprites, shot = :shot, hit = :hit)
    # end

    def self.update(sprites)
      sprites.each do |sprite|
        next if !sprite.respond_to?(:update)
        next if sprite.respond_to?(:vanished?) && sprite.vanished?
        sprite.update
      end
    end

    def self.clean(sprites)
      sprites.reject! { |sprite| sprite.nil? || sprite.vanished? }
    end

    def self.draw(sprites)
      sprites.flatten.sort_by(&:z).each do |sprite|
        next if sprite.respond_to?(:vanished?) && sprite.vanished?
        sprite.draw
      end
    end

    def initialize(x = 0, y = 0, image = nil)
      @x = x
      @y = y
      @image = image

      @z = 0
      @collision_enable = true
      @collision_sync = true
      @visible = true
      @vanished = false

      calc_center
    end

    def draw
      return if !@visible || vanished?

      Window.draw_ex(@x, @y, @image,
                     scale_x: @scale_x, scale_y: @scale_y,
                     alpha: @alpha, blend: @blend,
                     angle: @angle, center_x: @center_x, center_y: @center_y)
    end

    def vanish
      @vanished = true
    end

    def vanished?
      return @vanished
    end

    def image=(img)
      @image = img
      calc_center
    end

    private

    def calc_center
      if @image
        @center_x = @image.width / 2
        @center_y = @image.height / 2
      else
        @center_x = 0
        @center_y = 0
      end
    end
  end
end
