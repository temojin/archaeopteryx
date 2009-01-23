module Archaeopteryx
  class Loop
    attr_reader :midi
    def initialize(attributes)
      @generator = attributes[:generator]
      # @measures = attributes[:measures] || 32
      @beats = attributes[:beats] || 16
      midi_destination = attributes[:midi_destination] || 0
      @evil_timer_offset_wtf = attributes[:evil_timer_offset_wtf]
      @midi = LiveMIDI.new(:clock => @clock = attributes[:clock], # confusion!!!!!!!!!!
                           :logging => attributes[:logging] || false,
                           :midi_destination => midi_destination)
      @tap_tempo = TapTempo.new
    end
    def play(music)
      music.each {|note| @midi.play(note)}
    end
    def send(messages)
      messages.each {|message| @midi.send(message)}
    end
    def choose_next_clip(measure)
      @generator.rhythms.each do |rhythm|
        if rhythm.current.complete?
          rhythm.new_clip
          send rhythm.messages(measure)
        end
      end
    end
    def go
      generate_beats = L do
        (1..$measures).each do |measure|
          @generator.mutate(measure)
          (0..(@beats - 1)).each do |beat|
            @midi.send(@tap_tempo) if [0, 4, 8, 12].include?(beat) && @generator.is_a?(Mix)
            choose_next_clip(measure) if beat == @beats - 2 && @generator.is_a?(Mix)
            play @generator.notes(beat)
            @clock.tick
          end
        end
        @midi.timer.at((@clock.start + @clock.time) - @evil_timer_offset_wtf, &generate_beats)
      end
      generate_beats[]
    end
  end
end