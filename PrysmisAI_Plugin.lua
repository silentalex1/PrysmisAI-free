local BASE_URL = "https://prysmisai-free.onrender.com"

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local StudioService = game:GetService("StudioService")

local toolbar = plugin:CreateToolbar("PrysmisAI")
local toggleBtn = toolbar:CreateButton("PrysmisAI", "Open PrysmisAI panel", "rbxassetid://6031068421")

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	500,
	420,
	400,
	320
)

local widget = plugin:CreateDockWidgetPluginGui("PrysmisAI_Widget", widgetInfo)
widget.Title = "PrysmisAI"
widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

toggleBtn.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

local BG_DARK   = Color3.fromRGB(18, 18, 22)
local BG_CARD   = Color3.fromRGB(26, 27, 33)
local BG_INPUT  = Color3.fromRGB(22, 23, 28)
local BORDER    = Color3.fromRGB(45, 48, 58)
local TEXT_MAIN = Color3.fromRGB(230, 232, 240)
local TEXT_DIM  = Color3.fromRGB(120, 125, 145)
local TEAL      = Color3.fromRGB(26, 160, 140)
local TEAL_DIM  = Color3.fromRGB(20, 130, 115)
local GREEN     = Color3.fromRGB(40, 210, 140)
local BETA_BG   = Color3.fromRGB(40, 140, 220)

local root = Instance.new("Frame")
root.Size = UDim2.new(1, 0, 1, 0)
root.BackgroundColor3 = BG_DARK
root.BorderSizePixel = 0
root.Parent = widget

local padding = Instance.new("UIPadding")
padding.PaddingTop    = UDim.new(0, 22)
padding.PaddingBottom = UDim.new(0, 22)
padding.PaddingLeft   = UDim.new(0, 22)
padding.PaddingRight  = UDim.new(0, 22)
padding.Parent = root

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 16)
layout.Parent = root

local headerRow = Instance.new("Frame")
headerRow.Size = UDim2.new(1, 0, 0, 32)
headerRow.BackgroundTransparency = 1
headerRow.LayoutOrder = 1
headerRow.Parent = root

local headerLayout = Instance.new("UIListLayout")
headerLayout.FillDirection = Enum.FillDirection.Horizontal
headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
headerLayout.Padding = UDim.new(0, 10)
headerLayout.Parent = headerRow

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 130, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "PrysmisAI"
titleLabel.TextColor3 = TEXT_MAIN
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 20
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = headerRow

local betaBadge = Instance.new("TextLabel")
betaBadge.Size = UDim2.new(0, 52, 0, 22)
betaBadge.BackgroundColor3 = BETA_BG
betaBadge.Text = "BETA"
betaBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
betaBadge.Font = Enum.Font.GothamBold
betaBadge.TextSize = 11
betaBadge.Parent = headerRow

local betaCorner = Instance.new("UICorner")
betaCorner.CornerRadius = UDim.new(0, 5)
betaCorner.Parent = betaBadge

local card = Instance.new("Frame")
card.Size = UDim2.new(1, 0, 0, 190)
card.BackgroundColor3 = BG_CARD
card.BorderSizePixel = 0
card.LayoutOrder = 2
card.Parent = root

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 8)
cardCorner.Parent = card

local cardStroke = Instance.new("UIStroke")
cardStroke.Color = BORDER
cardStroke.Thickness = 1
cardStroke.Parent = card

local cardPad = Instance.new("UIPadding")
cardPad.PaddingLeft   = UDim.new(0, 16)
cardPad.PaddingRight  = UDim.new(0, 16)
cardPad.PaddingTop    = UDim.new(0, 2)
cardPad.PaddingBottom = UDim.new(0, 2)
cardPad.Parent = card

