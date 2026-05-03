local HttpService = game:GetService("HttpService")

local BASE_URL = "https://prysmisai-free.onrender.com"

local STUDIO_SERVICES = {
	"Workspace", "Players", "Lighting", "MaterialService",
	"NetworkClient", "ReplicatedFirst", "ReplicatedStorage",
	"ServerScriptService", "ServerStorage", "StarterGui",
	"StarterPack", "StarterPlayer", "Teams", "SoundService", "TextChatService"
}

local toolbar = plugin:CreateToolbar("PrysmisAI")
local toggleButton = toolbar:CreateButton("PrysmisAI", "Open PrysmisAI Plugin", "rbxassetid://6031071057")

local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right, true, false, 340, 560, 280, 420
)
local widget = plugin:CreateDockWidgetPluginGui("PrysmisAIDock", widgetInfo)
widget.Title = "PrysmisAI"

local connectedUsername = ""
local connectedModel = ""
local isConnected = false
local studioToken = ""
local pollThread = nil

local function serializeInstance(inst, depth)
	if depth > 6 then return nil end
	local data = { name = inst.Name, class = inst.ClassName, children = {} }
	if inst:IsA("LuaSourceContainer") then
		local ok, src = pcall(function() return inst.Source end)
		if ok and src and #src < 4000 then
			data.source = src
		end
	end
	for _, child in ipairs(inst:GetChildren()) do
		local childData = serializeInstance(child, depth + 1)
		if childData then
			table.insert(data.children, childData)
		end
	end
	return data
end

local screenGui = Instance.new("Frame")
screenGui.Name = "PrysmisAIRoot"
screenGui.Size = UDim2.new(1, 0, 1, 0)
screenGui.Position = UDim2.new(0, 0, 0, 0)
screenGui.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
screenGui.BorderSizePixel = 0
screenGui.Parent = widget

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, 0)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollFrame.Parent = screenGui

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingLeft = UDim.new(0, 16)
contentPadding.PaddingRight = UDim.new(0, 16)
contentPadding.PaddingTop = UDim.new(0, 20)
contentPadding.PaddingBottom = UDim.new(0, 20)
contentPadding.Parent = scrollFrame

local contentLayout = Instance.new("UIListLayout")
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Padding = UDim.new(0, 14)
contentLayout.FillDirection = Enum.FillDirection.Vertical
contentLayout.Parent = scrollFrame

local headerRow = Instance.new("Frame")
headerRow.Size = UDim2.new(1, 0, 0, 36)
headerRow.BackgroundTransparency = 1
headerRow.LayoutOrder = 1
headerRow.Parent = scrollFrame

local headerLayout = Instance.new("UIListLayout")
headerLayout.SortOrder = Enum.SortOrder.LayoutOrder
headerLayout.Padding = UDim.new(0, 8)
headerLayout.FillDirection = Enum.FillDirection.Horizontal
headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
headerLayout.Parent = headerRow

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 0, 1, 0)
titleLabel.AutomaticSize = Enum.AutomaticSize.X
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "PrysmisAI"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.LayoutOrder = 1
titleLabel.Parent = headerRow

local betaBadge = Instance.new("Frame")
betaBadge.Size = UDim2.new(0, 46, 0, 20)
betaBadge.BackgroundColor3 = Color3.fromRGB(0, 188, 188)
betaBadge.LayoutOrder = 2
betaBadge.Parent = headerRow

local betaCorner = Instance.new("UICorner")
betaCorner.CornerRadius = UDim.new(0, 5)
betaCorner.Parent = betaBadge

local betaLabel = Instance.new("TextLabel")
betaLabel.Size = UDim2.new(1, 0, 1, 0)
betaLabel.BackgroundTransparency = 1
betaLabel.Text = "BETA"
betaLabel.TextColor3 = Color3.fromRGB(10, 10, 12)
betaLabel.Font = Enum.Font.GothamBold
betaLabel.TextSize = 11
betaLabel.Parent = betaBadge

local infoCard = Instance.new("Frame")
infoCard.Size = UDim2.new(1, 0, 0, 0)
infoCard.AutomaticSize = Enum.AutomaticSize.Y
infoCard.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
infoCard.BorderSizePixel = 0
infoCard.LayoutOrder = 2
infoCard.Parent = scrollFrame

local infoCardCorner = Instance.new("UICorner")
infoCardCorner.CornerRadius = UDim.new(0, 10)
infoCardCorner.Parent = infoCard

