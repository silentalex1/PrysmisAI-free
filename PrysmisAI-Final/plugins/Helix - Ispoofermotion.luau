local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local SERVER_URL = "https://prysmisai-free.onrender.com"

local ID_PROPS = {
	Sound = {"SoundId"},
	ImageLabel = {"Image"},
	ImageButton = {"Image"},
	Decal = {"Texture"},
	["Texture"] = {"Texture"},
	MeshPart = {"TextureID", "MeshId"},
	SpecialMesh = {"MeshId", "TextureId"},
	Animation = {"AnimationId"},
	ParticleEmitter = {"Texture"},
	Trail = {"Texture"},
	Beam = {"Texture"},
	Sky = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"},
	ShirtGraphic = {"Graphic"},
	Shirt = {"ShirtTemplate"},
	Pants = {"PantsTemplate"},
	Humanoid = {},
}

local function normalizeId(value)
	if type(value) ~= "string" then value = tostring(value) end
	local m = value:match("rbxassetid://(%d+)")
	if m then return m end
	if value:match("^%d+$") and value ~= "0" then return value end
	return ""
end

local function hasPrefix(value)
	return type(value) == "string" and value:find("rbxassetid://") ~= nil
end

local function applyFormat(newId, usedPrefix)
	if usedPrefix then return "rbxassetid://" .. newId end
	return newId
end

local function randomId()
	local digits = math.random(10, 14)
	local result = ""
	for i = 1, digits do
		result = result .. tostring(math.random(i == 1 and 1 or 0, 9))
	end
	return result
end

local scannedMap = {}
local logLines = {}
local animToken = nil
local animConnected = false

local toolbar = plugin:CreateToolbar("Helix Spoofer")
local toggleBtn = toolbar:CreateButton("Helix Spoofer", "Toggle Helix Ispoofermotion", "rbxassetid://7733960981")

local wInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right,
	true, false, 350, 640, 310, 520
)
local widget = plugin:CreateDockWidgetPluginGui("HelixIspooferV1", wInfo)
widget.Title = "Helix - Ispoofermotion"

toggleBtn.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

local C = {
	bg         = Color3.fromRGB(11, 11, 18),
	surface    = Color3.fromRGB(17, 17, 27),
	card       = Color3.fromRGB(22, 22, 36),
	border     = Color3.fromRGB(38, 38, 58),
	text       = Color3.fromRGB(215, 215, 230),
	dim        = Color3.fromRGB(120, 120, 145),
	gold       = Color3.fromRGB(245, 182, 30),
	goldDark   = Color3.fromRGB(180, 130, 15),
	green      = Color3.fromRGB(68, 200, 100),
	greenDark  = Color3.fromRGB(45, 145, 70),
	red        = Color3.fromRGB(220, 75, 75),
	blue       = Color3.fromRGB(80, 160, 240),
	warn       = Color3.fromRGB(255, 170, 40),
	inputBg    = Color3.fromRGB(14, 14, 24),
	tabActive  = Color3.fromRGB(22, 22, 36),
	tabLine    = Color3.fromRGB(245, 182, 30),
}

local function mk(class, props)
	local i = Instance.new(class)
	for k, v in pairs(props) do
		i[k] = v
	end
	return i
end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 6)
	c.Parent = p
end

local function pad(p, all, t, b, l, r2)
	local u = Instance.new("UIPadding")
	u.PaddingTop    = UDim.new(0, t  or all)
	u.PaddingBottom = UDim.new(0, b  or all)
	u.PaddingLeft   = UDim.new(0, l  or all)
	u.PaddingRight  = UDim.new(0, r2 or all)
	u.Parent = p
end

local function listLayout(p, dir, sp, align)
	local u = Instance.new("UIListLayout")
	u.FillDirection  = dir   or Enum.FillDirection.Vertical
	u.SortOrder      = Enum.SortOrder.LayoutOrder
	u.Padding        = UDim.new(0, sp or 0)
	u.HorizontalAlignment = align or Enum.HorizontalAlignment.Left
	u.Parent = p
	return u
end

