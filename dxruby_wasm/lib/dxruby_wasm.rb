# frozen_string_literal: true

require "js"

require_relative "dxruby_wasm/constants/colors"
require_relative "dxruby_wasm/constants/key_codes"
require_relative "dxruby_wasm/image"
require_relative "dxruby_wasm/sprite"
require_relative "dxruby_wasm/sound"
require_relative "dxruby_wasm/font"
require_relative "dxruby_wasm/input"
require_relative "dxruby_wasm/render_methods"
require_relative "dxruby_wasm/render_target"
require_relative "dxruby_wasm/window"
require_relative "dxruby_wasm/version"

module DXRubyWasm
  include DXRubyWasm::Constants::Colors
  include DXRubyWasm::Constants::KeyCodes

  class Error < StandardError; end
end

include DXRubyWasm