local function makeRow(order, labelText, yPos)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 62)
	row.BackgroundTransparency = 1
	row.Position = UDim2.new(0, 0, 0, yPos)
	row.Parent = card

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.35, 0, 0, 20)
	lbl.Position = UDim2.new(0, 0, 0.5, -10)
	lbl.BackgroundTransparency = 1
	lbl.Text = labelText
	lbl.TextColor3 = TEXT_DIM
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local val = Instance.new("TextLabel")
	val.Size = UDim2.new(0.65, -10, 0, 20)
	val.Position = UDim2.new(0.35, 0, 0.5, -10)
	val.BackgroundTransparency = 1
	val.Text = "—"
	val.TextColor3 = TEXT_MAIN
	val.Font = Enum.Font.Gotham
	val.TextSize = 13
	val.TextXAlignment = Enum.TextXAlignment.Left
	val.TextTruncate = Enum.TextTruncate.AtEnd
	val.Parent = row

	if order < 3 then
		local div = Instance.new("Frame")
		div.Size = UDim2.new(1, 0, 0, 1)
		div.Position = UDim2.new(0, 0, 1, -1)
		div.BackgroundColor3 = BORDER
		div.BorderSizePixel = 0
		div.Parent = row
	end

	return lbl, val
end

local _, statusVal  = makeRow(1, "Status",   0)
local _, modelVal   = makeRow(2, "AI Model", 62)
local _, userVal    = makeRow(3, "User",     124)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 10, 0, 10)
statusDot.Position = UDim2.new(0, 0, 0.5, -5)
statusDot.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
statusDot.BorderSizePixel = 0
statusDot.Parent = statusVal.Parent

local dotCorner = Instance.new("UICorner")
dotCorner.CornerRadius = UDim.new(1, 0)
dotCorner.Parent = statusDot

statusVal.Position = UDim2.new(0, 16, 0.5, -10)
statusVal.Size = UDim2.new(0.65, -26, 0, 20)

local tokenInput = Instance.new("TextBox")
tokenInput.Size = UDim2.new(1, 0, 0, 42)
tokenInput.BackgroundColor3 = BG_INPUT
tokenInput.BorderSizePixel = 0
tokenInput.Text = ""
tokenInput.PlaceholderText = "Paste plugin token from website..."
tokenInput.PlaceholderColor3 = TEXT_DIM
tokenInput.TextColor3 = TEXT_MAIN
tokenInput.Font = Enum.Font.Gotham
tokenInput.TextSize = 13
tokenInput.ClearTextOnFocus = false
tokenInput.LayoutOrder = 3
tokenInput.Parent = root

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = tokenInput

local inputStroke = Instance.new("UIStroke")
inputStroke.Color = BORDER
inputStroke.Thickness = 1
inputStroke.Parent = tokenInput

local inputPad = Instance.new("UIPadding")
inputPad.PaddingLeft  = UDim.new(0, 14)
inputPad.PaddingRight = UDim.new(0, 14)
inputPad.Parent = tokenInput

local connectBtn = Instance.new("TextButton")
connectBtn.Size = UDim2.new(1, 0, 0, 46)
connectBtn.BackgroundColor3 = TEAL
connectBtn.BorderSizePixel = 0
connectBtn.Text = "Connect"
connectBtn.TextColor3 = Color3.fromRGB(200, 255, 240)
connectBtn.Font = Enum.Font.GothamBold
connectBtn.TextSize = 16
connectBtn.LayoutOrder = 4
connectBtn.Parent = root

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 8)
btnCorner.Parent = connectBtn

local connected = false
local currentToken = ""
local pollConn = nil

local function setDisconnectedState()
	connected = false
	statusDot.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
	statusVal.Text = "Disconnected"
	statusVal.TextColor3 = TEXT_DIM
	modelVal.Text = "—"
	userVal.Text = "—"
	connectBtn.Text = "Connect"
	connectBtn.BackgroundColor3 = TEAL
	connectBtn.TextColor3 = Color3.fromRGB(200, 255, 240)
	if pollConn then pollConn:Disconnect() pollConn = nil end
end

local function setConnectedState(username, model)
	connected = true
	statusDot.BackgroundColor3 = GREEN
	statusVal.Text = "Connected"
	statusVal.TextColor3 = GREEN
	modelVal.Text = model or "openai/gpt-5.2"
	modelVal.TextColor3 = Color3.fromRGB(80, 180, 255)
	userVal.Text = username or "Unknown"
	userVal.TextColor3 = TEXT_MAIN
	connectBtn.Text = "Disconnect"
	connectBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 50)
	connectBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
