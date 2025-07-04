class BufferBase
	def child(xofs, yofs, width, height)
		raise "child is too wide: #{xofs} + #{width} > #{@width}" if xofs + width > @width
		raise "child is too tall: #{yofs} + #{height} > #{@height}" if yofs + height > @height

		ChildRenderBuffer.new(width, height) do |x, y, dtxt|
			self.write(xofs + x, yofs + y, dtxt)
		end
	end
end

class ChildRenderBuffer < BufferBase
	attr_reader :width, :height
	def initialize(width, height, &block)
		@width = width
		@height = height
		@block = block
	end

	def write(x, y, dtxt)
		raise "y is out of bounds: #{y} >= #{height}" if y >= @height
		raise "x is out of bounds: #{x} + #{dtxt.width} > #{@width}" if x + dtxt.width > @width
		
		@block.call(x, y, dtxt)
	end
end

class RenderBuffer < BufferBase
	attr_reader :width, :height
	def initialize(width, height)
		@width = width
		@height = height
		@lines = (0...@height).map{ DecoratedText.new }
	end

	def write(x, y, dtxt)
		return if dtxt.empty?
		raise "y is out of bounds: #{y} >= #{height}" if y >= @height
		raise "x is out of bounds: #{x} + #{dtxt.width} > #{@width}" if x + dtxt.width > @width
		line = @lines[y]
		raise "overwrite on line #{y}: #{x} < #{line.width}" if x < line.width
		gap = x - line.width
		line << DecoratedTextSegment.new("", " " * gap) if gap > 0
		line.push_all(dtxt)
		dtxt.width
	end

	def display(interactive)
		print ANSI_CLEAR_SCREEN + ANSI_GO_HOME + ANSI_HIDE_CURSOR if interactive
		@lines.each_with_index do |line, i|
			if i != @lines.size - 1 || !STDOUT.tty?
				puts line.to_ansi
			else
				print line.to_ansi
			end
		end
	end

	def take(x, y, width)
		ret = DecoratedText.new
		return ret if width == 0
		@lines[y].segments.each do |seg|
			if x > seg.txt.size
				x -= seg.txt.size
				next
			end
			segpart = seg.txt[x...x+width]
			x = 0
			width -= segpart.size
			ret << DecoratedTextSegment.new(seg.codes, segpart)
			break if width == 0
		end
		ret
	end
end