local function divider(parent, lo)
	return mk("Frame", {
		BackgroundColor3 = C.border,
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 0, 1),
		LayoutOrder      = lo or 0,
		Parent           = parent,
	})
end

local function btn(parent, text, color, lo, h)
	local b = mk("TextButton", {
		BackgroundColor3 = color,
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 0, h or 36),
		Text             = text,
		TextColor3       = Color3.fromRGB(10, 10, 15),
		Font             = Enum.Font.GothamBold,
		TextSize         = 13,
		AutoButtonColor  = false,
		LayoutOrder      = lo or 0,
		Parent           = parent,
	})
	corner(b, 6)
	b.MouseEnter:Connect(function()
		b.BackgroundColor3 = color:Lerp(Color3.fromRGB(255,255,255), 0.15)
	end)
	b.MouseLeave:Connect(function()
		b.BackgroundColor3 = color
	end)
	return b
end

local function ghostBtn(parent, text, lo, h)
	local b = mk("TextButton", {
		BackgroundColor3 = C.card,
		BorderSizePixel  = 0,
		Size             = UDim2.new(1, 0, 0, h or 34),
		Text             = text,
		TextColor3       = C.text,
		Font             = Enum.Font.GothamMedium,
		TextSize         = 12,
		AutoButtonColor  = false,
		LayoutOrder      = lo or 0,
		Parent           = parent,
	})
	corner(b, 6)
	b.MouseEnter:Connect(function()
		b.BackgroundColor3 = C.border
	end)
	b.MouseLeave:Connect(function()
		b.BackgroundColor3 = C.card
	end)
	return b
end

local function statusLabel(parent, lo)
	return mk("TextLabel", {
		BackgroundTransparency = 1,
		Size       = UDim2.new(1, 0, 0, 20),
		Text       = "",
		TextColor3 = C.warn,
		Font       = Enum.Font.Gotham,
		TextSize   = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		LayoutOrder = lo or 0,
		Parent     = parent,
	})
end

local root = mk("Frame", {
	BackgroundColor3 = C.bg,
	BorderSizePixel  = 0,
	Size             = UDim2.new(1, 0, 1, 0),
	ClipsDescendants = true,
	Parent           = widget,
})

local header = mk("Frame", {
	BackgroundColor3 = C.surface,
	BorderSizePixel  = 0,
	Size             = UDim2.new(1, 0, 0, 58),
	Parent           = root,
})

mk("TextLabel", {
	BackgroundTransparency = 1,
	Position  = UDim2.new(0, 12, 0, 7),
	Size      = UDim2.new(1, -24, 0, 24),
	Text      = "Helix - Ispoofermotion",
	TextColor3 = C.text,
	Font      = Enum.Font.GothamBold,
	TextSize  = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent    = header,
})

mk("TextLabel", {
	BackgroundTransparency = 1,
	Position  = UDim2.new(0, 12, 0, 34),
	Size      = UDim2.new(1, -24, 0, 16),
	Text      = "Animation & Sound ID Manager",
	TextColor3 = C.dim,
	Font      = Enum.Font.Gotham,
	TextSize  = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent    = header,
})

mk("Frame", {
	BackgroundColor3 = C.border,
	BorderSizePixel  = 0,
	Position         = UDim2.new(0, 0, 0, 58),
	Size             = UDim2.new(1, 0, 0, 1),
	ZIndex           = 2,
	Parent           = root,
})

local tabBar = mk("Frame", {
	BackgroundColor3 = C.surface,
	BorderSizePixel  = 0,
	Position         = UDim2.new(0, 0, 0, 59),
	Size             = UDim2.new(1, 0, 0, 34),
	Parent           = root,
})
listLayout(tabBar, Enum.FillDirection.Horizontal, 0)

mk("Frame", {
	BackgroundColor3 = C.border,
	BorderSizePixel  = 0,
	Position         = UDim2.new(0, 0, 1, -1),
	Size             = UDim2.new(1, 0, 0, 1),
	ZIndex           = 2,
	Parent           = tabBar,
})

