class SeeingIsBelieving
  class Result
    include Enumerable
    RecordedException = Struct.new :line_number, :class_name, :message, :backtrace

    attr_accessor :stdout, :stderr, :exitstatus, :number_of_captures, :exception, :num_lines

    alias has_exception? exception

    def has_stdout?
      stdout && !stdout.empty?
    end

    def has_stderr?
      stderr && !stderr.empty?
    end

    def record_result(type, line_number, value)
      results_for(line_number, type) << value
      value
    end

    def record_exception(line_number, exception_class, exception_message, exception_backtrace)
      self.exception = RecordedException.new line_number, exception_class, exception_message, exception_backtrace
    end

    def [](line_number, type=:inspect)
      results_for(line_number, type)
    end

    def each(&block)
      return to_enum :each unless block
      (1..num_lines).each { |line_number| block.call self[line_number] }
    end

    def inspect
      results
      variables = instance_variables.map do |name|
        value = instance_variable_get(name)
        inspected = if name.to_s == '@results'
          "{#{value.sort_by(&:first).map { |k, v| "#{k.inspect}=>#{v.inspect}"}.join(",\n            ")}}"
        else
          value.inspect
        end
        "#{name}=#{inspected}"
      end
      "#<SIB::Result #{variables.join "\n  "}>"
    end

    def number_of_captures
      @number_of_captures || Float::INFINITY
    end

    private

    def results_for(line_number, type)
      line_results = (results[line_number] ||= Hash.new { |h, k| h[k] = [] })
      line_results[type]
    end

    def results
      @results ||= Hash.new
    end
  end
end
