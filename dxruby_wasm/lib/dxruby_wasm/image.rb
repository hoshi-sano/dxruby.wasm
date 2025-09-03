# frozen_string_literal: true

require "base64"

module DXRubyWasm
  class Image
    attr_reader :canvas, :ctx, :width, :height

    BLEND_TYPES = {
      alpha: "source-over",
      add:   "lighter",
    }
    FILE_HEADERS = {
      png: "\x89PNG\r\n\x1A\n".b,
      jpeg: "\xFF\xD8\xFF".b,
      bmp: "BM".b,
    }
    private_constant :FILE_HEADERS
    MIME_TYPES = {
      png: "image/png",
      jpeg: "image/jpeg",
      bmp: "image/bmp",
    }
    private_constant :MIME_TYPES

    def self.load(path_or_url)
      new(1, 1).load(path_or_url)
    end

    def self.load_tiles(path_or_url, xcount, ycount)
      orig_image = load(path_or_url)
      w = orig_image.width / xcount
      h = orig_image.height / ycount

      res = []

      ycount.times do |iy|
        xcount.times do |ix|
          image_data = orig_image.ctx.getImageData(w * ix, h * iy, w, h)
          new_image = new(w, h)
          new_image.ctx.putImageData(image_data, 0, 0)
          res << new_image
        end
      end

      res
    end

    def dup
      res = self.class.new(@width, @height)
      res.ctx.putImageData(@ctx.getImageData(0, 0, @width, @height), 0, 0)
      res
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
      if File.exist?(path_or_url)
        # load from wasi file system
        img[:src] = base64_image_data(path_or_url)
      else
        # load from remote
        img[:src] = path_or_url
      end

      begin
        img.decode.await
      rescue => e
        msg = "Failed to load image. path: #{path_or_url}"
        msg += ", message: #{e.message}" unless e.message.to_s.empty?
        raise DXRubyWasm::Error, msg
      end

      img[:width] = img[:naturalWidth].to_i
      img[:height] = img[:naturalHeight].to_i
      # TODO: update img.style.width, img.style.height here ?
      resize(img[:naturalWidth].to_i, img[:naturalHeight].to_i)
      @ctx.drawImage(img, 0, 0)

      self
    end

    def draw(x, y, image)
      @ctx.drawImage(image.canvas, x, y)
      self
    end

    def draw_ex(x, y, image, options = {})
      scale_x = options[:scale_x] || 1
      scale_y = options[:scale_y] || 1
      center_x = options[:center_x] || image.width / 2
      center_y = options[:center_y] || image.height / 2
      alpha = options[:alpha] || 255
      blend = options[:blend] || :alpha
      angle = options[:angle] || 0

      cx = x + center_x
      cy = y + center_y

      @ctx.translate(cx, cy)
      @ctx.rotate(angle * Math::PI / 180.0)
      @ctx.scale(scale_x, scale_y)
      @ctx.save()
      @ctx[:globalAlpha] = alpha / 255
      @ctx[:globalCompositeOperation] = BLEND_TYPES[blend]
      @ctx.drawImage(image.canvas, x - cx, y - cy)
      @ctx.restore()
      @ctx.setTransform(1, 0, 0, 1, 0, 0)
      self
    end

    def line(x1, y1, x2, y2, color)
      @ctx.beginPath()
      @ctx[:strokeStyle] = to_css_color_string(color)
      @ctx.moveTo(x1, y1)
      @ctx.lineTo(x2, y2)
      @ctx.stroke()
      @ctx.closePath()
      self
    end

    def box(x1, y1, x2, y2, color)
      @ctx.beginPath()
      @ctx[:strokeStyle] = to_css_color_string(color)
      @ctx.rect(x1, y1, x2-x1, y2-y1)
      @ctx.stroke()
      @ctx.closePath()
      self
    end

    def box_fill(x1, y1, x2, y2, color)
      @ctx.beginPath()
      @ctx[:fillStyle] = to_css_color_string(color)
      @ctx.fillRect(x1, y1, x2-x1, y2-y1)
      @ctx.closePath()
      self
    end

    def circle(x, y, r, color)
      @ctx.beginPath()
      @ctx[:strokeStyle] = to_css_color_string(color)
      @ctx.arc(x, y, r, 0, Math::PI * 2, false)
      @ctx.stroke()
      @ctx.closePath()
      self
    end

    def circle_fill(x, y, r, color)
      @ctx.beginPath()
      @ctx[:fillStyle] = to_css_color_string(color)
      @ctx.arc(x, y, r, 0, Math::PI * 2, false)
      @ctx.fill()
      @ctx.closePath()
      self
    end

    def triangle(x1, y1, x2, y2, x3, y3, color)
      @ctx.beginPath()
      @ctx[:strokeStyle] = to_css_color_string(color)
      @ctx.moveTo(x1, y1)
      @ctx.lineTo(x2, y2)
      @ctx.lineTo(x3, y3)
      @ctx.lineTo(x1, y1)
      @ctx.stroke()
      @ctx.closePath()
      self
    end

    def triangle_fill(x1, y1, x2, y2, x3, y3, color)
      @ctx.beginPath()
      @ctx[:fillStyle] = to_css_color_string(color)
      @ctx.moveTo(x1, y1)
      @ctx.lineTo(x2, y2)
      @ctx.lineTo(x3, y3)
      @ctx.fill()
      @ctx.closePath()
      self
    end

    def fill(color)
      box_fill(0, 0, @width, @height, color)
    end

    def clear
      fill([0, 0, 0, 0])
    end

    def draw_font(x, y, text, font, color = [255, 255, 255])
      draw_font_ex(x, y, text, font, { color: color })
      self
    end

    def draw_font_ex(x, y, text, font, option = {})
      @ctx[:font] = font.to_css_font_string
      @ctx[:textBaseline] = "top"
      @ctx[:fillStyle] = to_css_color_string(option[:color] || [255, 255, 255])
      # TODO: Use other options besides :color
      @ctx.fillText(text, x, y)
      self
    end

    private

    def base64_image_data(file_path)
      file_content = File.open(file_path, "rb").read
      header = file_content[0, 8]
      mime_type = nil
      FILE_HEADERS.each do |type, h|
        if header.start_with?(h)
          mime_type = MIME_TYPES[type]
          break
        end
      end
      return "data:#{mime_type};base64,#{Base64.encode64(file_content)}" if mime_type

      raise DXRubyWasm::Error, "Only PNG, JPEG, and BMP files are supported."
    rescue => e
      raise DXRubyWasm::Error, e.message
    end

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