local content = mk("Frame", {
	BackgroundColor3 = C.bg,
	BorderSizePixel  = 0,
	Position         = UDim2.new(0, 0, 0, 94),
	Size             = UDim2.new(1, 0, 1, -94),
	ClipsDescendants = true,
	Parent           = root,
})

local TABS = {"Scan", "Remap", "Log", "Auto-Animate"}
local tabBtns   = {}
local tabPanels = {}

for i, name in ipairs(TABS) do
	local b = mk("TextButton", {
		BackgroundColor3 = C.surface,
		BorderSizePixel  = 0,
		Size             = UDim2.new(0.25, 0, 1, 0),
		Text             = name,
		TextColor3       = C.dim,
		Font             = Enum.Font.GothamMedium,
		TextSize         = 11,
		AutoButtonColor  = false,
		LayoutOrder      = i,
		Parent           = tabBar,
	})
	tabBtns[name] = b

	local p = mk("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		Visible                = false,
		Parent                 = content,
	})
	tabPanels[name] = p
end

local activeIndicator = {}
for name, b in pairs(tabBtns) do
	local ind = mk("Frame", {
		BackgroundColor3 = C.gold,
		BorderSizePixel  = 0,
		Position         = UDim2.new(0, 0, 1, -2),
		Size             = UDim2.new(1, 0, 0, 2),
		Visible          = false,
		ZIndex           = 3,
		Parent           = b,
	})
	activeIndicator[name] = ind
end

local currentTab = nil

local function activateTab(name)
	if currentTab == name then return end
	currentTab = name
	for n, b in pairs(tabBtns) do
		local active = (n == name)
		b.TextColor3 = active and C.gold or C.dim
		activeIndicator[n].Visible = active
	end
	for n, p in pairs(tabPanels) do
		p.Visible = (n == name)
	end
end

for name, b in pairs(tabBtns) do
	b.MouseButton1Click:Connect(function()
		activateTab(name)
	end)
end

local function addLog(msg, col)
	local t = os.date("%H:%M:%S")
	table.insert(logLines, {time = t, msg = msg, col = col or C.text})
end

local function scrollingPanel(parent)
	local sf = mk("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		CanvasSize             = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness     = 4,
		ScrollBarImageColor3   = C.border,
		AutomaticCanvasSize    = Enum.AutomaticSize.Y,
		Parent                 = parent,
	})
	return sf
end

local function innerPad(parent, amount)
	local f = mk("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Size                   = UDim2.new(1, 0, 1, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		Parent                 = parent,
	})
	pad(f, amount or 10)
	listLayout(f, Enum.FillDirection.Vertical, 8)
	return f
end

local scanPanel = tabPanels["Scan"]
local scanSf    = scrollingPanel(scanPanel)
local scanInner = innerPad(scanSf, 10)

local scanStatus = statusLabel(scanInner, 1)
scanStatus.TextXAlignment = Enum.TextXAlignment.Left

local scanBtn = btn(scanInner, "Scan Workspace for IDs", C.blue, 2)
divider(scanInner, 3)

mk("TextLabel", {
	BackgroundTransparency = 1,
	Size       = UDim2.new(1, 0, 0, 18),
	Text       = "Scanned IDs",
	TextColor3 = C.dim,
	Font       = Enum.Font.GothamMedium,
	TextSize   = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = 4,
	Parent     = scanInner,
})

local scanResultsFrame = mk("Frame", {
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Size                   = UDim2.new(1, 0, 0, 0),
	AutomaticSize          = Enum.AutomaticSize.Y,
	LayoutOrder            = 5,
	Parent                 = scanInner,
})
listLayout(scanResultsFrame, Enum.FillDirection.Vertical, 4)

