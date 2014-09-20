require 'seeing_is_believing/event_stream/events'
class SeeingIsBelieving
  module EventStream
    module UpdateResult
      def self.call(result, event)
         case event
         when EventStream::Events::LineResult       then result.record_result(event.type, event.line_number, event.inspected)
         when EventStream::Events::UnrecordedResult then result.record_result(event.type, event.line_number, '...') # <-- is this really what I want?
         when EventStream::Events::Exception        then result.record_exception event.line_number, event.class_name, event.message, event.backtrace
         when EventStream::Events::Stdout           then result.stdout             = event.value
         when EventStream::Events::Stderr           then result.stderr             = event.value
         when EventStream::Events::BugInSiB         then result.bug_in_sib         = event.value
         when EventStream::Events::MaxLineCaptures  then result.number_of_captures = event.value
         when EventStream::Events::Exitstatus       then result.exitstatus         = event.value
         when EventStream::Events::NumLines         then result.num_lines          = event.value
         else raise "Unknown event: #{event.inspect}"
         end
      end
    end
  end
end
