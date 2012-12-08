--
-- 海鳗插件：目标面向显示（画扇形）
--

HM_TargetFace = {
	bEnable = false,				-- 是否画出目标面向
	nDegree = 90,					-- 扇形角度
	nRadius = 4,						-- 半径（尺）
	nAlpha = 35,						-- 不透透明度
	tColor = { 255, 0, 128 },		-- 颜色
}

for k, _ in pairs(HM_TargetFace) do
	RegisterCustomData("HM_TargetFace." .. k)
end

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_TargetFace = {}

-------------------------------------
-- 事件处理
-------------------------------------
-- update target
_HM_TargetFace.OnUpdateTarget = function()
	local sha = _HM_TargetFace.shadow
	if HM_TargetFace.bEnable and sha then
	    if HM.GetTarget() then
			sha:Show()
		else
			sha:Hide()
		end
	end
end

-- render interval
_HM_TargetFace.OnUpdateRender = function()
	local sha = _HM_TargetFace.shadow
	if not HM_TargetFace.bEnable or not sha or not sha:IsVisible() then
		return
	end
	local tar = HM.GetTarget()
	if not tar then
		return sha:Hide()
	end
	sha:SetTriangleFan(true)
	sha:ClearTriangleFanPoint()
	-- orgina point
	local nX, nY = HM.GetScreenPoint(tar.nX, tar.nY, tar.nZ)
	if not nX then return end
	local col, nRadius = HM_TargetFace.tColor, HM_TargetFace.nRadius * 64
	local nAlpha = 2 * (100 - HM_TargetFace.nAlpha)
	local nFace = math.ceil(128 * HM_TargetFace.nDegree / 360)
	local dwRad1 = math.pi * (tar.nFaceDirection - nFace) / 128
	if tar.nFaceDirection > (256 - nFace) then
		dwRad1 = dwRad1 - math.pi - math.pi
	end
	local dwRad2 = dwRad1 + (HM_TargetFace.nDegree / 180 * math.pi)
	sha:AppendTriangleFanPoint(nX, nY, col[1], col[2], col[3], nAlpha)
	-- points
	repeat
		nX, nY = HM.GetScreenPoint(tar.nX + math.cos(dwRad1) * nRadius, tar.nY + math.sin(dwRad1) * nRadius, tar.nZ)
		if nX then
			sha:AppendTriangleFanPoint(nX, nY, col[1], col[2], col[3], 0)
		end
		dwRad1 = dwRad1 + math.pi / 16
	until dwRad1 > dwRad2
end

---------------------------------------------------------------------
-- 设置界面
---------------------------------------------------------------------
_HM_TargetFace.PS = {}

-- init panel
_HM_TargetFace.PS.OnPanelActive = function(frame)
	local ui = HM.UI(frame)
	ui:Append("Text", { txt = _L["Options"], font = 27 })
	local nX = ui:Append("WndCheckBox", { txt = _L["Display the sector of target facing, change color"], checked = HM_TargetFace.bEnable })
	:Pos(10, 28):Enable(_HM_TargetFace.shadow ~= nil):Click(function(bChecked)
		HM_TargetFace.bEnable = bChecked
		if not bChecked then
			_HM_TargetFace.shadow:Hide()
		else
			_HM_TargetFace.shadow:Show()
		end
	end):Pos_()
	ui:Append("Shadow", "Shadow_Color", { x = nX + 2, y = 32, w = 18, h = 18 })
	:Color(unpack(HM_TargetFace.tColor)):Click(function()
		OpenColorTablePanel(function(r, g, b)
			ui:Fetch("Shadow_Color"):Color(r, g, b)
			HM_TargetFace.tColor = { r, g, b }
		end)
	end)
	nX = ui:Append("Text", { txt = _L["The sector angle"], x = 10, y = 56 }):Pos_()
	ui:Append("WndTrackBar", "Track_Angle", { x = nX, y = 60, txt = _L[" degree"] })
	:Range(30, 180, 30):Value(HM_TargetFace.nDegree):Change(function(nVal) HM_TargetFace.nDegree = nVal end)
	nX = ui:Append("Text", { txt = _L["The sector radius"], x = 10, y = 84 }):Pos_()
	ui:Append("WndTrackBar", "Track_Radius", { x = nX, y = 88, txt = _L[" feet"] })
	:Range(2, 27, 25):Value(HM_TargetFace.nRadius):Change(function(nVal) HM_TargetFace.nRadius = nVal end)
	nX = ui:Append("Text", { txt = _L["The sector transparency"], x = 10, y = 112 }):Pos_()
	ui:Append("WndTrackBar", "Track_Alpha", { x = nX, y = 116 })
	:Range(0, 100, 100):Value(HM_TargetFace.nAlpha):Change(function(nVal) HM_TargetFace.nAlpha = nVal end)
end

-- check conflict
_HM_TargetFace.PS.OnConflictCheck = function()
	-- init shadow
	local frame = Station.Lookup("Lowest/HM_Area") or Wnd.OpenWindow("interface\\HM\\ui\\HM_Area.ini")
	if frame then
		_HM_TargetFace.shadow = frame:Lookup("", "Shadow_Base")
	end
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("UPDATE_SELECT_TARGET", _HM_TargetFace.OnUpdateTarget)
HM.RegisterEvent("RENDER_FRAME_UPDATE", _HM_TargetFace.OnUpdateRender)

-- add to HM panel
HM.RegisterPanel(_L["Target face"], 2136, _L["Target"], _HM_TargetFace.PS)