end

local function buildFileTree()
	local tree = {}
	local function walk(inst, depth)
		if depth > 5 then return end
		local entry = {
			className = inst.ClassName,
			name = inst.Name,
			children = {},
			properties = {}
		}
		if inst:IsA("LuaSourceContainer") then
			local ok, src = pcall(function() return inst.Source end)
			if ok then entry.properties.Source = src end
		end
		if inst:IsA("BasePart") then
			entry.properties.Size = tostring(inst.Size)
			entry.properties.Position = tostring(inst.Position)
		end
		for _, child in ipairs(inst:GetChildren()) do
			table.insert(entry.children, walk(child, depth + 1))
		end
		return entry
	end
	local services = {
		"Workspace", "ServerScriptService", "StarterPlayer",
		"StarterGui", "ReplicatedStorage", "Lighting", "ServerStorage"
	}
	for _, svcName in ipairs(services) do
		local ok, svc = pcall(function() return game:GetService(svcName) end)
		if ok and svc then
			tree[svcName] = walk(svc, 0)
		end
	end
	return tree
end

local function sendFiles(token)
	local ok, files = pcall(buildFileTree)
	if not ok then return end
	local body = HttpService:JSONEncode({ token = token, files = files })
	pcall(function()
		HttpService:RequestAsync({
			Url = BASE_URL .. "/api/studio/files",
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = body
		})
	end)
end

local function pollCommands(token)
	if pollConn then pollConn:Disconnect() end
	pollConn = RunService.Heartbeat:Connect(function()
		task.spawn(function()
			local ok, res = pcall(function()
				return HttpService:RequestAsync({
					Url = BASE_URL .. "/api/studio/poll?token=" .. token,
					Method = "GET",
					Headers = { ["Content-Type"] = "application/json" }
				})
			end)
			if not ok or not res or res.StatusCode ~= 200 then return end
			local parsed = HttpService:JSONDecode(res.Body)
			if not parsed.commands or #parsed.commands == 0 then return end
			for _, cmd in ipairs(parsed.commands) do
				task.spawn(function()
					if cmd.action == "create_script" then
						local parent = game:FindService(cmd.parent) or game.Workspace
						local s
						if cmd.scriptType == "LocalScript" then
							s = Instance.new("LocalScript")
						elseif cmd.scriptType == "ModuleScript" then
							s = Instance.new("ModuleScript")
						else
							s = Instance.new("Script")
						end
						s.Name = cmd.name or "PrysmisScript"
						if cmd.source then s.Source = cmd.source end
						s.Parent = parent
					elseif cmd.action == "create_part" then
						local parent = game:FindService(cmd.parent) or game.Workspace
						local p = Instance.new("Part")
						p.Name = cmd.name or "Part"
						if cmd.anchored ~= nil then p.Anchored = cmd.anchored end
						if cmd.size then p.Size = Vector3.new(cmd.size[1], cmd.size[2], cmd.size[3]) end
						if cmd.position then p.Position = Vector3.new(cmd.position[1], cmd.position[2], cmd.position[3]) end
						if cmd.color then p.BrickColor = BrickColor.new(cmd.color) end
						if cmd.material then p.Material = Enum.Material[cmd.material] or Enum.Material.SmoothPlastic end
						p.Parent = parent
					elseif cmd.action == "delete_instance" then
						local parts = string.split(cmd.path, ".")
						local inst = game
						for _, part in ipairs(parts) do
							local next = inst:FindFirstChild(part)
							if not next then pcall(function() next = game:GetService(part) end) end
							if not next then inst = nil break end
							inst = next
						end
						if inst and inst ~= game then inst:Destroy() end
					elseif cmd.action == "modify_property" then
						local parts = string.split(cmd.path, ".")
						local inst = game
						for _, part in ipairs(parts) do
							local next = inst:FindFirstChild(part)
							if not next then pcall(function() next = game:GetService(part) end) end
							if not next then inst = nil break end
							inst = next
						end
						if inst and inst ~= game then
							pcall(function() inst[cmd.property] = cmd.value end)
						end
					end
					pcall(function()
						HttpService:RequestAsync({
							Url = BASE_URL .. "/api/studio/ack",
							Method = "POST",
							Headers = { ["Content-Type"] = "application/json" },
							Body = HttpService:JSONEncode({ token = token, commandId = cmd.id })
						})
					end)
				end)
			end
		end)
	end)
