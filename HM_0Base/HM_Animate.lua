-- @Author: Webster
-- @Date:   2016-01-21 22:01:02
-- @Last Modified by:   Webster
-- @Last Modified time: 2016-02-23 22:31:43

-- JX3UI Simple Animate Library
local ANI_QUEUE = {
	FADEIN  = setmetatable({}, { __mode = "kv" }),
	FADEOUT = setmetatable({}, { __mode = "kv" }),
	SCALE   = setmetatable({}, { __mode = "kv" }),
	POS     = setmetatable({}, { __mode = "kv" }),
}
local Animate   = {}
Animate.__index = Animate
-- constructor
function Animate:ctor(ui, nTime)
	assert(
		type(ui) == "table"
		and ui
		and ui.___id
		and type(ui.___id) == "userdata"
		and ui:IsValid()
	, "Animate:ctor error!")
	local oo = {}
	setmetatable(oo, self)
	oo.type  = ui:GetType()
	oo.name  = ui:GetName()
	oo.ui    = ui
	oo.nTime = nTime or 500
	return oo
end

function Animate:FadeIn(nTime, fnAction)
	if ANI_QUEUE.FADEIN[self.ui] then
		return self
	end
	if type(nTime) == "function" then
		fnAction, nTime = nTime, self.nTime
	else
		nTime = nTime or self.nTime
	end
	self.ui:SetAlpha(0)
	self.ui:Show()
	local nCreat = GetTime()
	local function FadeIn()
		local nNow  = GetTime()
		if self.ui and self.ui:IsValid() then
			local nLeft = nNow - nCreat
			if nLeft < nTime then
				local nAlpha = nLeft / nTime * 255
				return self.ui:SetAlpha(nAlpha)
			end
			self.ui:SetAlpha(255)
		end
		ANI_QUEUE.FADEIN[self.ui] = nil
		if fnAction then
			local res, err = pcall(fnAction)
		end
		return UnRegisterEvent("RENDER_FRAME_UPDATE", FadeIn)
	end
	ANI_QUEUE.FADEIN[self.ui] = FadeIn
	RegisterEvent("RENDER_FRAME_UPDATE", FadeIn)
	return self
end

function Animate:FadeOut(nTime, bShow, fnAction)
	if ANI_QUEUE.FADEOUT[self.ui] then
		return self
	end
	if type(nTime) == "function" then
		fnAction, nTime, bShow = nTime, self.nTime, false
	elseif type(nTime) == "boolean" then
		if type(bShow) == "function" then
			fnAction, bShow, nTime = bShow, nTime, self.nTime
		else
			fnAction, bShow, nTime = nil, nTime, self.nTime
		end
	else
		nTime = nTime or self.nTime
		if type(bShow) == "function" then
			fnAction, bShow = bShow, false
		end
	end
	local nSAlpha = self.ui:GetAlpha()
	if nSAlpha == 0 then
		nSAlpha = 255
		self.ui:SetAlpha(255)
	end
	self.ui:Show()
	local nCreat = GetTime()
	local function FadeOut()
		local nNow = GetTime()
		if self.ui and self.ui:IsValid() then
			local nLeft = nNow - nCreat
			if nLeft < nTime then
				local nAlpha = nSAlpha - nLeft / nTime * nSAlpha
				return self.ui:SetAlpha(nAlpha)
			end
			if bShow then
				self.ui:SetAlpha(0)
			else
				self.ui:Hide()
				self.ui:SetAlpha(nSAlpha)
			end
		end
		ANI_QUEUE.FADEOUT[self.ui] = nil
		if fnAction then
			local res, err = pcall(fnAction)
		end
		return UnRegisterEvent("RENDER_FRAME_UPDATE", FadeOut)
	end
	ANI_QUEUE.FADEOUT[self.ui] = FadeOut
	RegisterEvent("RENDER_FRAME_UPDATE", FadeOut)
	return self
end

