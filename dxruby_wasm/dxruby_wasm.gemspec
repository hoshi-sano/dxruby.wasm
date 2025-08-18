# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative "lib/dxruby_wasm/version"

Gem::Specification.new do |spec|
  spec.name = "dxruby_wasm"
  spec.version = DXRubyWasm::VERSION
  spec.authors = ["Yuki Morohoshi"]
  spec.email = ["hoshi.sanou@gmail.com"]

  spec.summary = "Game development framework for ruby.wasm"
  # spec.homepage = "TODO: https://hoshi-sano.github.io/dxruby_wasm/"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  # spec.metadata["homepage_uri"] = "TODO: https://hoshi-sano.github.io/dxruby_wasm/"
  spec.metadata["source_code_uri"] = "https://github.com/hoshi-sano/dxruby.wasm"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "js"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