local infoCardPad = Instance.new("UIPadding")
infoCardPad.PaddingLeft = UDim.new(0, 16)
infoCardPad.PaddingRight = UDim.new(0, 16)
infoCardPad.PaddingTop = UDim.new(0, 4)
infoCardPad.PaddingBottom = UDim.new(0, 4)
infoCardPad.Parent = infoCard

local infoCardLayout = Instance.new("UIListLayout")
infoCardLayout.SortOrder = Enum.SortOrder.LayoutOrder
infoCardLayout.FillDirection = Enum.FillDirection.Vertical
infoCardLayout.Parent = infoCard

local function makeDivider(parent, order)
	local div = Instance.new("Frame")
	div.Size = UDim2.new(1, 0, 0, 1)
	div.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
	div.BorderSizePixel = 0
	div.LayoutOrder = order
	div.Parent = parent
end

local function makeInfoRow(parent, labelText, valueText, valueColor, order)
	local row = Instance.new("Frame")
	row.Name = labelText .. "Row"
	row.Size = UDim2.new(1, 0, 0, 52)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 100, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(140, 140, 155)
	label.Font = Enum.Font.Gotham
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	if labelText == "Status" then
		local dotHolder = Instance.new("Frame")
		dotHolder.Size = UDim2.new(0, 0, 0, 0)
		dotHolder.AutomaticSize = Enum.AutomaticSize.XY
		dotHolder.BackgroundTransparency = 1
		dotHolder.Position = UDim2.new(0, 100, 0.5, -8)
		dotHolder.Parent = row

		local dotLayout = Instance.new("UIListLayout")
		dotLayout.FillDirection = Enum.FillDirection.Horizontal
		dotLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		dotLayout.Padding = UDim.new(0, 6)
		dotLayout.Parent = dotHolder

		local statusDot = Instance.new("Frame")
		statusDot.Name = "StatusDot"
		statusDot.Size = UDim2.new(0, 10, 0, 10)
		statusDot.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
		statusDot.BorderSizePixel = 0
		statusDot.LayoutOrder = 1
		statusDot.Parent = dotHolder

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(1, 0)
		dotCorner.Parent = statusDot

		local statusValue = Instance.new("TextLabel")
		statusValue.Name = "StatusValue"
		statusValue.Size = UDim2.new(0, 0, 0, 0)
		statusValue.AutomaticSize = Enum.AutomaticSize.XY
		statusValue.BackgroundTransparency = 1
		statusValue.Text = "Disconnected"
		statusValue.TextColor3 = Color3.fromRGB(200, 70, 70)
		statusValue.Font = Enum.Font.GothamBold
		statusValue.TextSize = 14
		statusValue.LayoutOrder = 2
		statusValue.Parent = dotHolder

		return statusDot, statusValue
	else
		local value = Instance.new("TextLabel")
		value.Name = "Value"
		value.Size = UDim2.new(1, -100, 1, 0)
		value.Position = UDim2.new(0, 100, 0, 0)
		value.BackgroundTransparency = 1
		value.Text = valueText
		value.TextColor3 = valueColor
		value.Font = Enum.Font.Gotham
		value.TextSize = 13
		value.TextXAlignment = Enum.TextXAlignment.Left
		value.TextTruncate = Enum.TextTruncate.AtEnd
		value.Parent = row
		return value
	end
end

local statusDot, statusValue = makeInfoRow(infoCard, "Status", "Disconnected", Color3.fromRGB(200, 70, 70), 1)
makeDivider(infoCard, 2)
local modelValue = makeInfoRow(infoCard, "AI Model", "—", Color3.fromRGB(56, 189, 248), 3)
makeDivider(infoCard, 4)
local userValue = makeInfoRow(infoCard, "User", "—", Color3.fromRGB(220, 220, 235), 5)

local tokenInput = Instance.new("TextBox")
tokenInput.Size = UDim2.new(1, 0, 0, 46)
tokenInput.BackgroundColor3 = Color3.fromRGB(26, 26, 30)
tokenInput.BorderSizePixel = 0
tokenInput.PlaceholderText = "Paste plugin token from website..."
tokenInput.PlaceholderColor3 = Color3.fromRGB(90, 90, 105)
tokenInput.Text = ""
tokenInput.TextColor3 = Color3.fromRGB(220, 220, 235)
tokenInput.Font = Enum.Font.Gotham
tokenInput.TextSize = 13
tokenInput.ClearTextOnFocus = false
tokenInput.LayoutOrder = 3
tokenInput.Parent = scrollFrame