function Animate:Scale(fScale, nTime, bNormal, fnAction)
	if ANI_QUEUE.SCALE[self.ui] then
		return self
	end
	if type(nTime) == "function" then
		fnAction, nTime, bNormal = nTime, self.nTime, false
	elseif type(nTime) == "boolean" then
		if type(bNormal) == "function" then
			fnAction, bNormal, nTime = bNormal, nTime, self.nTime
		else
			fnAction, bNormal, nTime = nil, nTime, self.nTime
		end
	else
		nTime = nTime or self.nTime
		if type(bNormal) == "function" then
			fnAction, bNormal = bNormal, false
		end
	end
	local bPoint = self.type == "WndFrame"
	local a = bPoint and GetFrameAnchor(self.ui)
	local fForm = 1
	if bNormal then
		fForm = fScale
		fScale = 1
	else
		self.ui:Scale(fScale, fScale)
	end
	local bLarge = fScale < fForm
	local fStep = (bLarge and fForm - fScale or fScale - fForm) / nTime
	local nCreat = GetTime()
	local fScaleNow = fScale
	local function Scale()
		local nNow  = GetTime()
		if self.ui and self.ui:IsValid() then
			local nLeft = nNow - nCreat
			if nLeft < nTime then
				local fCurrent = bLarge and fScale + nLeft * fStep or fScale - nLeft * fStep
				local fScale = fCurrent / fScaleNow
				fScaleNow = fCurrent
				self.ui:Scale(fScale, fScale)
				if bPoint then
					self.ui:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
				end
				return
			end
			-- expect
			if fScaleNow ~= 1 then
				local fScale = 1 / fScaleNow
				self.ui:Scale(fScale, fScale)
				if bPoint then
					self.ui:SetPoint(a.s, 0, 0, a.r, a.x, a.y)
				end
			end
		end
		ANI_QUEUE.SCALE[self.ui] = nil
		if fnAction then
			local res, err = pcall(fnAction)
		end
		return UnRegisterEvent("RENDER_FRAME_UPDATE", Scale)
	end
	ANI_QUEUE.SCALE[self.ui] = Scale
	RegisterEvent("RENDER_FRAME_UPDATE", Scale)
	return self
end

function Animate:Pos(tPos, nTime, bMove, fnAction)
	if ANI_QUEUE.POS[self.ui] then
		return self
	end
	local hParent
	if self.type:sub(1, 3) ~= "Wnd" then
		hParent = self.ui:GetParent()
		if hParent:GetType() ~= "Handle" and hParent:GetType() ~= "TreeLeaf" then
			return self
		end
	end

	if type(nTime) == "function" then
		fnAction, nTime, bMove = nTime, self.nTime, false
	elseif type(nTime) == "boolean" then
		if type(bMove) == "function" then
			fnAction, bMove, nTime = bMove, nTime, self.nTime
		else
			fnAction, bMove, nTime = nil, nTime, self.nTime
		end
	else
		nTime = nTime or self.nTime
		if type(bMove) == "function" then
			fnAction, bMove = bMove, false
		end
	end

	local nEX, nEY = self.ui:GetRelPos()
	local x, y = unpack(tPos)
	local nSX, nSY = nEX + x, nEY + y
	if bMove then
		nSX, nSY, nEX, nEY = nEX, nEY, nSX, nSY
	end
	local nX, nY = nEX - nSX, nEY - nSY
	self.ui:SetRelPos(nSX, nSY)
	if hParent then hParent:FormatAllItemPos() end
	local nCreat = GetTime()
	local function Animate()
		local nNow  = GetTime()
		if self.ui and self.ui:IsValid() then
			local nLeft = nNow - nCreat
			if nLeft < nTime then
				local nX, nY = nLeft / nTime * nX, nLeft / nTime * nY
				self.ui:SetRelPos(nSX + nX, nSY + nY)
				if hParent then hParent:FormatAllItemPos() end
				return
			end
			self.ui:SetRelPos(nEX, nEY)
			if hParent then hParent:FormatAllItemPos() end
		end
		ANI_QUEUE.POS[self.ui] = nil
		if fnAction then
			local res, err = pcall(fnAction)
		end
		return UnRegisterEvent("RENDER_FRAME_UPDATE", Animate)
	end
	ANI_QUEUE.POS[self.ui] = Animate
	RegisterEvent("RENDER_FRAME_UPDATE", Animate)
	return self
end

HM.Animate = setmetatable({}, { __call = function(me, ...) return Animate:ctor( ... ) end, __newindex = function() end, __metatable = true })
