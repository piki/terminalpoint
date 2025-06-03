require_relative 'decorated_text'
require 'test/unit'

class DecoratedTextTest < Test::Unit::TestCase
	def test_split_with_spaces
		dt = DecoratedText.new
		dt << DecoratedTextSegment.new("", "hello world test")
		
		result = dt.send(:split, /\s+/)
		
		assert_equal 3, result.length
		assert_equal DecoratedText.new("", "hello"), result[0]
		assert_equal DecoratedText.new("", "world"), result[1]
		assert_equal DecoratedText.new("", "test"), result[2]
	end
	
	def test_split_with_decorated_segments
		dt = DecoratedText.new
		dt << DecoratedTextSegment.new("1", "bold")
		dt << DecoratedTextSegment.new("", " normal ")
		dt << DecoratedTextSegment.new("31", "red")
		
		result = dt.send(:split, /\s+/)
		
		assert_equal 3, result.length
		assert_equal DecoratedText.new("1", "bold"), result[0]
		assert_equal DecoratedText.new("", "normal"), result[1]
		assert_equal DecoratedText.new("31", "red"), result[2]
	end
	
	def test_split_empty_text
		dt = DecoratedText.new
		
		result = dt.send(:split, /\s+/)
		
		assert_equal 0, result.length
	end
	
	def test_split_no_matches
		dt = DecoratedText.new
		dt << DecoratedTextSegment.new("", "hello")
		
		result = dt.send(:split, /\d+/)
		
		assert_equal 1, result.length
		assert_equal DecoratedText.new("", "hello"), result[0]
	end
	
	def test_split_at_segment_boundaries
		dt = DecoratedText.new
		dt << DecoratedTextSegment.new("1", "bold")
		dt << DecoratedTextSegment.new("", " ")
		dt << DecoratedTextSegment.new("31", "red")
		
		result = dt.send(:split, / /)
		
		assert_equal 2, result.length
		assert_equal DecoratedText.new("1", "bold"), result[0]
		assert_equal DecoratedText.new("31", "red"), result[1]
	end
	
	def test_split_multiple_separators
		dt = DecoratedText.new
		dt << DecoratedTextSegment.new("", "a::b::c")
		
		result = dt.send(:split, /::/)
		
		assert_equal 3, result.length
		assert_equal DecoratedText.new("", "a"), result[0]
		assert_equal DecoratedText.new("", "b"), result[1]
		assert_equal DecoratedText.new("", "c"), result[2]
	end

	def test_from_ansi
		result = DecoratedText.from_ansi("hello")
		assert_equal DecoratedText.new("", "hello"), result

		result = DecoratedText.from_ansi("\e[31mred")
		assert_equal DecoratedText.new("31", "red"), result

		result = DecoratedText.from_ansi("\e[31mred\e[0m")
		assert_equal DecoratedText.new("31", "red"), result

		result = DecoratedText.from_ansi("plain \e[31mred\e[32mgreen\e[0m")
		expect = DecoratedText.new
		expect << DecoratedTextSegment.new("", "plain ")
		expect << DecoratedTextSegment.new("31", "red")
		expect << DecoratedTextSegment.new("32", "green")
		assert_equal expect, result
	end

	def test_from_markdown
		result = DecoratedText.from_markdown("", "1;100", "hello")
		assert_equal DecoratedText.new("", "hello"), result

		result = DecoratedText.from_markdown("", "1;100", "hello **bold**")
		assert_equal DecoratedText.new("", "hello ", "1", "bold"), result

		result = DecoratedText.from_markdown("", "1;100", "hello __bold__")
		assert_equal DecoratedText.new("", "hello ", "1", "bold"), result

		result = DecoratedText.from_markdown("", "1;100", "hello _underlined_ and *italics* and ~strikethrough~ til plain again")
		assert_equal DecoratedText.new("", "hello ", "4", "underlined", "", " and ", "3", "italics", "", " and ", "9", "strikethrough", "", " til plain again"), result

		result = DecoratedText.from_markdown("", "1;100", "Simple `backticks` for code")
		assert_equal DecoratedText.new("", "Simple ", "1;100", "backticks", "", " for code"), result
	end
end
