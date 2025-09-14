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

    def draw_pixel(x, y, color, z = 0)
      # TODO:
      raise
    end

    def draw_line(x1, y1, x2, y2, color, z = 0)
      enqueue_draw(z, :line, x1, y1, x2, y2, color)
    end

    def draw_box(x1, y1, x2, y2, color, z = 0)
      enqueue_draw(z, :box, x1, y1, x2, y2, color)
    end

    def draw_box_fill(x1, y1, x2, y2, color, z = 0)
      enqueue_draw(z, :box_fill, x1, y1, x2, y2, color)
    end

    def draw_circle(x, y, r, color, z = 0)
      enqueue_draw(z, :circle, x, y, r, color)
    end

    def draw_circle_fill(x, y, r, color, z = 0)
      enqueue_draw(z, :circle_fill, x, y, r, color)
    end

    def draw_triangle(x1, y1, x2, y2, x3, y3, color, z = 0)
      enqueue_draw(z, :triangle, x1, y1, x2, y2, x3, y3, color)
    end

    def draw_triangle_fill(x1, y1, x2, y2, x3, y3, color, z = 0)
      enqueue_draw(z, :triangle_fill, x1, y1, x2, y2, x3, y3, color)
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
        when :pixel then raise # TODO:
        when :line then @image.line(*args)
        when :box then @image.box(*args)
        when :box_fill then @image.box_fill(*args)
        when :circle then @image.circle(*args)
        when :circle_fill then @image.circle_fill(*args)
        when :triangle then @image.triangle(*args)
        when :triangle_fill then @image.triangle_fill(*args)
        end
      }
    end
  end
end