local function renderScanResults()
	for _, c in ipairs(scanResultsFrame:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	local count = 0
	for id, _ in pairs(scannedMap) do
		count += 1
		local row = mk("Frame", {
			BackgroundColor3 = C.card,
			BorderSizePixel  = 0,
			Size             = UDim2.new(1, 0, 0, 30),
			LayoutOrder      = count,
			Parent           = scanResultsFrame,
		})
		corner(row, 5)
		pad(row, 0, 0, 0, 8, 8)
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Size       = UDim2.new(1, 0, 1, 0),
			Text       = id,
			TextColor3 = C.text,
			Font       = Enum.Font.Code,
			TextSize   = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent     = row,
		})
	end
	if count == 0 then
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Size       = UDim2.new(1, 0, 0, 28),
			Text       = "No IDs found yet. Click Scan.",
			TextColor3 = C.dim,
			Font       = Enum.Font.Gotham,
			TextSize   = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
			Parent     = scanResultsFrame,
		})
	end
end

renderScanResults()

scanBtn.MouseButton1Click:Connect(function()
	scannedMap = {}
	scanStatus.Text = "Scanning..."
	scanStatus.TextColor3 = C.dim
	task.wait()

	local found = {}
	local total = 0

	for _, desc in ipairs(game:GetDescendants()) do
		local props = ID_PROPS[desc.ClassName]
		if props then
			for _, prop in ipairs(props) do
				local ok, val = pcall(function() return desc[prop] end)
				if ok and val and type(val) == "string" and val ~= "" then
					local norm = normalizeId(val)
					if norm ~= "" then
						if not found[norm] then
							found[norm] = {}
							total += 1
						end
						table.insert(found[norm], {inst = desc, prop = prop, orig = val})
					end
				end
			end
		end
	end

	scannedMap = found
	renderScanResults()
	scanStatus.Text = "Found " .. total .. " unique ID(s)."
	scanStatus.TextColor3 = C.green
	addLog("Scan complete: " .. total .. " unique ID(s) found.", C.green)
end)

local remapPanel = tabPanels["Remap"]
local remapSf    = scrollingPanel(remapPanel)
local remapInner = innerPad(remapSf, 10)

mk("TextLabel", {
	BackgroundTransparency = 1,
	Size       = UDim2.new(1, 0, 0, 16),
	Text       = 'ID Mapping  —  JSON {"oldId": "newId", ...}',
	TextColor3 = C.dim,
	Font       = Enum.Font.GothamMedium,
	TextSize   = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = 1,
	Parent     = remapInner,
})

local remapBox = mk("TextBox", {
	BackgroundColor3 = C.inputBg,
	BorderSizePixel  = 0,
	Size             = UDim2.new(1, 0, 0, 140),
	Text             = "",
	PlaceholderText  = '{"oldId":"newId"}',
	TextColor3       = C.text,
	PlaceholderColor3 = C.dim,
	Font             = Enum.Font.Code,
	TextSize         = 10,
	TextXAlignment   = Enum.TextXAlignment.Left,
	TextYAlignment   = Enum.TextYAlignment.Top,
	MultiLine        = true,
	ClearTextOnFocus = false,
	LayoutOrder      = 2,
	Parent           = remapInner,
})
corner(remapBox, 6)
pad(remapBox, 0, 6, 6, 6, 6)

local remapStatus = statusLabel(remapInner, 3)

local autospoof = btn(remapInner, "Instantly Autospoof", C.gold, 4)
local exportBtn = ghostBtn(remapInner, "Export Scanned IDs as Template", 5)
local applyBtn  = btn(remapInner, "Apply Remap", C.green, 6)
local clearBtn  = ghostBtn(remapInner, "Clear Mapping Box", 7)

local function parseMapping(jsonStr)
	local mapping = {}
	local ok, result = pcall(function()
		return HttpService:JSONDecode(jsonStr)
	end)
	if ok and type(result) == "table" then
		for k, v in pairs(result) do
			local nk = normalizeId(tostring(k))
			local nv = normalizeId(tostring(v))
			if nk ~= "" and nv ~= "" then
				mapping[nk] = nv
			end
		end
	end
	return mapping
end

