local module = {}

local SCROLL_X = 10
local PADDING = 5
local PAD_2 = PADDING * 2
local TOPBAR_HEIGHT = 20

local REP_INTERVAL = 0.02

local function resize(self, x, y)
	if x ~= self.sizeX or y ~= self.sizeY then
		local xy = x * y
		local oXY = self.sizeXY
		local tX = self.textX
		local tY = self.textY
		local emu = self.emu
		
		if xy > oXY then
			local console = self.console
			
			for i = oXY + 1, xy do
				emu[i].Parent = console
			end
		else
			for i = xy + 1, oXY do
				emu[i].Parent = nil
			end
		end
		for i = 0, xy - 1 do
			local offset = i / x
			
			emu[i + 1].Position = UDim2.fromOffset((i % x) * tX, (offset - offset % 1) * tY)
		end
		
		self.sizeX = x
		self.sizeY = y
		self.sizeXY = xy
		
		x = x * tX
		y = y * tY
		
		self.console.Size = UDim2.fromOffset(x, y)
		
		x = x + SCROLL_X + PAD_2
		y = y + PAD_2
		
		self.window.Size = UDim2.fromOffset(x, y)
		self.topBar.Size = UDim2.fromOffset(x, TOPBAR_HEIGHT)
		self:setCursor(self.position)
		--self:refresh()
	end
end

local UserInputService = game:GetService("UserInputService")

function module.init(terminal)
	local topBar = Instance.new("Frame")
	local drag = Instance.new("Frame")
	local uInput = Instance.new("TextBox")

	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPos = nil
	
	local focused = false

	local deltaX = 0
	local deltaY = 0

	topBar.Size = UDim2.fromOffset(terminal.sizeX * terminal.textX + (SCROLL_X + PAD_2), 20)
	topBar.BackgroundColor3 = Color3.new(0.8, 0.8, 0.8)
	topBar.BorderSizePixel = 0
	topBar.ZIndex = -100

	drag.BackgroundColor3 = Color3.new(1, 1, 1)
	drag.BorderSizePixel = 0
	drag.Size = UDim2.fromOffset(SCROLL_X, SCROLL_X)
	drag.Position = UDim2.new(1, -SCROLL_X, 1, -SCROLL_X)

	uInput.Visible = false
	uInput.MultiLine = true

	terminal.window.Size = UDim2.fromOffset(terminal.sizeX * terminal.textX + SCROLL_X + PAD_2, terminal.sizeY * terminal.textY + PAD_2)
	terminal.window.Position = UDim2.fromOffset(0, TOPBAR_HEIGHT)
	terminal.console.Position = UDim2.fromOffset(PADDING, PADDING)
	terminal.console.Active = true

	terminal.resize = resize

	drag.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local connection
			dragging = 1
			dragStart = input.Position
			startPos = Vector2.new(dragStart.X, dragStart.Y) - drag.AbsolutePosition

			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					connection:Disconnect()
				end
			end)
		end
	end)

	local function update(input)
		local delta = input.Position - dragStart
		topBar.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	topBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = 2
			dragStart = input.Position
			startPos = topBar.Position

			local a
			a = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					a:Disconnect()
					local abspos = topBar.AbsolutePosition
					local viewportsize = workspace.CurrentCamera.ViewportSize
					local x = abspos.X < 0
					local y = abspos.Y < 0
					local x1 = abspos.X + topBar.Size.X.Offset > viewportsize.X
					local y1 = abspos.Y + terminal.window.Size.Y.Offset + 20 > viewportsize.Y - 36
					if x then
						topBar.Position = UDim2.new(0, 0, 0, topBar.Position.Y.Offset)
					end
					if y then
						topBar.Position = UDim2.new(0, topBar.Position.X.Offset, 0, 0)
					end
					if x1 then
						topBar.Position = UDim2.new(0, viewportsize.X - topBar.Size.X.Offset, 0, topBar.Position.Y.Offset)
					end
					if y1 then
						topBar.Position = UDim2.new(0, topBar.Position.X.Offset, 0, viewportsize.Y - terminal.window.AbsoluteSize.Y - TOPBAR_HEIGHT - 36)
					end
				end
			end)
		end
	end)

	topBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	drag.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput then
			if dragging == 1 then
				local delta = input.Position - dragStart
				local change = false
				local x
				local y
				dragStart = input.Position
				deltaX = deltaX + (delta.X >= 0 and delta.X or -delta.X)
				deltaY = deltaY + (delta.Y >= 0 and delta.Y or -delta.Y)

				if deltaX >= terminal.textX then
					local sizeX = (input.Position.X - terminal.window.AbsolutePosition.X - PAD_2 - startPos.X) / terminal.textX
					sizeX = sizeX - sizeX % 1
					x = sizeX < 20 and 20 or sizeX
					change = true
					deltaX = 0
				end

				if deltaY >= terminal.textY then
					local sizeY = (input.Position.Y - terminal.window.AbsolutePosition.Y - startPos.Y) / terminal.textY
					sizeY = sizeY - sizeY % 1
					y = sizeY < 10 and 10 or sizeY
					change = true
					deltaY = 0
				end

				if change then
					terminal:resize(x or terminal.sizeX, y or terminal.sizeY)
				end
			elseif dragging == 2 then
				update(input)
			end
		end
	end)
	
	game:GetService("UserInputService").InputBegan:Connect(function(input)
		if focused and input.KeyCode == Enum.KeyCode.Backspace then
			local init = true
			local dt = 0
			terminal:setCursor(terminal.position - 1)
			while input.UserInputState ~= Enum.UserInputState.End do
				dt = dt + game:GetService("RunService").RenderStepped:Wait()
				if init then
					if dt >= 0.5 then
						terminal:setCursor(terminal.position - 1)
						init = false
						dt = 0
					end
				elseif dt >= REP_INTERVAL then
					terminal:setCursor(terminal.position - 1)
					dt = 0
				end
			end
		end
	end)
	
	uInput:GetPropertyChangedSignal("Text"):Connect(function()
		if uInput.Text ~= "" then
			if #uInput.Text == 1 then
				terminal:printE(uInput.Text)
			else
				for i = 1, #uInput.Text do
					terminal:printE(uInput.Text:sub(i, i))
				end
			end
			uInput.Text = ""
			--uInput:CaptureFocus()
		end
	end)
	
	uInput.Focused:Connect(function()
		focused = true
		terminal:blink()
	end)
	
	uInput.FocusLost:Connect(function()
		focused = false
		terminal:noBlink()
	end)
	
	terminal.console.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			uInput:CaptureFocus()
		end
	end)
	
	uInput.Parent = topBar
	drag.Parent = terminal.window
	terminal.window.Parent = topBar
	terminal.topBar = topBar

	return topBar
end

return module
