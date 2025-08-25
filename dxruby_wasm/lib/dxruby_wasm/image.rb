# frozen_string_literal: true

require "base64"

module DXRubyWasm
  class Image
    attr_reader :canvas, :width, :height

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
        msg += "message: #{e.message}" unless e.message.to_s.empty?
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

    def box_fill(x1, y1, x2, y2, color)
      @ctx.beginPath()
      @ctx[:fillStyle] = to_css_color_string(color)
      @ctx.fillRect(x1, y1, x2-x1, y2-y1)
      @ctx.closePath()
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