autospoof.MouseButton1Click:Connect(function()
	local current = {}
	if remapBox.Text ~= "" then
		local ok, decoded = pcall(function() return HttpService:JSONDecode(remapBox.Text) end)
		if ok and type(decoded) == "table" then
			for k, v in pairs(decoded) do
				current[normalizeId(tostring(k))] = normalizeId(tostring(v))
			end
		end
	end

	for id, _ in pairs(scannedMap) do
		if not current[id] or current[id] == "" then
			current[id] = randomId()
		end
	end

	if not next(current) then
		remapStatus.Text = "No scanned IDs. Run Scan first."
		remapStatus.TextColor3 = C.warn
		return
	end

	local out = {}
	for k, v in pairs(current) do
		out[k] = v
	end

	local ok2, encoded = pcall(function() return HttpService:JSONEncode(out) end)
	if ok2 then
		remapBox.Text = encoded
		local n = 0
		for _ in pairs(out) do n = n + 1 end
		remapStatus.Text = "Autospoofed " .. n .. " ID(s)."
		remapStatus.TextColor3 = C.gold
	end
end)

exportBtn.MouseButton1Click:Connect(function()
	if not next(scannedMap) then
		remapStatus.Text = "Nothing scanned yet. Run Scan first."
		remapStatus.TextColor3 = C.warn
		return
	end
	local template = {}
	for id, _ in pairs(scannedMap) do
		template[id] = ""
	end
	local ok, encoded = pcall(function() return HttpService:JSONEncode(template) end)
	if ok then
		remapBox.Text = encoded
		local n = 0
		for _ in pairs(template) do n = n + 1 end
		remapStatus.Text = "Exported " .. n .. " ID(s) as template."
		remapStatus.TextColor3 = C.green
	end
end)

applyBtn.MouseButton1Click:Connect(function()
	local raw = remapBox.Text
	if raw == "" then
		remapStatus.Text = "Mapping box is empty."
		remapStatus.TextColor3 = C.warn
		return
	end

	local mapping = parseMapping(raw)
	if not next(mapping) then
		remapStatus.Text = "No valid ID pairs found in mapping."
		remapStatus.TextColor3 = C.red
		return
	end

	ChangeHistoryService:SetWaypoint("Helix: Pre-Remap")
	local applied = 0
	local errors  = 0

	for _, desc in ipairs(game:GetDescendants()) do
		local props = ID_PROPS[desc.ClassName]
		if props then
			for _, prop in ipairs(props) do
				local ok, val = pcall(function() return desc[prop] end)
				if ok and val and type(val) == "string" and val ~= "" then
					local norm = normalizeId(val)
					local newId = mapping[norm]
					if newId and newId ~= "" then
						local usePrefix = hasPrefix(val)
						local newVal = applyFormat(newId, usePrefix)
						local setOk = pcall(function() desc[prop] = newVal end)
						if setOk then
							applied += 1
						else
							errors += 1
						end
					end
				end
			end
		end
	end

	ChangeHistoryService:SetWaypoint("Helix: Post-Remap")

	if applied > 0 then
		remapStatus.Text = "Applied " .. applied .. " remap(s). " .. (errors > 0 and errors .. " failed." or "")
		remapStatus.TextColor3 = C.green
		addLog("Remap applied: " .. applied .. " change(s).", C.green)
	else
		remapStatus.Text = "No matching IDs found in workspace."
		remapStatus.TextColor3 = C.warn
		addLog("Remap: No matching IDs found.", C.warn)
	end
end)

clearBtn.MouseButton1Click:Connect(function()
	remapBox.Text = ""
	remapStatus.Text = ""
end)

local logPanel = tabPanels["Log"]
local logSf    = scrollingPanel(logPanel)
local logInner = mk("Frame", {
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Size                   = UDim2.new(1, 0, 0, 0),
	AutomaticSize          = Enum.AutomaticSize.Y,
	Parent                 = logSf,
})
pad(logInner, 0, 8, 8, 10, 10)
listLayout(logInner, Enum.FillDirection.Vertical, 6)

local clearLogBtn = ghostBtn(logInner, "Clear Log", 0, 30)
divider(logInner, 1)

local logContainer = mk("Frame", {
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Size                   = UDim2.new(1, 0, 0, 0),
	AutomaticSize          = Enum.AutomaticSize.Y,
	LayoutOrder            = 2,
	Parent                 = logInner,
})
listLayout(logContainer, Enum.FillDirection.Vertical, 4)

