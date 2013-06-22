--
-- 海鳗插件：目标面向显示（画扇形）
--

HM_TargetFace = {
	bTargetFace = true,			-- 是否画出目标面向
	bFocusFace = false,			-- 是否画出焦点的面向
	nSectorDegree = 90,			-- 扇形角度
	nSectorRadius = 6,				-- 扇形半径（尺）
	nSectorAlpha = 40,				-- 扇形透明度
	tTargetFaceColor = { 255, 0, 128 },		-- 目标面向颜色
	tFocusFaceColor = { 0, 128, 255 },		-- 焦点面向颜色
	bTargetShape = false,		-- 目标脚底圈圈
	bFocusShape = true,			-- 焦点脚底圈圈
	nShapeRadius = 2,				-- 脚底圈圈半径
	nShapeAlpha = 60,				-- 脚底圈圈透明度
	tTargetShapeColor = { 255, 0, 0 },
	tFocusShapeColor = { 0, 0, 255 },
}
HM.RegisterCustomData("HM_TargetFace")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_TargetFace = {
	szIniFile = "interface\\HM\\ui\\HM_TargetFace.ini",
}

-- draw shape
_HM_TargetFace.DrawShape = function(tar, sha, nDegree, nRadius, nAlpha, col)
	nRadius = nRadius * 64
	local nFace = math.ceil(128 * nDegree / 360)
	local dwRad1 = math.pi * (tar.nFaceDirection - nFace) / 128
	if tar.nFaceDirection > (256 - nFace) then
		dwRad1 = dwRad1 - math.pi - math.pi
	end
	local dwRad2 = dwRad1 + (nDegree / 180 * math.pi)
	local nAlpha2 = 0
	if nDegree == 360 then
		nAlpha, nAlpha2 = nAlpha2, nAlpha
		dwRad2 = dwRad2 + math.pi / 16
	end
	-- orgina point
	HM.ApplyScreenPoint(function(nX, nY)
		if not nX then
			return sha:Hide()
		end
		sha:ClearTriangleFanPoint()
		sha:AppendTriangleFanPoint(nX, nY, col[1], col[2], col[3], nAlpha)
		-- points
		repeat
			HM.ApplyScreenPoint(function(nX, nY)
				if nX then
					sha:AppendTriangleFanPoint(nX, nY, col[1], col[2], col[3], nAlpha2)
				end
			end, tar.nX + math.cos(dwRad1) * nRadius, tar.nY + math.sin(dwRad1) * nRadius, tar.nZ)
			dwRad1 = dwRad1 + math.pi / 16
		until dwRad1 > dwRad2
		sha:Show()
	end, tar.nX, tar.nY, tar.nZ)
end

-------------------------------------
-- 事件处理
-------------------------------------
-- update target
_HM_TargetFace.OnUpdateTarget = function()
	local _, dwID = GetClientPlayer().GetTarget()
	_HM_TargetFace.bTargetActive = dwID ~= 0
end

-- render interval
_HM_TargetFace.OnRender = function()
	local _t, t, tar = _HM_TargetFace, HM_TargetFace, nil
	-- target face
	if not _t.bTargetActive then
		_t.hTargetFace:Hide()
		_t.hTargetShape:Hide()
	else
		tar = HM.GetTarget()
		if not tar then
			_t.bTargetActive = false
		else
			if HM_TargetFace.bTargetFace then
				_t.DrawShape(tar, _t.hTargetFace, t.nSectorDegree, t.nSectorRadius, t.nSectorAlpha, t.tTargetFaceColor)
			else
				_t.hTargetFace:Hide()
			end
			if HM_TargetFace.bTargetShape then
				_t.DrawShape(tar, _t.hTargetShape, 360, t.nShapeRadius, t.nShapeAlpha, t.tTargetShapeColor)
			else
				_t.hTargetShape:Hide()
			end
		end
	end
	-- focus
	if not _t.bFocusActive then
		_t.hFocusFace:Hide()
		_t.hFocusShape:Hide()
	else
		local bIsTarget = tar and _t.dwFocusID == tar.dwID
		tar = HM.GetTarget(_t.dwFocusID)
		if not tar then
			_t.bFocusActive = false
		else
			if HM_TargetFace.bFocusFace and (not HM_TargetFace.bTargetFace or not bIsTarget) then
				_t.DrawShape(tar, _t.hFocusFace, t.nSectorDegree, t.nSectorRadius, t.nSectorAlpha, t.tFocusFaceColor)
			else
				_t.hFocusFace:Hide()
			end
			if HM_TargetFace.bFocusShape and (not HM_TargetFace.bTargetShape or not bIsTarget) then
				_t.DrawShape(tar, _t.hFocusShape, 360, t.nShapeRadius, t.nShapeAlpha, t.tFocusShapeColor)
			else
				_t.hFocusShape:Hide()
			end
		end
	end
