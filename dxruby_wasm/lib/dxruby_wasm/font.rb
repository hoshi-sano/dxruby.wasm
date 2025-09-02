# frozen_string_literal: true

module DXRubyWasm
  class Font
    attr_reader :size, :fontname, :weight, :italic, :auto_fitting

    def self.default
      @@default ||= new(24)
    end

    def self.default=(f)
      @@default = f
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