local function refreshLog()
	for _, c in ipairs(logContainer:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end
	if #logLines == 0 then
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Size       = UDim2.new(1, 0, 0, 24),
			Text       = "No log entries yet.",
			TextColor3 = C.dim,
			Font       = Enum.Font.Gotham,
			TextSize   = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
			Parent     = logContainer,
		})
		return
	end
	for i, entry in ipairs(logLines) do
		local row = mk("Frame", {
			BackgroundColor3 = C.card,
			BorderSizePixel  = 0,
			Size             = UDim2.new(1, 0, 0, 0),
			AutomaticSize    = Enum.AutomaticSize.Y,
			LayoutOrder      = i,
			Parent           = logContainer,
		})
		corner(row, 5)
		pad(row, 0, 5, 5, 8, 8)
		local inner2 = mk("Frame", {
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			Size                   = UDim2.new(1, 0, 0, 0),
			AutomaticSize          = Enum.AutomaticSize.Y,
			Parent                 = row,
		})
		listLayout(inner2, Enum.FillDirection.Horizontal, 8)
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Size       = UDim2.new(0, 55, 0, 18),
			Text       = entry.time,
			TextColor3 = C.dim,
			Font       = Enum.Font.Code,
			TextSize   = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
			Parent     = inner2,
		})
		mk("TextLabel", {
			BackgroundTransparency = 1,
			Size       = UDim2.new(1, -63, 0, 18),
			Text       = entry.msg,
			TextColor3 = entry.col,
			Font       = Enum.Font.Gotham,
			TextSize   = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = 2,
			Parent     = inner2,
		})
	end
end

refreshLog()

clearLogBtn.MouseButton1Click:Connect(function()
	logLines = {}
	refreshLog()
end)

addLog("Plugin loaded.", C.green)

local animPanel = tabPanels["Auto-Animate"]
local animSf    = scrollingPanel(animPanel)
local animInner = mk("Frame", {
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Size                   = UDim2.new(1, 0, 0, 0),
	AutomaticSize          = Enum.AutomaticSize.Y,
	Parent                 = animSf,
})
pad(animInner, 0, 12, 12, 10, 10)
listLayout(animInner, Enum.FillDirection.Vertical, 10)

local tokenSection = mk("Frame", {
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Size                   = UDim2.new(1, 0, 0, 0),
	AutomaticSize          = Enum.AutomaticSize.Y,
	LayoutOrder            = 1,
	Parent                 = animInner,
})
listLayout(tokenSection, Enum.FillDirection.Vertical, 8)

local animateSection = mk("Frame", {
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Size                   = UDim2.new(1, 0, 0, 0),
	AutomaticSize          = Enum.AutomaticSize.Y,
	LayoutOrder            = 2,
	Visible                = false,
	Parent                 = animInner,
})
listLayout(animateSection, Enum.FillDirection.Vertical, 10)

mk("TextLabel", {
	BackgroundTransparency = 1,
	Size       = UDim2.new(1, 0, 0, 16),
	Text       = "Auto-Animate",
	TextColor3 = C.gold,
	Font       = Enum.Font.GothamBold,
	TextSize   = 14,
	TextXAlignment = Enum.TextXAlignment.Center,
	LayoutOrder = 0,
	Parent     = tokenSection,
})

mk("TextLabel", {
	BackgroundTransparency = 1,
	Size       = UDim2.new(1, 0, 0, 16),
	Text       = "Enter in your website token.",
	TextColor3 = C.text,
	Font       = Enum.Font.Gotham,
	TextSize   = 12,
	TextXAlignment = Enum.TextXAlignment.Center,
	LayoutOrder = 1,
	Parent     = tokenSection,
})

mk("TextLabel", {
	BackgroundTransparency = 1,
	Size       = UDim2.new(1, 0, 0, 28),
	Text       = "Get your token from prysmisai-free.onrender.com\nSettings > Studio > Generate new token",
	TextColor3 = C.dim,
	Font       = Enum.Font.Gotham,
	TextSize   = 10,
	TextXAlignment = Enum.TextXAlignment.Center,
	TextWrapped = true,
	LayoutOrder = 2,
	Parent     = tokenSection,
})

