--codedit text blocks: vertically aligned text between two subsequent text positions.
--line1 and line2 must be valid, subsequent lines. col1 and col2 can be anything.
local buffer = require'codedit_buffer'
local str = require'codedit_str'

--clamped line segment on a line that intersects the rectangle formed by two arbitrary text positions.
function buffer:block_cols(line, line1, col1, line2, col2)
	local col1 = self:aligned_col(line, line1, col1)
	local col2 = self:aligned_col(line, line2, col2)
	--the aligned columns could end up switched because the visual columns of col1 and col2 could be switched.
	if col1 > col2 then
		col1, col2 = col2, col1
	end
	--restrict columns to the available text
	local last_col = self:last_col(line)
	col1 = math.min(math.max(col1, 1), last_col + 1)
	col2 = math.min(math.max(col2, 1), last_col + 1)
	return col1, col2
end

--select the block between two subsequent text positions as a multi-line string
function buffer:select_block(line1, col1, line2, col2)
	local lines = {}
	for line = line1, line2 do
		local tcol1, tcol2 = self:block_cols(line, line1, col1, line2, col2)
		table.insert(lines, self:sub(line, tcol1, tcol2))
	end
	return lines
end

--insert a multi-line string as a block at some position in the text. return the position after the string.
function buffer:insert_block(line1, col1, s)
	local line = line1
	local line2, col2
	local vcol = self:visual_col(line1, col1)
	for _,s in str.lines(s) do
		local col = self:real_col(line, vcol)
		line2, col2 = self:insert_string(line, col, s)
		line = line + 1
	end
	return line2, col2
end

--remove the block between two subsequent positions in the text
function buffer:remove_block(line1, col1, line2, col2)
	for line = line1, line2 do
		local tcol1, tcol2 = self:block_cols(line, line1, col1, line2, col2)
		self:remove_string(line, tcol1, line, tcol2)
	end
end

--indent the block between two subsequent positions in the text
function buffer:indent_block(line1, line2, col1)
	for line = line1, line2 do
		self:insert_tab(line, col1)
	end
end

--outdent the block between two subsequent positions in the text
function buffer:outdent_block(line1, line2, col1)
	local vcol = self:visual_col(line1, col1)
	for line = line1, line2 do
		local col = self:real_col(line, vcol)
		self:remove_tab(line, col)
	end
end


if not ... then require'codedit_demo' end
