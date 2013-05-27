--
-- 海鳗插件：字体列表查看
--

HM_FontList = {}

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_FontList = {
	nCur = 0,
	nMax = 255,
}

---------------------------------------------------------------------
-- 设置界面
---------------------------------------------------------------------
-- init panel
_HM_FontList.OnPanelActive = function(frame)
	local ui = HM.UI(frame)
	local txts = {}
	ui:Append("Text", { txt = "系统字体大全", x = 0, y = 0, font = 27 })
	for i = 1, 40 do
		local x = ((i - 1) % 8) * 62
		local y = math.floor((i - 1) / 8) * 55 + 30
		txts[i] = ui:Append("Text", { w = 62, h = 30, x = x, y = y, align = 1 })
	end
	local btn1 = ui:Append("WndButton", { txt = "上一页", x = 0, y = 320 })
	local nX, _ = btn1:Pos_()
	local btn2 = ui:Append("WndButton", { txt = "下一页", x = nX, y = 320 })
	btn1:Click(function()
		_HM_FontList.nCur = _HM_FontList.nCur - #txts
		if _HM_FontList.nCur <= 0 then
			_HM_FontList.nCur = 0
			btn1:Enable(false)
		end
		btn2:Enable(true)
		for k, v in ipairs(txts) do
			local i = _HM_FontList.nCur + k - 1
			if i > _HM_FontList.nMax then
				txts[k]:Text("")
			else
				txts[k]:Text("字体" .. i)
				txts[k]:Font(i)
			end
		end
	end):Click()
	btn2:Click(function()
		_HM_FontList.nCur = _HM_FontList.nCur + #txts
		if (_HM_FontList.nCur + #txts) >= _HM_FontList.nMax then
			btn2:Enable(false)
		end
		btn1:Enable(true)
		for k, v in ipairs(txts) do
			local i = _HM_FontList.nCur + k - 1
			if i > _HM_FontList.nMax then
				txts[k]:Text("")
			else
				txts[k]:Text("字体" .. i)
				txts[k]:Font(i)
			end
		end
	end)
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
-- add to HM panel
HM.RegisterPanel("系统字体大全", 1925, "开发", _HM_FontList)