local tokenBox = mk("TextBox", {
	BackgroundColor3  = C.inputBg,
	BorderSizePixel   = 0,
	Size              = UDim2.new(1, 0, 0, 38),
	Text              = "",
	PlaceholderText   = "Paste your studio token here...",
	TextColor3        = C.text,
	PlaceholderColor3 = C.dim,
	Font              = Enum.Font.Code,
	TextSize          = 11,
	ClearTextOnFocus  = false,
	LayoutOrder       = 3,
	Parent            = tokenSection,
})
corner(tokenBox, 6)
pad(tokenBox, 0, 0, 0, 8, 8)

local tokenStatus = statusLabel(tokenSection, 4)

local submitTokenBtn = btn(tokenSection, "Submit token", C.gold, 5, 36)

local connectedBadge = mk("Frame", {
	BackgroundColor3 = Color3.fromRGB(20, 40, 25),
	BorderSizePixel  = 0,
	Size             = UDim2.new(1, 0, 0, 36),
	LayoutOrder      = 1,
	Parent           = animateSection,
})
corner(connectedBadge, 8)
pad(connectedBadge, 0, 0, 0, 12, 12)

local connectedRow = mk("Frame", {
	BackgroundTransparency = 1,
	BorderSizePixel        = 0,
	Size                   = UDim2.new(1, 0, 1, 0),
	Parent                 = connectedBadge,
})
listLayout(connectedRow, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Center)

local dot = mk("Frame", {
	BackgroundColor3 = C.green,
	BorderSizePixel  = 0,
	Size             = UDim2.new(0, 8, 0, 8),
	LayoutOrder      = 1,
	Parent           = connectedRow,
})
corner(dot, 99)

local connLabel = mk("TextLabel", {
	BackgroundTransparency = 1,
	Size       = UDim2.new(0, 200, 0, 20),
	Text       = "Connected to PrysmisAI",
	TextColor3 = C.green,
	Font       = Enum.Font.GothamMedium,
	TextSize   = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	LayoutOrder = 2,
	Parent     = connectedRow,
})

mk("TextLabel", {
	BackgroundTransparency = 1,
	Size       = UDim2.new(1, 0, 0, 16),
	Text       = "Type in any animation you want me to create.",
	TextColor3 = C.text,
	Font       = Enum.Font.Gotham,
	TextSize   = 12,
	TextXAlignment = Enum.TextXAlignment.Center,
	LayoutOrder = 2,
	Parent     = animateSection,
})

local animBox = mk("TextBox", {
	BackgroundColor3  = C.inputBg,
	BorderSizePixel   = 0,
	Size              = UDim2.new(1, 0, 0, 80),
	Text              = "",
	PlaceholderText   = "Example: Make the BasePart float up and down smoothly...",
	TextColor3        = C.text,
	PlaceholderColor3 = C.dim,
	Font              = Enum.Font.Gotham,
	TextSize          = 11,
	ClearTextOnFocus  = false,
	MultiLine         = true,
	TextXAlignment    = Enum.TextXAlignment.Left,
	TextYAlignment    = Enum.TextYAlignment.Top,
	LayoutOrder       = 3,
	Parent            = animateSection,
})
corner(animBox, 6)
pad(animBox, 0, 8, 8, 8, 8)

local animStatus = statusLabel(animateSection, 4)

local animateItBtn = btn(animateSection, "Animate it.", C.gold, 5, 38)

local disconnectBtn = ghostBtn(animateSection, "Disconnect", 6, 28)
disconnectBtn.TextColor3 = C.dim
disconnectBtn.TextSize = 10

local function showConnected(username, modelName)
	tokenSection.Visible = false
	animateSection.Visible = true
	local displayName = username or "PrysmisAI"
	if modelName and modelName ~= "" then
		connLabel.Text = "Connected  |  " .. displayName .. "  |  " .. modelName
	else
		connLabel.Text = "Connected  |  " .. displayName
	end
	addLog("Auto-Animate: Connected to server.", C.green)
end

