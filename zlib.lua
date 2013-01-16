--zlib binding
local ffi = require'ffi'
require'zlib_h'
local C = ffi.load'zlib'
local M = {C = C}

function M.version()
	return ffi.string(C.zlibVersion())
end

local function check(ret)
	if ret == 0 then return end
	error(ffi.string(C.zError(ret)))
end

local function flate(api)
	return function(...)
		local ret = api(...)
		if ret == 0 then return true end
		if ret == C.Z_STREAM_END then return false end
		check(ret)
	end
end

local deflate = flate(C.deflate)
local inflate = flate(C.inflate)

local function init_deflate(finally, level)
	level = level or -1
	local strm = ffi.new'z_stream'
	check(C.deflateInit_(strm, level, M.version(), ffi.sizeof(strm)))
	finally(function() check(C.deflateEnd(strm)) end)
	return strm, deflate
end

local function init_inflate(finally)
	local strm = ffi.new'z_stream'
	check(C.inflateInit_(strm, M.version(), ffi.sizeof(strm)))
	finally(function() check(C.inflateEnd(strm)) end)
	return strm, inflate
end

local function inflate_deflate(init)
	return function(read, write, bufsize, ...)
		glue.fcall(function(finally, except, ...)
			bufsize = bufsize or 16384

			local strm, flate = init(finally, ...)

			local buf = ffi.new('uint8_t[?]', bufsize)
			strm.next_out, strm.avail_out = buf, bufsize
			strm.next_in, strm.avail_in = nil, 0

			local function flush()
				local sz = bufsize - strm.avail_out
				if sz == 0 then return end
				write(buf, sz)
				strm.next_out, strm.avail_out = buf, bufsize
			end

			local data, size --data must be anchored as an upvalue!
			while true do
				if strm.avail_in == 0 then --input buffer empty: refill
					data, size = read()
					if not data then --eof: finish up
						local ret
						repeat
							flush()
						until not flate(strm, C.Z_FINISH)
						flush()
						return
					end
					strm.next_in, strm.avail_in = data, size or #data
				end
				flush()
				if not flate(strm, C.Z_NO_FLUSH) then
					flush()
					return
				end
			end
		end, ...)
	end
end

M.inflate = inflate_deflate(init_inflate)
M.deflate = inflate_deflate(init_deflate)

--utility functions

function M.compress_cdata(data, size)
	local sz = ffi.new('unsigned long[1]', C.compressBound(size))
	local buf = ffi.new('uint8_t[?]', sz[0])
	check(C.compress(buf, sz, data, size))
	return buf, sz[0]
end

function M.compress(s)
	return ffi.string(M.compress_cdata(s, #s))
end

function M.uncompress_cdata(data, size, sz, buf)
	sz = ffi.new('unsigned long[1]', sz)
	buf = buf or ffi.new('uint8_t[?]', sz[0])
	check(C.uncompress(buf, sz, data, size))
	return buf, sz[0], buf
end

function M.uncompress(s, sz, buf)
	return ffi.string(M.uncompress_cdata(s, #s, sz, buf))
end

--gzip file access functions

local function checkz(ret) assert(ret == 0) end
local function checkminus1(ret) assert(ret ~= -1); return ret end
local function ptr(o) return o ~= nil and o or nil end

function M.gzclose(gzfile)
	checkz(C.gzclose(gzfile))
	ffi.gc(gzfile, nil)
end

function M.gzopen(filename, mode, bufsize)
	local gzfile = ptr(C.gzopen(filename, mode or 'r'))
	if not gzfile then return nil, string.format('errno %d', ffi.errno()) end
	ffi.gc(gzfile, M.gzclose)
	if bufsize then C.gzbuffer(gzfile, bufsize) end
	return gzfile
end

local gzfile = {}

local flush_enum = {
	none    = C.Z_NO_FLUSH,
	partial = C.Z_PARTIAL_FLUSH,
	sync    = C.Z_SYNC_FLUSH,
	full    = C.Z_FULL_FLUSH,
	finish  = C.Z_FINISH,
	block   = C.Z_BLOCK,
	trees   = C.Z_TREES,
}

function M.gzflush(gzfile, flush)
	checkz(C.gzflush(gzfile, flush_enum[flush]))
end

function M.gzread(gzfile, sz)
	local buf = ffi.new('uint8_t[?]', sz)
	sz = checkminus1(C.gzread(gzfile, buf, sz))
	return ffi.string(buf, sz)
end

function M.gzwrite(gzfile, s)
	local sz = C.gzwrite(gzfile, s, #s)
	if sz == 0 then return nil,'error' end
	return sz
end

function M.gzeof(gzfile)
	return C.gzeof(gzfile) == 1
end

function M.gzseek(gzfile, ...)
	local narg = select('#',...)
	local whence, offset
	if narg == 0 then
		whence, offset = 'cur', 0
	elseif narg == 1 then
		if type(...) == 'string' then
			whence, offset = ..., 0
		else
			whence, offset = 'cur',...
		end
	else
		whence, offset = ...
	end
	whence = assert(whence == 'set' and 0 or whence == 'cur' and 1)
	return checkminus1(C.gzseek(gzfile, offset, whence))
end

function M.gzoffset(gzfile)
	return checkminus1(C.gzoffset(gzfile))
end

ffi.metatype('gzFile_', {__index = {
	close = M.gzclose,
	read = M.gzread,
	write = M.gzwrite,
	flush = M.gzflush,
	eof = M.gzeof,
	seek = M.gzseek,
	offset = M.gzoffset,
}})

--checksum functions

function M.adler32(s, adler)
	adler = adler or C.adler32(0, nil, 0)
	return tonumber(C.adler32(adler, s, #s))
end

function M.crc32b(s, crc)
	crc = crc or C.crc32(0, nil, 0)
	return tonumber(C.crc32(crc, s, #s))
end

if not ... then require'zlib_test' end

return M