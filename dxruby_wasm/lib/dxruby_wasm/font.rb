# frozen_string_literal: true

module DXRubyWasm
  class Font
    attr_reader :size, :fontname, :weight, :italic, :auto_fitting

    FILE_HEADERS = {
      ttf: "\x00\x01\x00\x00",
      otf: "\x4f\x54\x54\x4f",
      woff: "\x77\x4f\x46\x46",
      woff2: "\x77\x4f\x46\x32",
      eot: "\x4c\x50",
    }
    private_constant :FILE_HEADERS
    MIME_TYPES = {
      ttf: "font/ttf",
      otf: "font/otf",
      woff: "font/woff",
      woff2: "font/woff2",
      eot: "application/vnd.ms-fontobject",
    }
    private_constant :MIME_TYPES

    def self.default
      @@default ||= new(24)
    end

    def self.default=(f)
      @@default = f
    end

    def self.install(path_or_url)
      if File.exist?(path_or_url)
        # load from wasi file system
        source = base64_font_data(path_or_url)
      else
        # load from remote
        source = "url(#{path_or_url})"
      end
      name = File.basename(path_or_url, File.extname(path_or_url))
      font = JS.global[:FontFace].new(name, source)

      begin
        font.load.await
      rescue => e
        msg = "Failed to load font. path: #{path_or_url}"
        msg += ", message: #{e.message}" unless e.message.to_s.empty?
        raise DXRubyWasm::Error, msg
      end
      JS.global[:document][:fonts].add(font)

      [font[:family].to_s]
    end

    def self.base64_font_data(file_path)
      header = File.binread(file_path, 4, 0)
      mime_type = nil
      FILE_HEADERS.each do |type, h|
        if header.start_with?(h)
          mime_type = MIME_TYPES[type]
          break
        end
      end
      raise DXRubyWasm::Error, "Only ttf, otf, woff, woff2 and eot files are supported." unless mime_type

      base64_data = Base64.strict_encode64(File.binread(file_path))

      "url(data:#{mime_type};base64,#{base64_data})"
    end

    def initialize(size, fontname = nil, option = {})
      @size = size
      @fontname = fontname
      @internal_name = fontname || "sans-serif"

      @italic = !!option[:italic]
      @style_weight_str = @italic ? "italic" : ""
      if option[:weight] && option[:weight].respond_to?(:to_i)
        @weight = option[:weight].to_i
        @style_weight_str = [@style_weight_str, @weight].join(" ")
      else
        @weight = !!option[:weight]
        @style_weight_str = [@style_weight_str, "bold"].join(" ") if @weight
      end
      @auto_fitting = !!option[:auto_fitting]
    end

    def name
      @internal_name
    end

    def to_css_font_string
      [@style_weight_str, "#{@size}px #{@internal_name}"].join(" ")
    end
  end
end