local function showDisconnected()
	animConnected = false
	animToken = nil
	tokenSection.Visible = true
	animateSection.Visible = false
	tokenStatus.Text = ""
	tokenBox.Text = ""
	addLog("Auto-Animate: Disconnected.", C.dim)
end

submitTokenBtn.MouseButton1Click:Connect(function()
	local t = tokenBox.Text:match("^%s*(.-)%s*$")
	if t == "" then
		tokenStatus.Text = "Token cannot be empty."
		tokenStatus.TextColor3 = C.warn
		return
	end

	tokenStatus.Text = "Connecting..."
	tokenStatus.TextColor3 = C.dim
	task.wait()

	local ok, response = pcall(function()
		return HttpService:PostAsync(
			SERVER_URL .. "/api/studio/connect",
			HttpService:JSONEncode({ token = t }),
			Enum.HttpContentType.ApplicationJson,
			false
		)
	end)

	if not ok then
		tokenStatus.Text = "Connection failed. Check network."
		tokenStatus.TextColor3 = C.red
		addLog("Auto-Animate connect error: " .. tostring(response), C.red)
		return
	end

	local decoded
	local dok = pcall(function() decoded = HttpService:JSONDecode(response) end)

	if dok and decoded and decoded.success then
		animToken = t
		animConnected = true
		showConnected(decoded.username, decoded.model)
	else
		local errMsg = (dok and decoded and decoded.error) or "Invalid token."
		tokenStatus.Text = errMsg
		tokenStatus.TextColor3 = C.red
		addLog("Auto-Animate: " .. errMsg, C.red)
	end
end)

disconnectBtn.MouseButton1Click:Connect(function()
	showDisconnected()
end)

animateItBtn.MouseButton1Click:Connect(function()
	if not animConnected or not animToken then
		animStatus.Text = "Not connected. Reconnect."
		animStatus.TextColor3 = C.red
		return
	end

	local prompt = animBox.Text:match("^%s*(.-)%s*$")
	if prompt == "" then
		animStatus.Text = "Enter an animation description."
		animStatus.TextColor3 = C.warn
		return
	end

	animStatus.Text = "Generating animation..."
	animStatus.TextColor3 = C.blue
	animateItBtn.Active = false
	task.wait()

	local apiKey = plugin:GetSetting("prysmis_deepinfra_key") or ""
	local ok, response = pcall(function()
		return HttpService:PostAsync(
			SERVER_URL .. "/api/studio/animate",
			HttpService:JSONEncode({ token = animToken, prompt = prompt, apiKey = apiKey }),
			Enum.HttpContentType.ApplicationJson,
			false
		)
	end)

	animateItBtn.Active = true

	if not ok then
		animStatus.Text = "Request failed. Try again."
		animStatus.TextColor3 = C.red
		addLog("Auto-Animate request failed: " .. tostring(response), C.red)
		return
	end

	local decoded
	local dok = pcall(function() decoded = HttpService:JSONDecode(response) end)

	if not dok or not decoded or not decoded.success then
		local errMsg = (dok and decoded and decoded.error) or "Server error."
		animStatus.Text = errMsg
		animStatus.TextColor3 = C.red
		addLog("Auto-Animate error: " .. errMsg, C.red)
		return
	end

	local code = decoded.code
	if not code or code == "" then
		animStatus.Text = "AI returned no code."
		animStatus.TextColor3 = C.warn
		return
	end

	local execOk, execErr = pcall(function()
		local fn, loadErr = loadstring(code)
		if not fn then
			error(tostring(loadErr))
		end
		fn()
	end)

	if execOk then
		animStatus.Text = "Animation applied."
		animStatus.TextColor3 = C.green
		addLog("Auto-Animate: '" .. prompt:sub(1, 40) .. "' applied.", C.green)
		refreshLog()
	else
		animStatus.Text = "Execution error. Check Output."
		animStatus.TextColor3 = C.red
		warn("[Helix] Animation exec error: " .. tostring(execErr))
		addLog("Auto-Animate exec error: " .. tostring(execErr):sub(1, 60), C.red)
	end

	refreshLog()
end)

activateTab("Remap")
refreshLog()
