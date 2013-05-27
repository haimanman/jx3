--
-- 海鳗插件：图标列表查看
--

HM_IconList = {}

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_IconList = {
	nCur = 0,
	nMax = 3481,
}

---------------------------------------------------------------------
-- 设置界面
---------------------------------------------------------------------
-- init panel
_HM_IconList.OnPanelActive = function(frame)
	local ui = HM.UI(frame)
	local imgs, txts = {}, {}
	ui:Append("Text", { txt = "系统图标大全", x = 0, y = 0, font = 27 })
	for i = 1, 40 do
		local x = ((i - 1) % 10) * 50
		local y = math.floor((i - 1) / 10) * 70 + 40
		imgs[i] = ui:Append("Image", { w = 48, h = 48, x = x, y = y})
		txts[i] = ui:Append("Text", { w = 48, h = 20, x = x, y = y + 48, align = 1 })
	end
	local btn1 = ui:Append("WndButton", { txt = "上一页", x = 0, y = 320 })
	local nX, _ = btn1:Pos_()
	local btn2 = ui:Append("WndButton", { txt = "下一页", x = nX, y = 320 })
	btn1:Click(function()
		_HM_IconList.nCur = _HM_IconList.nCur - #imgs
		if _HM_IconList.nCur <= 0 then
			_HM_IconList.nCur = 0
			btn1:Enable(false)
		end
		btn2:Enable(true)
		for k, v in ipairs(imgs) do
			local i = _HM_IconList.nCur + k - 1
			if i > _HM_IconList.nMax then
				break
			end
			imgs[k]:Icon(i)
			txts[k]:Text(tostring(i))
		end
	end):Click()
	btn2:Click(function()
		_HM_IconList.nCur = _HM_IconList.nCur + #imgs
		if (_HM_IconList.nCur + #imgs) >= _HM_IconList.nMax then
			btn2:Enable(false)
		end
		btn1:Enable(true)
		for k, v in ipairs(imgs) do
			local i = _HM_IconList.nCur + k - 1
			if i > _HM_IconList.nMax then
				break
			end
			imgs[k]:Icon(i)
			txts[k]:Text(tostring(i))
		end
	end)
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
-- add to HM panel
HM.RegisterPanel("系统图标大全", 591, "开发", _HM_IconList)
HM.bDevelopper = true
