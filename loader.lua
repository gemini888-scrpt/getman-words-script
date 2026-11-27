-- getman words (smooth obsidian UI + real human legit)
getgenv().__GWGen = (getgenv().__GWGen or 0) + 1
local GEN = getgenv().__GWGen
local function alive() return getgenv().__GWGen == GEN end

local P = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local LP = P.LocalPlayer

local WG = RS:WaitForChild("WordGame", 30)
local Action = WG and WG:WaitForChild("Action", 15)
local State = WG and WG:WaitForChild("State", 15)
if not (Action and State) then return end

local Cfg = { solve = true, mode = "legit", choose = true, safe = true, show = true, tries = 25 }
local MODES = {
	legit      = { T = {0.85, 1.70}, C = {0.15, 0.30}, TYPO = 0.20, PAUSE = 0.25, END = {0.25, 0.50}, FAST = false },
	superlegit = { T = {1.35, 2.60}, C = {0.22, 0.42}, TYPO = 0.28, PAUSE = 0.40, END = {0.35, 0.70}, FAST = false },
	rage       = { T = {0.02, 0.06}, C = {0.01, 0.02}, TYPO = 0,    PAUSE = 0,    END = {0, 0},       FAST = true  },
}
local BAD_END = { ["й"]=true, ["ь"]=true, ["ъ"]=true, ["ы"]=true }
local CACHE = "getman_words_v2.txt"