end

local pollTimer = 0
local POLL_INTERVAL = 3

RunService.Heartbeat:Connect(function(dt)
	if not connected then return end
	pollTimer += dt
	if pollTimer < POLL_INTERVAL then return end
	pollTimer = 0
	task.spawn(function()
		local ok, res = pcall(function()
			return HttpService:RequestAsync({
				Url = BASE_URL .. "/api/studio/poll?token=" .. currentToken,
				Method = "GET",
				Headers = { ["Content-Type"] = "application/json" }
			})
		end)
		if not ok or not res or res.StatusCode ~= 200 then return end
		local parsed = pcall(function() return HttpService:JSONDecode(res.Body) end)
	end)
end)

connectBtn.MouseButton1Click:Connect(function()
	if connected then
		setDisconnectedState()
		currentToken = ""
		tokenInput.Text = ""
		return
	end

	local token = tokenInput.Text and tokenInput.Text:match("^%s*(.-)%s*$") or ""
	if token == "" then
		tokenInput.PlaceholderText = "⚠ Please paste your token first"
		task.delay(2.5, function()
			tokenInput.PlaceholderText = "Paste plugin token from website..."
		end)
		return
	end

	connectBtn.Text = "Connecting..."
	connectBtn.BackgroundColor3 = Color3.fromRGB(30, 110, 100)

	task.spawn(function()
		local ok, res = pcall(function()
			return HttpService:RequestAsync({
				Url = BASE_URL .. "/api/studio/connect",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = HttpService:JSONEncode({ token = token })
			})
		end)

		if not ok or not res then
			connectBtn.Text = "Connect"
			connectBtn.BackgroundColor3 = TEAL
			tokenInput.PlaceholderText = "⚠ Network error — try again"
			task.delay(3, function()
				tokenInput.PlaceholderText = "Paste plugin token from website..."
			end)
			return
		end

		if res.StatusCode == 200 then
			local data = HttpService:JSONDecode(res.Body)
			if data.success then
				currentToken = token
				setConnectedState(data.username, data.model)
				task.spawn(function() sendFiles(currentToken) end)
				pollCommands(currentToken)
			else
				connectBtn.Text = "Connect"
				connectBtn.BackgroundColor3 = TEAL
				tokenInput.PlaceholderText = "⚠ " .. (data.error or "Invalid token")
				task.delay(3, function()
					tokenInput.PlaceholderText = "Paste plugin token from website..."
				end)
			end
		elseif res.StatusCode == 401 then
			connectBtn.Text = "Connect"
			connectBtn.BackgroundColor3 = TEAL
			tokenInput.PlaceholderText = "⚠ Invalid or expired token"
			task.delay(3, function()
				tokenInput.PlaceholderText = "Paste plugin token from website..."
			end)
		else
			connectBtn.Text = "Connect"
			connectBtn.BackgroundColor3 = TEAL
			tokenInput.PlaceholderText = "⚠ Server error (" .. res.StatusCode .. ")"
			task.delay(3, function()
				tokenInput.PlaceholderText = "Paste plugin token from website..."
			end)
		end
	end)
end)

connectBtn.MouseEnter:Connect(function()
	if connected then
		connectBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 60)
	else
		connectBtn.BackgroundColor3 = TEAL_DIM
	end
end)

connectBtn.MouseLeave:Connect(function()
	if connected then
		connectBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 50)
	else
		connectBtn.BackgroundColor3 = TEAL
	end
end)

setDisconnectedState()