end

-------------------------------------
-- 窗口函数
-------------------------------------
-- create
function HM_TargetFace.OnFrameCreate()
	-- shadows
	for _, v in ipairs({ "TargetFace", "TargetShape", "FocusFace", "FocusShape" }) do
		local sha = this:Lookup("", "Shadow_" .. v)
		sha:SetTriangleFan(true)
		_HM_TargetFace["h" .. v]  = sha
	end
	-- events
	this:RegisterEvent("UPDATE_SELECT_TARGET")
	this:RegisterEvent("RENDER_FRAME_UPDATE")
	this:RegisterEvent("NPC_ENTER_SCENE")
	this:RegisterEvent("PLAYER_ENTER_SCENE")
	this:RegisterEvent("HM_ADD_FOCUS_TARGET")
	this:RegisterEvent("HM_DEL_FOCUS_TARGET")
end

-- event
function HM_TargetFace.OnEvent(event)
	if event == "RENDER_FRAME_UPDATE" then
		_HM_TargetFace.OnRender()
	elseif event == "UPDATE_SELECT_TARGET" then
		_HM_TargetFace.OnUpdateTarget()
	elseif event == "HM_ADD_FOCUS_TARGET" then
		_HM_TargetFace.dwFocusID = arg0
		_HM_TargetFace.bFocusActive = true
	elseif event == "HM_DEL_FOCUS_TARGET" and arg0 == _HM_TargetFace.dwFocusID then
		_HM_TargetFace.dwFocusID = 0
		_HM_TargetFace.bFocusActive = false
	elseif event == "NPC_ENTER_SCENE" or event == "PLAYER_ENTER_SCENE" then
		if arg0 == _HM_TargetFace.dwFocusID then
			_HM_TargetFace.bFocusActive = true
		end
	end
end

-------------------------------------
-- 设置界面
-------------------------------------
_HM_TargetFace.PS = {}

