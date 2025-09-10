# frozen_string_literal: true

module DXRubyWasm
  class Sound
    @@audio_context = nil

    def self.audio_context
      # NOTE: Browsers often require a user gesture (like a click) to start an AudioContext.
      #       It is created on first use, assuming a user gesture has already occurred.
      @@audio_context ||= JS.global[:AudioContext].new
    end

    def initialize(path)
      @path = path
      @buffer = nil
      @source = nil # To keep track of the current playing source node

      context = self.class.audio_context

      Fiber.new {
        JS.global.fetch(path)
          .then { |response| response.arrayBuffer() }
          .then { |array_buffer| context.decodeAudioData(array_buffer) }
          .then { |audio_buffer| @buffer = audio_buffer; JS::Undefined }
          .await
      }.transfer
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
