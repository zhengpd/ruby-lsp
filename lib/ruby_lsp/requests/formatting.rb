# typed: strict
# frozen_string_literal: true

require "ruby_lsp/requests/support/rubocop_formatting_runner"

module RubyLsp
  module Requests
    # ![Formatting symbol demo](../../misc/formatting.gif)
    #
    # The [formatting](https://microsoft.github.io/language-server-protocol/specification#textDocument_formatting)
    # request uses RuboCop to fix auto-correctable offenses in the document. This requires enabling format on save and
    # registering the ruby-lsp as the Ruby formatter.
    #
    # If RuboCop is not available, the request will fall back to SyntaxTree.
    #
    # # Example
    #
    # ```ruby
    # def say_hello
    # puts "Hello" # --> formatting: fixes the indentation on save
    # end
    # ```
    class Formatting < BaseRequest
      class Error < StandardError; end

      extend T::Sig

      sig { params(uri: String, document: Document).void }
      def initialize(uri, document)
        super(document)

        @uri = uri
      end

      sig { override.returns(T.nilable(T.all(T::Array[Interface::TextEdit], Object))) }
      def run
        # Don't try to format files outside the current working directory
        return unless @uri.sub("file://", "").start_with?(Dir.pwd)

        return if @document.syntax_error?

        formatted_text = formatted_file
        return unless formatted_text

        size = @document.source.size
        return if formatted_text.size == size && formatted_text == @document.source

        [
          Interface::TextEdit.new(
            range: Interface::Range.new(
              start: Interface::Position.new(line: 0, character: 0),
              end: Interface::Position.new(line: size, character: size),
            ),
            new_text: formatted_text,
          ),
        ]
      end

      private

      sig { returns(T.nilable(String)) }
      def formatted_file
        if defined?(Support::RuboCopFormattingRunner)
          Support::RuboCopFormattingRunner.instance.run(@uri, @document)
        else
          SyntaxTree.format(@document.source)
        end
      end
    end
  end
end