-- init panel
_HM_TargetFace.PS.OnPanelActive = function(frame)
	local ui, t, _t = HM.UI(frame), HM_TargetFace, _HM_TargetFace
	ui:Append("Text", { txt = _L["Options"], font = 27 })
	-- face
	local nX = ui:Append("WndCheckBox", { txt = _L["Display the sector of target facing, change color"], checked = t.bTargetFace })
	:Pos(10, 28):Click(function(bChecked)
		t.bTargetFace = bChecked
	end):Pos_()
	ui:Append("Shadow", "Color_TargetFace", { x = nX + 2, y = 32, w = 18, h = 18 })
	:Color(unpack(t.tTargetFaceColor)):Click(function()
		OpenColorTablePanel(function(r, g, b)
			ui:Fetch("Color_TargetFace"):Color(r, g, b)
			t.tTargetFaceColor = { r, g, b }
		end)
	end)
	nX = ui:Append("WndCheckBox", { txt = _L["Display the sector of focus facing, change color"], checked = t.bFocusFace })
	:Pos(10, 56):Enable(HM_TargetList ~= nil):Click(function(bChecked)
		t.bFocusFace = bChecked
	end):Pos_()
	ui:Append("Shadow", "Color_FocusFace", { x = nX + 2, y = 60, w = 18, h = 18 })
	:Color(unpack(t.tFocusFaceColor)):Click(function()
		OpenColorTablePanel(function(r, g, b)
			ui:Fetch("Color_FocusFace"):Color(r, g, b)
			t.tFocusFaceColor = { r, g, b }
		end)
	end)
	nX = ui:Append("Text", { txt = _L["The sector angle"], x = 37, y = 84}):Pos_()
	ui:Append("WndTrackBar", { x = nX, y = 88, txt = _L[" degree"] })
	:Range(30, 180, 30):Value(t.nSectorDegree):Change(function(nVal) t.nSectorDegree = nVal end)
	nX = ui:Append("Text", { txt = _L["The sector radius"], x = 37, y = 112 }):Pos_()
	ui:Append("WndTrackBar", { x = nX, y = 116, txt = _L[" feet"] })
	:Range(1, 26, 25):Value(t.nSectorRadius):Change(function(nVal) t.nSectorRadius = nVal end)
	nX = ui:Append("Text", { txt = _L["The sector transparency"], x = 37, y = 140 }):Pos_()
	ui:Append("WndTrackBar", { x = nX, y = 144 })
	:Range(0, 200, 100):Value(t.nSectorAlpha):Change(function(nVal) t.nSectorAlpha = nVal end)
	-- foot shape
	nX = ui:Append("WndCheckBox", { txt = _L["Display the foot shape of target, change color"], checked = t.bTargetShape })
	:Pos(10, 168):Click(function(bChecked)
		t.bTargetShape = bChecked
	end):Pos_()
	ui:Append("Shadow", "Color_TargetShape", { x = nX + 2, y = 172, w = 18, h = 18 })
	:Color(unpack(t.tTargetShapeColor)):Click(function()
		OpenColorTablePanel(function(r, g, b)
			ui:Fetch("Color_TargetShape"):Color(r, g, b)
			t.tTargetShapeColor = { r, g, b }
		end)
	end)
	nX = ui:Append("WndCheckBox", { txt = _L["Display the foot shape of focus, change color"], checked = t.bFocusShape })
	:Pos(10, 196):Enable(HM_TargetList ~= nil):Click(function(bChecked)
		t.bFocusShape = bChecked
	end):Pos_()
	ui:Append("Shadow", "Color_FocusShape", { x = nX + 2, y = 200, w = 18, h = 18 })
	:Color(unpack(t.tFocusShapeColor)):Click(function()
		OpenColorTablePanel(function(r, g, b)
			ui:Fetch("Color_FocusShape"):Color(r, g, b)
			t.tFocusShapeColor = { r, g, b }
		end)
	end)
	nX = ui:Append("Text", { txt = _L["The foot shape radius"], x = 37, y = 228 }):Pos_()
	ui:Append("WndTrackBar", { x = nX, y = 232, txt = _L[" feet"] })
	:Range(1, 26, 25):Value(t.nShapeRadius):Change(function(nVal) t.nShapeRadius = nVal end)
	nX = ui:Append("Text", { txt = _L["The foot shape transparency"], x = 37, y = 256 }):Pos_()
	ui:Append("WndTrackBar", { x = nX, y = 260 })
	:Range(0, 200, 100):Value(t.nShapeAlpha):Change(function(nVal) t.nShapeAlpha = nVal end)
	-- tips
	ui:Append("Text", { x = 0, y = 284, txt = _L["Tips"], font = 27 })
	ui:Append("Text", { x = 10, y = 312, txt = _L["Only show the facing and foot shape of the last added focus target"] })
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
-- add to HM panel
HM.RegisterPanel(_L["Target face"], 2136, _L["Target"], _HM_TargetFace.PS)

-- open hidden window
local frame = Station.Lookup("Lowest/HM_TargetFace")
if frame then Wnd.CloseWindow(frame) end
Wnd.OpenWindow(_HM_TargetFace.szIniFile, "HM_TargetFace")
