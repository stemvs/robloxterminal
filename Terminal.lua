local Terminal = {}

-- Constants

local FONT = Enum.Font.Code
local CONSOLE_MAX_SIZE = 1E4
local CURS_OSC = 0.5

local CHARS = {
	[0x20] = "",
	[0x21] = "<b>!</b>",
	[0x22] = "<b>&quot;</b>",
	[0x23] = "<b>#</b>",
	[0x24] = "<b>$</b>",
	[0x25] = "<b>%</b>",
	[0x26] = "<b>&amp;</b>",
	[0x27] = "<b>&apos;</b>",
	[0x28] = "<b>(</b>",
	[0x29] = "<b>)</b>",
	[0x2A] = "<b>*</b>",
	[0x2B] = "<b>+</b>",
	[0x2C] = "<b>,</b>",
	[0x2D] = "<b>-</b>",
	[0x2E] = "<b>.</b>",
	[0x2F] = "<b>/</b>",
	[0x30] = "<b>0</b>",
	[0x31] = "<b>1</b>",
	[0x32] = "<b>2</b>",
	[0x33] = "<b>3</b>",
	[0x34] = "<b>4</b>",
	[0x35] = "<b>5</b>",
	[0x36] = "<b>6</b>",
	[0x37] = "<b>7</b>",
	[0x38] = "<b>8</b>",
	[0x39] = "<b>9</b>",
	[0x3A] = "<b>:</b>",
	[0x3B] = "<b>;</b>",
	[0x3C] = "<b>&lt;</b>",
	[0x3D] = "<b>=</b>",
	[0x3E] = "<b>&gt;</b>",
	[0x3F] = "<b>?</b>",
	[0x40] = "<b>@</b>",
	[0x41] = "<b>A</b>",
	[0x42] = "<b>B</b>",
	[0x43] = "<b>C</b>",
	[0x44] = "<b>D</b>",
	[0x45] = "<b>E</b>",
	[0x46] = "<b>F</b>",
	[0x47] = "<b>G</b>",
	[0x48] = "<b>H</b>",
	[0x49] = "<b>I</b>",
	[0x4A] = "<b>J</b>",
	[0x4B] = "<b>K</b>",
	[0x4C] = "<b>L</b>",
	[0x4D] = "<b>M</b>",
	[0x4E] = "<b>N</b>",
	[0x4F] = "<b>O</b>",
	[0x50] = "<b>P</b>",
	[0x51] = "<b>Q</b>",
	[0x52] = "<b>R</b>",
	[0x53] = "<b>S</b>",
	[0x54] = "<b>T</b>",
	[0x55] = "<b>U</b>",
	[0x56] = "<b>V</b>",
	[0x57] = "<b>W</b>",
	[0x58] = "<b>X</b>",
	[0x59] = "<b>Y</b>",
	[0x5A] = "<b>Z</b>",
	[0x5B] = "<b>[</b>",
	[0x5C] = "<b>\\</b>",
	[0x5D] = "<b>]</b>",
	[0x5E] = "<b>^</b>",
	[0x5F] = "<b>_</b>",
	[0x60] = "<b>`</b>",
	[0x61] = "<b>a</b>",
	[0x62] = "<b>b</b>",
	[0x63] = "<b>c</b>",
	[0x64] = "<b>d</b>",
	[0x65] = "<b>e</b>",
	[0x66] = "<b>f</b>",
	[0x67] = "<b>g</b>",
	[0x68] = "<b>h</b>",
	[0x69] = "<b>i</b>",
	[0x6A] = "<b>j</b>",
	[0x6B] = "<b>k</b>",
	[0x6C] = "<b>l</b>",
	[0x6D] = "<b>m</b>",
	[0x6E] = "<b>n</b>",
	[0x6F] = "<b>o</b>",
	[0x70] = "<b>p</b>",
	[0x71] = "<b>q</b>",
	[0x72] = "<b>r</b>",
	[0x73] = "<b>s</b>",
	[0x74] = "<b>t</b>",
	[0x75] = "<b>u</b>",
	[0x76] = "<b>v</b>",
	[0x77] = "<b>w</b>",
	[0x78] = "<b>x</b>",
	[0x79] = "<b>y</b>",
	[0x7A] = "<b>z</b>",
	[0x7B] = "<b>{</b>",
	[0x7C] = "<b>|</b>",
	[0x7D] = "<b>}</b>",
	[0x7E] = "<b>~</b>",
}

local rStepped = game:GetService("RunService").RenderStepped
local rWait = rStepped.Wait

local band = bit32.band
local bor = bit32.bor
local bnot = bit32.bnot
local rshift = bit32.rshift
local log = math.log

local DEFAULT = {
	sizeX = 90,
	sizeY = 25,
	textY = 17,
	bufferSize = 5E4,
	bColor = Color3.fromRGB(40, 44, 52),
	tColor = Color3.fromRGB(220, 223, 228),
	transparency = 0
}

