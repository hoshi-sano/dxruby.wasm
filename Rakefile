# frozen_string_literal: true

task :build do
  require "bundler/setup"
  file_path = File.join(__dir__, "dist", "dxruby.wasm")
  sh "rbwasm build -o #{file_path}"
end
