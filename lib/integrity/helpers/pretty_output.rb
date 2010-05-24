module Integrity
  module Helpers
    module PrettyOutput
      def cycle(*values)
        @cycles ||= {}
        @cycles[values] ||= -1 # first value returned is 0
        next_value = @cycles[values] = (@cycles[values] + 1) % values.size
        values[next_value]
      end

      def bash_color_codes(string)
        AnsiToHtml.new(string).to_s
      end

      def pretty_date(date_time)
        days_away = (Date.today - Date.new(date_time.year, date_time.month, date_time.day)).to_i
        if days_away == 0
          "today"
        elsif days_away == 1
          "yesterday"
        elsif date_time == DateTime.new
          "unavailable"
        else
          strftime_with_ordinal(date_time, "on %b %o")
        end
      end

      def strftime_with_ordinal(date_time, format_string)
        ordinal = case date_time.day
          when 1, 21, 31 then "st"
          when 2, 22     then "nd"
          when 3, 23     then "rd"
          else                "th"
        end

        date_time.strftime(format_string.gsub("%o", date_time.day.to_s + ordinal))
      end
    end
  end
end

class AnsiParser
  def initialize(delegate)
    @delegate = delegate
    @state_changes = 0

    @reset_state = {
      :fg => 37,
      :bg => 30,
      :bold => false
    }

    @state = @reset_state.dup
  end

  def reset_state!
    @delegate.state_reset(@state_changes)

    @state_changes = 0
    @state = @reset_state.dup
  end

  def update_state(changes)
    new_state = @state.merge(changes)
    if new_state != @state
      @state = new_state
      @state_changes += 1

      @delegate.state_updated(@state,changes)
    end
  end

  def add_code(number)
    number = number.to_i
    case number
    when 0
      reset_state!
    when 1
      update_state(:bold => true)
    when 22
      update_state(:bold => false)
    when 30..37,90..97
      update_state(:fg => number)
    when 40..47,100..107
      update_state(:bg => number)
    else
      # unhandled
    end
  end

  def add_text(text)
    @delegate.text_added(text)
  end

  AnsiPre  = %r{^([^\e]*)(?=\e\[\d+m)}
  AnsiScan = %r{\e\[(\d+)m([^\e]*)}
  def parse(text)
    #text = text.gsub('&', '&amp;').gsub('"', '&quot;').gsub('<', '&lt;').gsub('>', '&gt;')

    if text.include?("\e")
      text.sub!(AnsiPre,'')
      pre = $1
      add_text(pre)

      text.scan(AnsiScan).each {|(code,text)| add_code(code); add_text(text)}
    else
      @delegate.buffer = text
    end
  end
end

class AnsiToHtml
  attr_accessor :buffer
  
  def initialize(input)
    @input = input
    @buffer = ""
    @opened = false
  end

  def to_s
    AnsiParser.new(self).parse(@input)
    @buffer
  end

  def text_added(text)
    @buffer += text
  end

  def state_reset(depth)
    @buffer += "</span>" if @opened
    @opened = false
  end

  def state_updated(state,changes)
    @buffer += "</span>" if @opened
    @opened = true
    @buffer += "<span class='#{state_to_class(state) * ' '}'>"
  end

  def state_to_class(state)
    classes = ["ansi-fg-#{state[:fg]}", "ansi-bg-#{state[:bg]}"]
    classes << 'ansi-bold' if state[:bold]
    classes
  end

end