local tokenCorner = Instance.new("UICorner")
tokenCorner.CornerRadius = UDim.new(0, 10)
tokenCorner.Parent = tokenInput

local tokenPad = Instance.new("UIPadding")
tokenPad.PaddingLeft = UDim.new(0, 14)
tokenPad.PaddingRight = UDim.new(0, 14)
tokenPad.Parent = tokenInput

local connectBtn = Instance.new("TextButton")
connectBtn.Size = UDim2.new(1, 0, 0, 48)
connectBtn.BackgroundColor3 = Color3.fromRGB(0, 128, 128)
connectBtn.BorderSizePixel = 0
connectBtn.Text = "CONNECT"
connectBtn.TextColor3 = Color3.fromRGB(160, 255, 240)
connectBtn.Font = Enum.Font.GothamBold
connectBtn.TextSize = 15
connectBtn.LayoutOrder = 4
connectBtn.Parent = scrollFrame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 10)
btnCorner.Parent = connectBtn

local sendFilesBtn = Instance.new("TextButton")
sendFilesBtn.Size = UDim2.new(1, 0, 0, 48)
sendFilesBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
sendFilesBtn.BorderSizePixel = 0
sendFilesBtn.Text = "SEND FILES"
sendFilesBtn.TextColor3 = Color3.fromRGB(200, 220, 255)
sendFilesBtn.Font = Enum.Font.GothamBold
sendFilesBtn.TextSize = 15
sendFilesBtn.LayoutOrder = 5
sendFilesBtn.Visible = false
sendFilesBtn.Parent = scrollFrame

local sendFilesBtnCorner = Instance.new("UICorner")
sendFilesBtnCorner.CornerRadius = UDim.new(0, 10)
sendFilesBtnCorner.Parent = sendFilesBtn

local statusMsg = Instance.new("TextLabel")
statusMsg.Size = UDim2.new(1, 0, 0, 0)
statusMsg.AutomaticSize = Enum.AutomaticSize.Y
statusMsg.BackgroundTransparency = 1
statusMsg.Text = ""
statusMsg.TextColor3 = Color3.fromRGB(200, 80, 80)
statusMsg.Font = Enum.Font.Gotham
statusMsg.TextSize = 12
statusMsg.TextWrapped = true
statusMsg.TextXAlignment = Enum.TextXAlignment.Center
statusMsg.LayoutOrder = 6
statusMsg.Parent = scrollFrame

local function showError(msg)
	statusMsg.TextColor3 = Color3.fromRGB(220, 80, 80)
	statusMsg.Text = msg
end

local function showSuccess(msg)
	statusMsg.TextColor3 = Color3.fromRGB(72, 199, 142)
	statusMsg.Text = msg
end

local function setConnectedState(username, model)
	isConnected = true
	connectedUsername = username
	connectedModel = model

	if statusDot then statusDot.BackgroundColor3 = Color3.fromRGB(72, 199, 142) end
	if statusValue then
		statusValue.Text = "Connected"
		statusValue.TextColor3 = Color3.fromRGB(72, 199, 142)
	end

	userValue.Text = username
	modelValue.Text = model

	tokenInput.Visible = false
	connectBtn.Text = "DISCONNECT"
	connectBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
	connectBtn.TextColor3 = Color3.fromRGB(160, 255, 240)
	sendFilesBtn.Visible = true
	statusMsg.Text = ""
end

local function setDisconnectedState()
	isConnected = false
	connectedUsername = ""
	connectedModel = ""
	studioToken = ""

	if statusDot then statusDot.BackgroundColor3 = Color3.fromRGB(180, 60, 60) end
	if statusValue then
		statusValue.Text = "Disconnected"
		statusValue.TextColor3 = Color3.fromRGB(200, 70, 70)
	end

	userValue.Text = "—"
	modelValue.Text = "—"

	tokenInput.Visible = true
	tokenInput.Text = ""
	connectBtn.Text = "CONNECT"
	connectBtn.BackgroundColor3 = Color3.fromRGB(0, 128, 128)
	connectBtn.TextColor3 = Color3.fromRGB(160, 255, 240)
	sendFilesBtn.Visible = false
	statusMsg.Text = ""

	if pollThread then
		task.cancel(pollThread)
		pollThread = nil
	end
end

