# frozen_string_literal: true

require "js"

require_relative "dxruby_wasm/constants/colors"
require_relative "dxruby_wasm/image"
require_relative "dxruby_wasm/window"
require_relative "dxruby_wasm/version"

module DXRubyWasm
  include DXRubyWasm::Constants::Colors

  class Error < StandardError; end
  # Your code goes here...
end

include DXRubyWasm
