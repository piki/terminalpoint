# Struct to contain a single text string, decorated with a set of ANSI
# codes.  If codes == "", then the text is plain.
DecoratedTextSegment = Struct.new(:codes, :txt) do
	def to_ansi
		if codes.empty?
			txt
		else
			"\e[#{codes}m#{txt}\e[0m"
		end
	end
end

# Struct to contain several DecoratedTextSegments.  Any two adjacent
# segments with identical codes will be combined into a single segment.
class DecoratedText
	def initialize(*args)
		@segments = []
		while !args.empty?
			@segments << DecoratedTextSegment.new(args.shift, args.shift)
		end
	end

	# Construct a DecoratedText applying any markdown decorations found in
	# `txt`.  Any backtick text is decorated with `backtick_codes`, and any
	# text not in markdown control sequences is decorated with
	# `plain_codes`.
	#
	# Supported markdown sequences: 
	# **bold**, __bold__, *italics*, _underlines_, and `backticks`
	def DecoratedText.from_markdown(plain_codes, backtick_codes, txt)
		# Backticks prevent other markdown formatting, so we split the string
		# according to backticks and apply other markdown formatting only
		# in the even-numbered segments and the last segment.
		split = txt.split(/`/, -1).each_with_index.map{|tok, i|
			if i % 2 == 0 || i == split.size - 1
				tok.
					gsub(/~([^~]*)~/) { |txt| DecoratedText.ansi(9, txt[1..-2]) }.
					gsub(/\*\*([^*]*)\*\*/) { |txt| DecoratedText.ansi(1, txt[2..-3]) }.
					gsub(/__([^_]*)__/) { |txt| DecoratedText.ansi(1, txt[2..-3]) }.
					gsub(/\*(\w[^*]*)\*/) { |txt| DecoratedText.ansi(3, txt[1..-2]) }.
					gsub(/\b_([^_]*)_\b/) { |txt| DecoratedText.ansi(4, txt[1..-2]) }
			else
				DecoratedText.ansi(code, tok)
			end
		}

		# If we had an odd number of backticks, then the last one shows up as
		# a literal ` character.
		ansi = if split.size % 2 == 0
			split[..-2].join + "`" + split[-1]
		else
			split.join
		end

		DecoratedText.from_ansi(ansi)
	end

	# Construct a DecoratedText from a text string with inline ANSI codes
	def DecoratedText.from_ansi(ansi)
		ret = DecoratedText.new
		ansi.split(/\x1b\[/).each_with_index do |tok, i|
			if i == 0
				ret << DecoratedTextSegment.new("", tok)
			else
				codes, txt = tok.split('m', 2)
				codes.gsub!(/^0($|;)/, '')
				ret << DecoratedTextSegment.new(codes, txt)
			end
		end
		ret
	end

	def to_ansi
		@segments.map {|seg| seg.to_ansi}.join
	end

	def ==(other)
		other_segments = other.instance_variable_get(:@segments)
		@segments == other_segments
		#@segments.size == other_segments.size && @segments.zip(other_segments).all? { |(a, b)| a == b }
	end

	# Add a new segment to the end of the text
	def <<(seg)
		return if seg.txt.empty?
		if !@segments.empty? && @segments.last.codes == seg.codes
			@segments.last.txt += seg.txt
		else
			@segments << seg
		end
	end

	# Add a whole new DecoratedText to the end of the text
	def push_all(dtxt)
		dtxt.instance_variable_get(:@segments).each do |seg|
			@segments << seg
		end
	end

	# Add a new segment to the beginning of the text
	def prepend(seg)
		return if seg.txt.empty?
		if !@segments.empty? && @segments.first.codes == seg.codes
			@segments.first.txt = seg.txt + @segments.first.txt
		else
			@segments.unshift(seg)
		end
	end

	# Return the minimum display width of the text, i.e., if every word
	# is wrapped.
	def min_width
		@segments.map {|seg| seg.txt.length}.max
	end

	# Return the maximum display width of the text, with no wrapping
	def width
		@segments.map {|seg| seg.txt.length}.sum
	end

	# True if there is no text
	def empty?
		@segments.empty?
	end

	# Return an array of DecoratedText objects, each of which has
	# width <= max_length.  If any of the words is longer than max_length,
	# then that line will also be longer than max_length.
	def wrap(max_length)
		words = self.split(/\s+/)
		lines = []
		line = nil

		words.each do |word|
			if line.nil?
				line = word
			elsif (line.width + 1 + word.width) <= max_length
				line << DecoratedTextSegment.new("", " ")
				line << word
			else
				lines << line
				line = word
			end
		end

		lines << line unless line.nil?
		lines
	end

# class utility functions
	def DecoratedText.ansi(codes, s)
		# If there are already ANSI codes in `s`, like from the user using `#{fmt('bold', '...')}` in their config file
		# rewrite the end of those sequences to apply the overall formatting for the string.
		sfix = s.gsub("\x1b[0m", "\x1b[0;#{codes}m")
		"\x1b[0;#{codes}m#{sfix}\x1b[0m"
	end


private
	# Split this DecoratedText into an array of multiple DecoratedText
	# objects, separated by a regular expression.  If re occurs in the
	# middle of a segment, that segment will be split.
	def split(re)
		result = []
		current = DecoratedText.new
		
		@segments.each do |segment|
			parts = segment.txt.split(re, -1)
			
			if parts.length == 1
				current << DecoratedTextSegment.new(segment.codes, parts[0])
			else
				parts.each_with_index do |part, i|
					if i == 0
						current << DecoratedTextSegment.new(segment.codes, part)
					else
						result << current unless current.empty?
						current = DecoratedText.new
						current << DecoratedTextSegment.new(segment.codes, part) unless part.empty?
					end
				end
			end
		end
		
		result << current unless current.empty?
		result
	end
end