local function startPolling(token)
	if pollThread then
		task.cancel(pollThread)
	end
	pollThread = task.spawn(function()
		while isConnected do
			task.wait(3)
			local ok, resp = pcall(function()
				return HttpService:GetAsync(BASE_URL .. "/api/studio/poll?token=" .. token)
			end)
			if ok and resp then
				local dok, data = pcall(function() return HttpService:JSONDecode(resp) end)
				if dok and data and data.commands then
					for _, cmd in ipairs(data.commands) do
						if cmd.type == "execute" and cmd.code and cmd.code ~= "" then
							local execOk, execErr = pcall(function()
								local fn, loadErr = loadstring(cmd.code)
								if not fn then error(tostring(loadErr)) end
								fn()
							end)
							if not execOk then
								warn("[PrysmisAI] Command exec error: " .. tostring(execErr))
							end
						end
					end
				end
			end
		end
	end)
end

local function attemptConnect()
	local token = tokenInput.Text:match("^%s*(.-)%s*$")
	if token == "" then
		showError("Please paste your plugin token first.")
		return
	end

	connectBtn.Text = "Connecting..."
	connectBtn.BackgroundColor3 = Color3.fromRGB(40, 90, 90)
	statusMsg.Text = ""

	local success, result = pcall(function()
		return HttpService:RequestAsync({
			Url = BASE_URL .. "/api/studio/connect",
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode({ token = token })
		})
	end)

	if not success then
		connectBtn.Text = "CONNECT"
		connectBtn.BackgroundColor3 = Color3.fromRGB(0, 128, 128)
		showError("Network error. Check your connection.")
		return
	end

	if result.StatusCode == 200 then
		local data = HttpService:JSONDecode(result.Body)
		if data.success then
			studioToken = token
			setConnectedState(data.username or "Unknown", data.model or "llama3.2-vision")
			showSuccess("Connected successfully.")
			startPolling(token)
		else
			connectBtn.Text = "CONNECT"
			connectBtn.BackgroundColor3 = Color3.fromRGB(0, 128, 128)
			showError(data.error or "Invalid token.")
		end
	elseif result.StatusCode == 401 then
		connectBtn.Text = "CONNECT"
		connectBtn.BackgroundColor3 = Color3.fromRGB(0, 128, 128)
		showError("Invalid or expired token.")
	else
		connectBtn.Text = "CONNECT"
		connectBtn.BackgroundColor3 = Color3.fromRGB(0, 128, 128)
		showError("Server error (" .. result.StatusCode .. ").")
	end
end

connectBtn.MouseButton1Click:Connect(function()
	if isConnected then
		setDisconnectedState()
	else
		attemptConnect()
	end
end)

connectBtn.MouseEnter:Connect(function()
	if isConnected then
		connectBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
		connectBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
		connectBtn.Text = "DISCONNECT"
	else
		connectBtn.BackgroundColor3 = Color3.fromRGB(0, 160, 160)
	end
end)

connectBtn.MouseLeave:Connect(function()
	if isConnected then
		connectBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 100)
		connectBtn.TextColor3 = Color3.fromRGB(160, 255, 240)
		connectBtn.Text = "DISCONNECT"
	else
		connectBtn.BackgroundColor3 = Color3.fromRGB(0, 128, 128)
		connectBtn.TextColor3 = Color3.fromRGB(160, 255, 240)
	end
end)

sendFilesBtn.MouseButton1Click:Connect(function()
	if not isConnected or studioToken == "" then
		showError("Not connected.")
		return
	end

	sendFilesBtn.Text = "Sending..."
	sendFilesBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 140)

	local fileTree = {}
	for _, serviceName in ipairs(STUDIO_SERVICES) do
		local ok, service = pcall(function() return game:GetService(serviceName) end)
		if ok and service then
			local serialized = serializeInstance(service, 0)
			if serialized then
				fileTree[serviceName] = serialized
			end
		end
	end

	local jsonOk, jsonBody = pcall(function()
		return HttpService:JSONEncode({ token = studioToken, files = fileTree })
	end)

	if not jsonOk then
		sendFilesBtn.Text = "SEND FILES"
		sendFilesBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
		showError("Failed to serialize files.")
		return
	end

	local success, result = pcall(function()
		return HttpService:RequestAsync({
			Url = BASE_URL .. "/api/studio/files",
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = jsonBody
		})
	end)

	sendFilesBtn.Text = "SEND FILES"
	sendFilesBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 180)

	if success and result.StatusCode == 200 then
		showSuccess("Files sent. AI can now see your project.")
	else
		showError("Failed to send files.")
	end
end)

sendFilesBtn.MouseEnter:Connect(function()
	sendFilesBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 220)
end)
sendFilesBtn.MouseLeave:Connect(function()
	sendFilesBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 180)
end)

toggleButton.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

setDisconnectedState()
