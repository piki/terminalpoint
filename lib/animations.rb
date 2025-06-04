require './lib/buffer.rb'

# New slide appears in place, from top to bottom
def wipe_down(from, to, old_idx, new_idx)
	from = from.render
	to = to.render
	(0...from.height).each do |frame|
		buf = RenderBuffer.new(from.width, from.height)
		(0...from.height).each do |rownum|
			dtxt = (rownum < frame ? to : from).take(0, rownum, from.width)
			buf.write(0, rownum, dtxt)
		end
		add_footer(buf, old_idx)
		STDIN.cooked { buf.display }
		sleep 0.5/from.height
	end
	show(new_idx)
end

# New slide slides in from the top
def slide_down(from, to, old_idx, new_idx)
	from = from.render
	to = to.render
	(0...from.height).each do |frame|
		buf = RenderBuffer.new(from.width, from.height)
		(0...from.height).each do |rownum|
			dtxt = if rownum < frame
				to.take(0, from.height-frame+rownum, from.width)
			else
				from.take(0, rownum, from.width)
			end
			buf.write(0, rownum, dtxt)
		end
		add_footer(buf, old_idx)
		STDIN.cooked { buf.display }
		sleep 0.5/from.height
	end
	show(new_idx)
end

# New slide slides in from the right
def slide_left(from, to, old_idx, new_idx)
	from = from.render
	to = to.render
	add_footer(to, new_idx)
	(1...from.width).each do |frame|
		buf = RenderBuffer.new(from.width, from.height)
		(0...from.height).each do |rownum|
			dtxt = from.take(0, rownum, from.width-frame)
			buf.write(0, rownum, dtxt)
			dtxt2 = to.take(0, rownum, frame-1)
			buf.write(from.width-frame, rownum, dtxt2)
		end
		STDIN.cooked { buf.display }
		sleep 0.5/from.width
	end
	show(new_idx)
end

# New slide appears in place, from the corners toward the middle
def diamond_wipe(from, to, old_idx, new_idx)
	from = from.render
	add_footer(from, old_idx)
	to = to.render
	add_footer(to, new_idx)
	frame_count = (from.width/2 + from.height) / 2
	(1...frame_count).each do |frame|
		buf = RenderBuffer.new(from.width, from.height)
		(0...from.height).each do |rownum|
			vdist = from.height/2 - (rownum - from.height/2).abs
			new = 2*[frame - vdist, 0].max
			if new*2 >= from.width
				dtxt = to.take(0, rownum, from.width)
				buf.write(0, rownum, dtxt)
			else
				dtxt1 = to.take(0, rownum, new)
				buf.write(0, rownum, dtxt1)
				dtxt2 = from.take(new, rownum, from.width-new*2)
				buf.write(new, rownum, dtxt2)
				dtxt3 = to.take(from.width-new, rownum, new)
				buf.write(from.width-new, rownum, dtxt3)
			end
		end
		STDIN.cooked { buf.display }
		sleep 0.5/frame_count
	end
	show(new_idx)
end
