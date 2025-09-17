# frozen_string_literal: true

module DXRubyWasm
  class Sound
    @@audio_context = nil

    def self.audio_context
      # NOTE: Browsers often require a user gesture (like a click) to start an AudioContext.
      #       It is created on first use, assuming a user gesture has already occurred.
      @@audio_context ||= JS.global[:AudioContext].new
    end

    def initialize(path_or_url)
      @path = path_or_url
      @buffer = nil
      @source = nil # To keep track of the current playing source node

      context = self.class.audio_context

      promise = if File.exist?(path_or_url)
                  binary_string = File.binread(path_or_url)
                  uint8_array = JS.global[:Uint8Array].new(binary_string.bytes.to_js)
                  array_buffer = uint8_array[:buffer]
                  context.decodeAudioData(array_buffer)
                else
                  JS.global.fetch(path_or_url)
                    .then { |response| response.arrayBuffer() }
                    .then { |array_buffer| context.decodeAudioData(array_buffer) }
                end
      promise
        .then { |audio_buffer| @buffer = audio_buffer; JS::Undefined }
        .await
    end

    # Start playing the sound.
    # If it's already playing, it will be stopped and restarted from the beginning.
    def play
      stop if @source
      return unless @buffer

      context = self.class.audio_context
      @source = context.createBufferSource()
      @source[:buffer] = @buffer
      @source.connect(context[:destination])
      @source.start(0)
    end

    # Stop playing the sound.
    def stop
      if @source
        @source.stop(0)
        @source = nil
      end
    end
  end
end
