# frozen_string_literal: true

module DXRubyWasm
  module RenderMethods
    def bgcolor
      @bgcolor
    end

    def bgcolor=(color)
      @bgcolor = color
    end

    def draw(x, y, image, z = 0)
      enqueue_draw(z, :image, x, y, image)
    end

    def draw_ex(x, y, image, options = {})
      z = options[:z] || 0
      enqueue_draw(z, :draw_ex, x, y, image, options)
    end

    def draw_font(x, y, text, font, options = {})
      z = options[:z] || 0
      enqueue_draw(z, :font, x, y, text, font, options)
    end

    def enqueue_draw(z, *args)
      @draw_queue.push([z, @draw_queue.length, *args])
    end

    def drain_draw_queue
      @draw_queue.sort { |a, b|
        if a[0] == b[0]
          a[1] <=> b[1] # sort by queued order
        else
          a[0] <=> b[0] # sort by z
        end
      }.each { |item|
        args = item[3..]
        case item[2]
        when :image then @image.draw(*args)
        when :draw_ex then @image.draw_ex(*args)
        when :font then @image.draw_font_ex(*args)
        end
      }
    end
  end
end