local function rnd(a, b) return a + (b - a) * math.random() end
local function uLen(s) local ok, c = pcall(utf8.len, s) return ok and c or 0 end
local function ruLow(raw)
	if type(raw) ~= "string" then return "" end
	local s = string.lower((string.gsub(raw, "%s+", "")))
	local ok, r = pcall(function()
		local t = {}
		for _, c in utf8.codes(s) do
			if c >= 0x0410 and c <= 0x042F then c += 32 elseif c == 0x0401 then c = 0x0451 end
			t[#t+1] = utf8.char(c)
		end
		return table.concat(t)
	end)
	return ok and r or s
end
local function ruUp(raw)
	if type(raw) ~= "string" then return "" end
	local ok, r = pcall(function()
		local t = {}
		for _, c in utf8.codes(string.upper(raw)) do
			if c >= 0x0430 and c <= 0x044F then c -= 32 elseif c == 0x0451 then c = 0x0401 end
			t[#t+1] = utf8.char(c)
		end
		return table.concat(t)
	end)
	return ok and r or raw
end
local function clean(raw)
	local w = ruLow(raw)
	if w == "" then return nil end
	local n = 0
	for _, c in utf8.codes(w) do
		if not ((c >= 0x0430 and c <= 0x044F) or c == 0x0451) then return nil end
		n += 1
		if n > 28 then return nil end
	end
	return n >= 3 and w or nil
end
local function rest(w, p)
	p = ruLow(p or "")
	return string.sub(w, (#p > 0 and #p or 2) + 1)
end

local KB = "йцукенгшщзхъфывапролджэячсмитьбю"
local KB_LIST = {}
for _, c in utf8.codes(KB) do KB_LIST[#KB_LIST+1] = utf8.char(c) end
local function typoChar(ch)
	for i, v in ipairs(KB_LIST) do
		if v == ch then
			local d = (math.random() < 0.5) and -1 or 1
			return KB_LIST[math.clamp(i + d, 1, #KB_LIST)]
		end
	end
	return KB_LIST[math.random(1, #KB_LIST)]
end

-- === СЛОВАРЬ (БЕЗ ИЗМЕНЕНИЙ) ===
local Dict = getgenv().__GWDict or { b = {}, total = 0, ok = false }
local function loadDict()
	if Dict.ok then return end
	local saved = (type(readfile) == "function") and pcall(readfile, CACHE) and readfile(CACHE) or nil
	if saved and #saved > 50000 then
		for line in string.gmatch(saved, "[^\r\n]+") do
			local w = clean(line)
			if w then
				local k = string.sub(w, 1, 2)
				Dict.b[k] = Dict.b[k] or {}
				table.insert(Dict.b[k], w)
				Dict.total += 1
			end
		end
		Dict.ok = true
		getgenv().__GWDict = Dict
		return
	end

	local function get(u)
		local ok, res = pcall(function() return game:HttpGet(u) end)
		return (ok and type(res) == "string" and #res > 1000) and res or nil
	end
	local nounsRaw = get("https://raw.githubusercontent.com/Harrix/Russian-Nouns/main/dist/russian_nouns.txt")
		or get("https://cdn.jsdelivr.net/gh/Harrix/Russian-Nouns@main/dist/russian_nouns.txt")
	local freqRaw = get("https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/ru/ru_50k.txt")

	local nounSet, allNouns = {}, {}
	if nounsRaw then
		for line in string.gmatch(nounsRaw, "[^\r\n]+") do
			local w = clean(line)
			if w and not nounSet[w] then
				nounSet[w] = true
				allNouns[#allNouns+1] = w
			end
		end
	end
	local ordered, used = {}, {}
	if freqRaw and #allNouns > 0 then
		for line in string.gmatch(freqRaw, "[^\r\n]+") do
			local w = clean(line:match("^(%S+)") or line)
			if w and nounSet[w] and not used[w] then
				used[w] = true
				ordered[#ordered+1] = w
			end
		end
	end
	table.sort(allNouns, function(a, b)
		local wa = (#a >= 8 and #a <= 14) and #a or (#a + 100)
		local wb = (#b >= 8 and #b <= 14) and #b or (#b + 100)
		return wa < wb
	end)
	for _, w in ipairs(allNouns) do
		if not used[w] then
			used[w] = true
			ordered[#ordered+1] = w
		end
	end
	for _, w in ipairs(ordered) do
		local k = string.sub(w, 1, 2)
		Dict.b[k] = Dict.b[k] or {}
		table.insert(Dict.b[k], w)
		Dict.total += 1
	end
	if type(writefile) == "function" and #ordered > 1000 then
		pcall(writefile, CACHE, table.concat(ordered, "\n"))
	end
	Dict.ok = true
	getgenv().__GWDict = Dict
end
task.spawn(loadDict)

-- === ЛОГИКА ИГРЫ (БЕЗ ИЗМЕНЕНИЙ) ===
local G = { phase = "lobby", let = "", you = nil, turn = nil, tid = nil, rnd = 0, gen = 0, at = 0, ch = nil, chr = nil }
local S = { used = {}, bad = {}, req = 0, tr = 0, tKey = nil, cKey = nil, pend = nil, plan = nil, last = "-", won = 0 }

local function mark(w) local c = clean(w) if c then S.used[c] = true end end

State.OnClientEvent:Connect(function(p)
	if not alive() or type(p) ~= "table" then return end
	if p.kind == "match" then
		G.at, G.phase = os.clock(), tostring(p.phase or "lobby")
		G.let = ruLow(tostring(p.letter or p.prefix or p.letters or ""))
		G.you, G.turn, G.tid = p.you, p.turn, p.tableId
		G.rnd, G.gen = tonumber(p.round) or 0, tonumber(p.generation) or 0
		G.ch, G.chr = p.choices, p.chooser
		local mk = tostring(G.tid)..":"..tostring(G.gen)
		if G.mk ~= mk then G.mk, S.used, S.tKey, S.cKey, S.pend, S.plan = mk, {}, nil, nil, nil, nil end
		for _, w in ipairs(p.history or {}) do mark(w) end
		if p.lastWord then mark(p.lastWord) end
	elseif p.kind == "accepted" then
		local w = clean(tostring(p.word or ""))
		if w then mark(w) if S.pend and S.pend.w == w then S.won += 1 S.pend = nil end end
	elseif p.kind == "invalid" or p.kind == "wordRejected" then
		if S.pend then
			if p.reason == "used" then mark(S.pend.w) elseif S.pend.w then S.bad[S.pend.w] = true end
			S.pend = nil
		end
	elseif p.kind == "result" then
		G.phase, G.turn, S.pend, S.plan = "finished", nil, nil, nil
	end
end)

local function typeText(txt)
	if Cfg.show then
		local ui = LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild("WordGameUI")
		local box = ui and ui:FindFirstChildWhichIsA("TextBox", true)
		if box then pcall(function() box.Text = txt end) end
	end
	pcall(function() Action:FireServer("typing", txt, { tableId = G.tid, round = G.rnd, generation = G.gen }) end)
end

local function pick(pref)
	local p = ruLow(pref)
	local b = Dict.b[string.sub(p, 1, 2)]
	if p == "" or not b then return nil end
	local L, fb = #p, nil
	for _, w in ipairs(b) do
		if #w > L and string.sub(w, 1, L) == p and not S.used[w] and not S.bad[w] then
			if Cfg.safe and BAD_END[string.sub(w, -2)] then fb = fb or w else return w end
		end
	end
	return fb
end

local function submit(w)
	local l = ruLow(G.let)
	local r = rest(w, l)
	S.req += 1
	S.pend = { w = w, at = os.clock() }
	typeText(r)
	Action:FireServer("word", l .. r, { requestId = S.req, tableId = G.tid, round = G.rnd, generation = G.gen })
	S.last, S.tr = w, S.tr + 1
end

local function doTurn(key)
	local function stop() return not alive() or S.plan ~= key or G.phase ~= "playing" or G.turn ~= G.you end
	local l = G.let
	local w = pick(l)
	if not w then S.tr = Cfg.tries S.plan = nil return end
	S.used[w] = true

	local M = MODES[Cfg.mode] or MODES.legit
	local retry = S.tr > 0
	task.wait(retry and rnd(0.25, 0.45) or rnd(M.T[1], M.T[2]))
	if stop() then S.plan = nil return end

	local suf = rest(w, l)
	if not M.FAST then
		local n = uLen(suf)
		local typoIdx = (not retry and n >= 3 and math.random() < M.TYPO) and math.random(2, n) or nil
		local pauseIdx = (not retry and n >= 4 and math.random() < M.PAUSE) and math.random(2, n - 1) or nil

		for i = 1, n do
			if stop() then S.plan = nil return end
			local o1 = utf8.offset(suf, i)
			local o2 = utf8.offset(suf, i + 1)
			local pref = string.sub(suf, 1, (o1 and o1 - 1) or 0)
			local curCh = string.sub(suf, o1, (o2 and o2 - 1) or #suf)

			if typoIdx == i then
				typeText(pref .. typoChar(curCh))
				task.wait(rnd(0.18, 0.36))
				if stop() then S.plan = nil return end
				typeText(pref)
				task.wait(rnd(0.12, 0.25))
				if stop() then S.plan = nil return end
			end

			typeText(string.sub(suf, 1, (o2 and o2 - 1) or #suf))

			if pauseIdx == i then
				task.wait(rnd(0.25, 0.50))
			end

			local cMin = retry and (M.C[1] * 0.6) or M.C[1]
			local cMax = retry and (M.C[2] * 0.6) or M.C[2]
			task.wait(rnd(cMin, cMax))
		end

		if not retry and M.END[2] > 0 then
			task.wait(rnd(M.END[1], M.END[2]))
		end
	end

	if not stop() then submit(w) end
	S.plan = nil
end

Run.Heartbeat:Connect(function()
	if not (alive() and Cfg.solve and Dict.ok) or (os.clock() - G.at) > 20 then return end
	if G.phase == "choosing" and G.chr == G.you and G.ch and Cfg.choose then
		local k = tostring(G.tid)..":"..tostring(G.rnd)
		if S.cKey ~= k then
			S.cKey = k
			local c = ruLow(tostring(G.ch[1] or ""))
			task.delay(rnd(0.7, 1.4), function() if alive() and G.phase == "choosing" then Action:FireServer("choose", c) end end)
		end
		return
	end
	if G.phase ~= "playing" or G.turn ~= G.you then return end
	if S.pend then if os.clock() - S.pend.at > 1.6 then S.pend = nil end return end
	local k = table.concat({tostring(G.tid), tostring(G.rnd), tostring(G.gen)}, ":")
	if S.tKey ~= k then S.tKey, S.tr = k, 0 end
	if not S.plan and S.tr < Cfg.tries then S.plan = k task.spawn(doTurn, k) end
end)

-- === ПЛАВНЫЙ ЧЕРНО-СЕРЫЙ ИНТЕРФЕЙС (getman words) ===
local function tw(obj, t, props, style)
	TS:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local pGui = (type(gethui) == "function" and gethui()) or LP:WaitForChild("PlayerGui")
for _, n in ipairs({"MyWordBotUI", "GetmanWordsUI"}) do if pGui:FindFirstChild(n) then pGui[n]:Destroy() end end

local gui = Instance.new("ScreenGui", pGui)
gui.Name, gui.ResetOnSpawn = "GetmanWordsUI", false

local f = Instance.new("Frame", gui)
f.AnchorPoint = Vector2.new(0, 0)
f.Size, f.Position = UDim2.fromOffset(265, 278), UDim2.new(0.02, 0, 0.32, 0)
f.BackgroundColor3, f.BorderSizePixel = Color3.fromRGB(16, 16, 19), 0
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)

local fGrad = Instance.new("UIGradient", f)
fGrad.Color = ColorSequence.new(Color3.fromRGB(24, 24, 28), Color3.fromRGB(12, 12, 14))
fGrad.Rotation = 45

local fs = Instance.new("UIStroke", f)
fs.Color, fs.Thickness = Color3.fromRGB(48, 48, 54), 1

local uScale = Instance.new("UIScale", f)
uScale.Scale = 0.85
tw(uScale, 0.35, {Scale = 1}, Enum.EasingStyle.Back)

-- Шапка
local hdr = Instance.new("Frame", f)
hdr.Size, hdr.BackgroundTransparency = UDim2.new(1, 0, 0, 38), 1

local dot = Instance.new("Frame", hdr)
dot.Size, dot.Position = UDim2.fromOffset(7, 7), UDim2.fromOffset(14, 15)
dot.BackgroundColor3, dot.BorderSizePixel = Color3.fromRGB(220, 220, 230), 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

local ttl = Instance.new("TextLabel", hdr)
ttl.Size, ttl.Position, ttl.BackgroundTransparency = UDim2.new(1, -80, 1, 0), UDim2.fromOffset(28, 0), 1
ttl.Font, ttl.TextSize, ttl.TextColor3 = Enum.Font.GothamBold, 14, Color3.fromRGB(240, 240, 245)
ttl.TextXAlignment, ttl.Text = Enum.TextXAlignment.Left, "getman words"

local kBadge = Instance.new("TextLabel", hdr)
kBadge.Size, kBadge.Position = UDim2.fromOffset(28, 20), UDim2.new(1, -40, 0, 9)
kBadge.BackgroundColor3, kBadge.BorderSizePixel = Color3.fromRGB(26, 26, 30), 0
kBadge.Font, kBadge.TextSize, kBadge.TextColor3 = Enum.Font.GothamMedium, 11, Color3.fromRGB(130, 130, 140)
kBadge.Text = "K"
Instance.new("UICorner", kBadge).CornerRadius = UDim.new(0, 5)
Instance.new("UIStroke", kBadge).Color = Color3.fromRGB(44, 44, 50)

local sep = Instance.new("Frame", f)
sep.Size, sep.Position = UDim2.new(1, -24, 0, 1), UDim2.fromOffset(12, 38)
sep.BackgroundColor3, sep.BorderSizePixel = Color3.fromRGB(34, 34, 38), 0

-- Плавное перетаскивание
local drag, dIn, dStart, sPos
hdr.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		drag, dStart, sPos = true, i.Position, f.Position
		i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end)
	end
end)
hdr.InputChanged:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then dIn = i end
end)
UIS.InputChanged:Connect(function(i)
	if i == dIn and drag then
		local d = i.Position - dStart
		tw(f, 0.08, {Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + d.X, sPos.Y.Scale, sPos.Y.Offset + d.Y)})
	end
end)

-- Карточка статуса
local sBox = Instance.new("Frame", f)
sBox.Size, sBox.Position = UDim2.new(1, -24, 0, 54), UDim2.fromOffset(12, 48)
sBox.BackgroundColor3, sBox.BorderSizePixel = Color3.fromRGB(20, 20, 24), 0
Instance.new("UICorner", sBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", sBox).Color = Color3.fromRGB(36, 36, 42)

local letBox = Instance.new("TextLabel", sBox)
letBox.Size, letBox.Position = UDim2.fromOffset(48, 38), UDim2.fromOffset(8, 8)
letBox.BackgroundColor3, letBox.BorderSizePixel = Color3.fromRGB(28, 28, 34), 0
letBox.Font, letBox.TextSize, letBox.TextColor3 = Enum.Font.GothamBold, 15, Color3.fromRGB(245, 245, 250)
letBox.Text = "-"
Instance.new("UICorner", letBox).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", letBox).Color = Color3.fromRGB(50, 50, 58)

local sLbl = Instance.new("TextLabel", sBox)
sLbl.Size, sLbl.Position, sLbl.BackgroundTransparency = UDim2.new(1, -68, 1, -10), UDim2.fromOffset(64, 5), 1
sLbl.Font, sLbl.TextSize, sLbl.TextColor3 = Enum.Font.GothamMedium, 11, Color3.fromRGB(175, 175, 185)
sLbl.TextXAlignment, sLbl.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Center
sLbl.Text = "Загрузка базы..."

-- Свитч-переключатель с анимацией
local function makeToggle(y, text, def, cb)
	local row = Instance.new("TextButton", f)
	row.Size, row.Position, row.AutoButtonColor = UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, y), false
	row.BackgroundColor3, row.BorderSizePixel, row.Text = Color3.fromRGB(22, 22, 26), 0, ""
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
	local st = Instance.new("UIStroke", row) st.Color = Color3.fromRGB(36, 36, 42)

	local lbl = Instance.new("TextLabel", row)
	lbl.Size, lbl.Position, lbl.BackgroundTransparency = UDim2.new(1, -60, 1, 0), UDim2.fromOffset(12, 0), 1
	lbl.Font, lbl.TextSize, lbl.TextXAlignment = Enum.Font.GothamMedium, 12, Enum.TextXAlignment.Left
	lbl.Text = text

	local pill = Instance.new("Frame", row)
	pill.Size, pill.Position = UDim2.fromOffset(36, 18), UDim2.new(1, -46, 0.5, -9)
	pill.BorderSizePixel = 0
	Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

	local knob = Instance.new("Frame", pill)
	knob.Size, knob.BorderSizePixel = UDim2.fromOffset(14, 14), 0
	Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

	local function set(on, fast)
		local d = fast and 0.01 or 0.22
		tw(lbl, d, {TextColor3 = on and Color3.fromRGB(238, 238, 244) or Color3.fromRGB(135, 135, 145)})
		tw(pill, d, {BackgroundColor3 = on and Color3.fromRGB(215, 215, 225) or Color3.fromRGB(34, 34, 40)})
		tw(knob, d, {
			Position = on and UDim2.fromOffset(20, 2) or UDim2.fromOffset(2, 2),
			BackgroundColor3 = on and Color3.fromRGB(16, 16, 19) or Color3.fromRGB(120, 120, 130)
		})
	end
	set(def, true)
	row.MouseEnter:Connect(function() tw(row, 0.15, {BackgroundColor3 = Color3.fromRGB(27, 27, 32)}) end)
	row.MouseLeave:Connect(function() tw(row, 0.15, {BackgroundColor3 = Color3.fromRGB(22, 22, 26)}) end)
	row.MouseButton1Click:Connect(function() cb(set) end)
end

makeToggle(110, "Авто-ответ", true, function(set)
	Cfg.solve = not Cfg.solve
	set(Cfg.solve)
	tw(dot, 0.25, {BackgroundColor3 = Cfg.solve and Color3.fromRGB(220, 220, 230) or Color3.fromRGB(75, 75, 85)})
end)

makeToggle(150, "Без плохих окончаний", true, function(set)
	Cfg.safe = not Cfg.safe
	set(Cfg.safe)
end)

-- Селектор режима (3 сегмента)
local mFrame = Instance.new("Frame", f)
mFrame.Size, mFrame.Position = UDim2.new(1, -24, 0, 32), UDim2.fromOffset(12, 190)
mFrame.BackgroundColor3, mFrame.BorderSizePixel = Color3.fromRGB(20, 20, 24), 0
Instance.new("UICorner", mFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", mFrame).Color = Color3.fromRGB(36, 36, 42)

local mList = { {id="legit", txt="LEGIT"}, {id="superlegit", txt="SUPER"}, {id="rage", txt="RAGE"} }
local mBtns = {}
for idx, info in ipairs(mList) do
	local b = Instance.new("TextButton", mFrame)
	b.Size = UDim2.new(1/3, -4, 1, -6)
	b.Position = UDim2.new((idx-1)/3, idx == 1 and 3 or 2, 0, 3)
	b.AutoButtonColor, b.BorderSizePixel = false, 0
	b.Font, b.TextSize, b.Text = Enum.Font.GothamBold, 11, info.txt
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	mBtns[info.id] = b
	b.MouseButton1Click:Connect(function()
		Cfg.mode = info.id
		for k, btnObj in pairs(mBtns) do
			local active = (k == Cfg.mode)
			tw(btnObj, 0.2, {
				BackgroundColor3 = active and Color3.fromRGB(44, 44, 52) or Color3.fromRGB(20, 20, 24),
				TextColor3 = active and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(120, 120, 130)
			})
		end
	end)
end
for k, btnObj in pairs(mBtns) do
	local active = (k == Cfg.mode)
	btnObj.BackgroundColor3 = active and Color3.fromRGB(44, 44, 52) or Color3.fromRGB(20, 20, 24)
	btnObj.TextColor3 = active and Color3.fromRGB(240, 240, 245) or Color3.fromRGB(120, 120, 130)
end

-- Кнопка мгновенного ответа
local actBtn = Instance.new("TextButton", f)
actBtn.Size, actBtn.Position, actBtn.AutoButtonColor = UDim2.new(1, -24, 0, 34), UDim2.fromOffset(12, 230), false
actBtn.BackgroundColor3, actBtn.BorderSizePixel = Color3.fromRGB(32, 32, 38), 0
actBtn.Font, actBtn.TextSize, actBtn.TextColor3 = Enum.Font.GothamBold, 12, Color3.fromRGB(235, 235, 242)
actBtn.Text = "Ответить мгновенно"
Instance.new("UICorner", actBtn).CornerRadius = UDim.new(0, 8)
local actSt = Instance.new("UIStroke", actBtn) actSt.Color = Color3.fromRGB(58, 58, 66)

actBtn.MouseEnter:Connect(function() tw(actBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(42, 42, 50)}) end)
actBtn.MouseLeave:Connect(function() tw(actBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(32, 32, 38)}) end)
actBtn.MouseButton1Click:Connect(function()
	tw(actBtn, 0.08, {BackgroundColor3 = Color3.fromRGB(65, 65, 75)})
	task.delay(0.12, function() tw(actBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(32, 32, 38)}) end)
	if G.phase == "playing" and G.turn == G.you and Dict.ok then
		local w = pick(G.let)
		if w then S.used[w] = true submit(w) end
	end
end)

-- Плавное скрытие/показ окна на K
local shown = true
UIS.InputBegan:Connect(function(i, g)
	if not g and i.KeyCode == Enum.KeyCode.K then
		shown = not shown
		if shown then
			f.Visible = true
			tw(uScale, 0.28, {Scale = 1}, Enum.EasingStyle.Back)
		else
			tw(uScale, 0.18, {Scale = 0.85}, Enum.EasingStyle.Quad)
			task.delay(0.18, function() if not shown then f.Visible = false end end)
		end
	end
end)

task.spawn(function()
	Action:FireServer("sync")
	while alive() do
		letBox.Text = G.let ~= "" and ruUp(G.let) or "-"
		sLbl.Text = string.format("База: %d  |  Решено: %d\nСлово: %s", Dict.total, S.won, S.last)
		task.wait(0.2)
	end
end)