function Terminal.new(options)
	local terminal = {}

	local sizeX, sizeY, sizeB,
	textX, textY,
	sizeXY

	local bColor, tColor, transparency

	local emu, buffer

	local window = Instance.new("Frame")
	local console = Instance.new("Frame")
	local cursor = Instance.new("Frame")

	local cThread

	local cOn = false
	local cBlink = false
	local cThreadR = false
	
	local input = false

	local event = Instance.new("BindableEvent")

	if options then
		sizeX = options.sizeX or DEFAULT.sizeX
		sizeY = options.sizeY or DEFAULT.sizeY
		sizeB = options.sizeB or DEFAULT.bufferSize
		textY = options.textY or DEFAULT.textY
		bColor = options.bColor or DEFAULT.bColor
		tColor = options.tColor or DEFAULT.tColor
		transparency = options.transparency or DEFAULT.transparency
	else
		sizeX = DEFAULT.sizeX
		sizeY = DEFAULT.sizeY
		sizeB = DEFAULT.bufferSize
		textY = DEFAULT.textY
		bColor = DEFAULT.bColor
		tColor = DEFAULT.tColor
		transparency = DEFAULT.transparency
	end

	sizeXY = sizeX * sizeY

	textX = textY / 2
	textX = textX - textX % 1

	emu, buffer = table.create(CONSOLE_MAX_SIZE), table.create(sizeB)

	window.BackgroundColor3 = bColor
	window.BackgroundTransparency = transparency
	window.BorderSizePixel = 0
	window.ClipsDescendants = true
	window.Size = UDim2.fromOffset(sizeX * textX + 20, sizeY * textY + 10)

	console.Size = UDim2.fromOffset(textX * sizeX, textY * sizeY)
	console.Position = UDim2.fromOffset(5, 5)
	console.BackgroundTransparency = 1
	console.Parent = window

	cursor.Size = UDim2.fromOffset(textX, textY)
	cursor.Position = UDim2.fromOffset(0, 0)
	cursor.BorderSizePixel = 0
	cursor.BackgroundColor3 = Color3.new(1, 1, 1)
	cursor.BackgroundTransparency = 1
	cursor.ZIndex = 1
	cursor.Parent = console

	for i = 1, CONSOLE_MAX_SIZE do
		local text = Instance.new("TextLabel")

		text.BackgroundTransparency = 1
		--text.TextColor3 = tColor
		local color = Color3.fromRGB(math.random(100, 255), math.random(100, 255), math.random(100, 255))
		local coal = (i % (sizeX)) / sizeX
		--color = 0.3 * color.R + 0.59 * color.G + 0.11 * color.B
		--text.TextColor3 = Color3.fromHSV(math.abs(math.sin(math.rad(i))), 1, 1)
		text.TextColor3 = tColor
		text.BorderSizePixel = 0
		--text.Text = CHARS[(i-1) % (0x7F - 0x21) + 0x21]
		--text.Text = CHARS[math.random(0x21, 0x7E)]
		text.Text = ""
		text.Font = FONT
		text.TextSize = textY - 1
		text.TextXAlignment = Enum.TextXAlignment.Left
		text.TextYAlignment = Enum.TextYAlignment.Top
		text.ZIndex = 2
		text.RichText = true
		emu[i] = text
		if i <= sizeXY then
			i = i - 1
			local offset = i / sizeX
			text.Size = UDim2.fromOffset(textX, textY)
			text.Position = UDim2.fromOffset((i % sizeX) * textX, (offset - offset % 1) * textY)
			text.Parent = console
		end

	end

	for i = 1, sizeB do
		buffer[i] = {"", Color3.new()}
	end
	
	local function findegg(pos)
		local i = 2
		while pos - i > 0 do
			if buffer[pos - i][1] == 0x0A then
				i = i - 1
				break
			end
			if pos - i == 1 then
				break
			else
				i = i + 1
			end
		end
		return pos - i
	end

	local function findChicken(self, pos)
		local i = 1
		while pos + i <= self.sizeXY do
			if buffer[pos + i][1] == 0x0A then
				i = i + 1
				break
			end
			i = i + 1
		end
		return pos + i
	end
	
	function terminal:refresh()
		local bPos = self.bpos
		local i = 1

		if buffer[bPos][1] ~= 0x0A and bPos ~= self.oneEgg then
			local delta = ((findChicken(self, bPos) - self.oneEgg) % self.sizeX + 1) + 1
		end
		
		while i <= self.sizeXY do
			local byte = buffer[bPos][1]
			if byte == 0x0A then
				local length = self.sizeX - i % self.sizeX + 1
				while length > 0 do
					self.emu[i].Text = CHARS[0x20]
					i = i + 1
					length = length - 1
				end
			else
				self.emu[i].Text = CHARS[buffer[bPos][1]]
				i = i + 1
			end
			bPos = bPos + 1
		end
		
	end

	function terminal:clear()
		for i = 1, self.sizeXY do
			emu[i].Text = ""
		end
	end

	function terminal:setTransparency(value)
		window.BackgroundTransparency = value
	end

	function terminal:cursor()
		if not cOn then
			cOn = true
			cursor.Position = emu[self.position].Position
			if cBlink and not cThreadR then
				coroutine.resume(cThread)
			else
				cursor.BackgroundTransparency = 0
			end
		end
	end

	function terminal:noCursor()
		if cOn then
			cOn = false
			if not cThreadR then
				cursor.BackgroundTransparency = 1
			end
		end
	end

	function terminal:blink()
		if not cBlink then
			cBlink = true
			if cOn and not cThreadR then
				coroutine.resume(cThread)
			end
		end
	end

	function terminal:noBlink()
		cBlink = false
	end
	
	function terminal:setCursor(p)
		p = p > self.sizeXY and self.sizeXY or p
		
		self.position = p
		if cOn then
			input = true
			cursor.Position = emu[p].Position
		end
	end
	
	function terminal:scroll(x)
		local bPos = self.bpos
		local egg = self.oneEgg
		if x == -1 then
			local i = 0
			while i < self.sizeX do
				if buffer[bPos + i][1] == 0x0A then
					i = i + 1
					egg = bPos + i
					break
				end
				i = i + 1
			end
			self.bpos = bPos + i
		elseif x == 1 then
			local set = false
			if bPos > 1 then
				local i = 1
				local endp = self.sizeX
				while i < endp and bPos - i > 1 do
					if buffer[bPos - i][1] == 0x0A then
						print("lol")
						if set then
							print("'nh", bPos - i)
							i = i - 1
							break
						end
						egg = findegg(bPos - i)
						--print(egg, bPos - i)
						endp = ((bPos - i - egg) % self.sizeX) + 1
						print(i, endp)
						set = true
					end
					i = i + 1
				end
				self.bpos = bPos - i
				self.bpos = self.bpos
			end
			--if self.bpos > 1 then
				--self.bpos = self.bpos - self.sizeX
				--self.bpos = self.bpos < 1 and 1 or self.bpos
			--end
		end
		self.oneEgg = egg
		self:refresh()
	end
	
	function terminal:printE(str)
		local pos = self.position
		local sizeX = self.sizeX
		local sizeXY = self.sizeXY
		local emu = self.emu
		local i = 1
		
		while i <= #str do
			local byte = string.byte(str, i)
			
			if byte > 0x7F then
				byte = band(bnot(byte), 0xFF)
				byte = bor(byte, rshift(byte, 1))
				byte = bor(byte, rshift(byte, 2))
				byte = bor(byte, rshift(byte, 4))
				i = i + 7 - log(byte + 1, 2)
				byte = 0x3F
			end
			
			i = i + 1
			
			if byte == 0x0A or byte == 0x0D then
				pos = pos + sizeX
				pos = pos - pos % sizeX
				pos = pos >= sizeXY and sizeXY - sizeX or pos
				buffer[self.bpos][1] = 0x0A
			else
				emu[pos].Text = CHARS[byte]
				buffer[self.bpos][1] = byte
			end
			
			if pos == sizeXY then
				pos = sizeXY - sizeX
			end

			pos = pos + 1
			self.bpos = self.bpos + 1

			if cOn then
				cursor.Position = emu[pos].Position
			end
		end
		input = true
		self.position = pos
	end

	function terminal:print(str)
		local pos = self.position > self.sizeXY and self.sizeXY or self.position
		local sizeXY = self.sizeXY
		for i = 1, #str do
			local byte = str:byte(i)
			if byte ~= 0x20 then
				if byte == 0x0A then
					pos = pos + self.sizeX
					pos = pos - (pos % self.sizeX)
					pos = math.min(self.sizeXY, pos)
				else
					emu[pos].Text = CHARS[byte]	
				end
			else
				emu[pos].Text = ""
			end
			if pos >= sizeXY then
				break
			end
			pos = pos + 1
		end
		if cOn then
			cursor.Position = emu[pos].Position
		end
		self.position = pos
		input = true
	end

	cThread = coroutine.create(function()
		local dt = 0
		cThreadR = true
		while true do
			if cOn and cBlink then
				if input then
					input = false
					dt = 0
					cursor.BackgroundTransparency = 0
				end
				if dt >= CURS_OSC then
					dt = 0
					cursor.BackgroundTransparency = cursor.BackgroundTransparency == 1 and 0 or 1
				end
			else
				dt = 0
				cursor.BackgroundTransparency = cOn and 0 or 1
				cThreadR = false
				coroutine.yield()
				cThreadR = true
			end
			dt = dt + rWait(rStepped)
		end
	end)

	terminal.window = window
	terminal.console = console
	terminal.event = event
	terminal.position = 1
	terminal.sizeX = sizeX
	terminal.sizeY = sizeY
	terminal.sizeXY = sizeXY
	terminal.textX = textX
	terminal.textY = textY
	terminal.emu = emu
	terminal.bpos = 1
	terminal.oneEgg = 1

	return terminal
end

return Terminal
