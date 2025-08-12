class BufferBase
	def child(xofs, yofs, width, height)
		raise "child is too wide: #{xofs} + #{width} > #{@width}" if xofs + width > @width
		raise "child is too tall: #{yofs} + #{height} > #{@height}" if yofs + height > @height

		ChildRenderBuffer.new(width, height, xofs, yofs, self)
	end
end

class ChildRenderBuffer < BufferBase
	attr_reader :width, :height
	def initialize(width, height, xofs, yofs, parent)
		@width = width
		@height = height
		@xofs = xofs
		@yofs = yofs
		@parent = parent
	end

	def write(x, y, dtxt)
		return if y >= @height || @height <= 0
		return if x >= @width || @width <= 0
		return if x + dtxt.width > @width
		
		@parent.write(@xofs+x, @yofs+y, dtxt)
	end

	def xofs
		@xofs + @parent.xofs
	end

	def yofs
		@yofs + @parent.yofs
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
		raise "overwrite on line #{y}: #{x} < #{line.width}\n#{line.inspect}" if x < line.width
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

	def xofs
		0
	end

	def yofs
		0
	end
end
