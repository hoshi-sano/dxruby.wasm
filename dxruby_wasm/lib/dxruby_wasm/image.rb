# frozen_string_literal: true

module DXRubyWasm
  class Image
    attr_reader :canvas, :width, :height

    def self.load(path_or_url)
      new(1, 1).load(path_or_url)
    end

    def initialize(width, height, color = C_DEFAULT, canvas: nil)
      @width, @height = width, height
      @canvas = canvas || JS.global[:document].createElement("canvas")
      @ctx = @canvas.getContext("2d")
      resize(@width, @height)
      box_fill(0, 0, @width, @height, color)
    end

    def load(path_or_url)
      img = JS.global[:Image].new(1, 1)
      # TODO: load from wasi file system
      img[:src] = path_or_url

      img.decode.then {
        img[:width] = img[:naturalWidth]
        img[:height] = img[:naturalHeight]
        # TODO: update img.style.width, img.style.height here ?
        resize(img[:naturalWidth], img[:naturalHeight])
        @ctx.drawImage(img, 0, 0)
      }.catch { |e|
        raise DXRubyWasm::Error, "Failed to load image: #{path_or_url}"
      }
      self
    end

    def draw(x, y, image)
      @ctx.drawImage(image.canvas, x, y)
      self
    end

    def box_fill(x1, y1, x2, y2, color)
      @ctx.beginPath()
      @ctx[:fillStyle] = to_css_color_string(color)
      @ctx.fillRect(x1, y1, x2-x1, y2-y1)
      @ctx.closePath()
      self
    end

    private

    def resize(w, h)
      @width, @height = w, h
      @canvas[:width] = w
      @canvas[:height] = h
    end

    def to_css_color_string(color)
      a, r, g, b = *color
      "rgb(#{r} #{g} #{b} / #{a / 255.0})"
    end
  end
end
