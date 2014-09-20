require 'seeing_is_believing/binary'         # Defines the regexes to locate the markers
require 'seeing_is_believing/parser_helpers' # We have to parse the file to find the comments

class SeeingIsBelieving
  class Binary
    class RemoveAnnotations
      def self.call(code, should_clean_values)
        new(code, should_clean_values).call
      end

      def initialize(code, should_clean_values)
        self.should_clean_values = should_clean_values
        self.code                = code
      end

      def call
        buffer, parser, rewriter = ParserHelpers.initialize_parser code, 'strip_comments'
        comments                 = ParserHelpers.comments_from parser, buffer
        removed_comments         = { result: [], exception: [], stdout: [], stderr: [] }

        comments.each do |comment|
          case comment.text
          when VALUE_REGEX
            if should_clean_values
              removed_comments[:result] << comment
              rewriter.remove comment.location.expression
            end
          when EXCEPTION_REGEX
            removed_comments[:exception] << comment
            rewriter.remove comment.location.expression
          when STDOUT_REGEX
            removed_comments[:stdout] << comment
            rewriter.remove comment.location.expression
          when STDERR_REGEX
            removed_comments[:stderr] << comment
            rewriter.remove comment.location.expression
          end
        end

        remove_whitespace_preceding_comments(buffer, rewriter, removed_comments)
        rewriter.process
      rescue Parser::SyntaxError => e
        raise SyntaxError, e.message
      end

      private

      attr_accessor :code, :should_clean_values, :buffer

      def remove_whitespace_preceding_comments(buffer, rewriter, removed_comments)
        removed_comments[:result].each    { |comment| remove_whitespace_before comment.location.expression.begin_pos, buffer, rewriter, false }
        removed_comments[:exception].each { |comment| remove_whitespace_before comment.location.expression.begin_pos, buffer, rewriter, true  }
        removed_comments[:stdout].each    { |comment| remove_whitespace_before comment.location.expression.begin_pos, buffer, rewriter, true  }
        removed_comments[:stderr].each    { |comment| remove_whitespace_before comment.location.expression.begin_pos, buffer, rewriter, true  }
      end

      # any whitespace before the index (on the same line) will be removed
      # if the preceding whitespace is at the beginning of the line, the newline will be removed
      # if there is a newline before all of that, and remove_preceding_newline is true, it will be removed as well
      def remove_whitespace_before(index, buffer, rewriter, remove_preceding_newline)
        end_pos   = index
        begin_pos = end_pos - 1
        begin_pos -= 1 while code[begin_pos] =~ /\s/ && code[begin_pos] != "\n"
        begin_pos -= 1 if code[begin_pos] == "\n"
        begin_pos -= 1 if code[begin_pos] == "\n" && remove_preceding_newline
        return if begin_pos.next == end_pos
        rewriter.remove Parser::Source::Range.new(buffer, begin_pos.next, end_pos)
      end
    end
  end
end
