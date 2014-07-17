--
-- 海鳗插件：特殊BUFF、技能 CD 监控
--

HM_TargetMon = {
	bSkillMon = true,		-- 目标技能 CD 监控
	bSkillRight = false,		-- 技能排列右对齐
	bTargetBuffEx = true,	-- 目标特殊BUFF
	bTargetRight = false,	-- 目标 BUFF 右对齐
	bSelfBuffEx = true,		-- 自身特殊BUFF
	bSelfRight = false,		-- 自身BUFF 右对齐
	bBoxEvent2 = false,		-- 图标鼠标事件
	nSize = 55,					-- BOX 大小
	tNSBuffEx = {},			-- 排除监控自己
	tNTBuffEx = {},			-- 排除监控目标
	tAnchor = {},				-- 位置
}

-- get skill name by id
local function _s(dwSkillID)
	local szName, _ = HM.GetSkillName(dwSkillID)
	return szName
end

-- get buff name by id
local function _b(dwBuffID, dwLevel)
	local szName, _ = HM.GetBuffName(dwBuffID, dwLevel)
	return szName
end

-- skill list (by force, < 0 disable )
HM_TargetMon.tSkillList4 = {
	{		-- 少林
		[_s(236)--[[摩诃无量]]] = 25,
		[_s(242)--[[捉影式]]] = 17,
		[_s(240)--[[抢珠式]]] = 30,
		[_s(249)--[[五蕴皆空]]] = 14,
		[_s(257)--[[锻骨诀]]] = 45,
		[_s(261)--[[无相诀]]] = 90,
	},  {	-- 万花
		[_s(100)--[[星楼月影]]] = 24,
		[_s(132)--[[春泥护花]]] = 36,
		[_s(186)--[[芙蓉并蒂]]] = 25,
		[_s(183)--[[厥阴指]]] = 10,
		[_s(2663)--[[听风吹雪]]] = 120,
		[_s(136)--[[水月无间]]] = 60,
	}, {	-- 天策
		[_s(412)--[[疾如风]]] = 60,
		[_s(413)--[[守如山]]] = 110,
		[_s(482)--[[崩]]] = 15,
		[_s(418)--[[突]]] = 17,
		[_s(422)--[[啸如虎]]] = 90,
		[_s(428)--[[断魂刺]]] = 23,
		[_s(433)--[[任驰骋]]] = 40,
	}, {	-- 纯阳
		[_s(588)--[[人剑合一]]] = 14,
		[_s(310)--[[剑飞惊天]]] = 20,
		[_s(366)--[[大道无术]]] = 20,
		[_s(370)--[[八卦洞玄]]] = 25,
		[_s(372)--[[转乾坤]]] = 120,
		[_s(371)--[[镇山河]]] = 240,
		[_s(307)--[[剑冲阴阳]]] = 30,
		[_s(358)--[[生太极]]] = 10,
	},  {	-- 七秀
		[_s(544)--[[帝骖龙翔]]] = 40,
		[_s(550)--[[鹊踏枝]]] = 60,
		[_s(574)--[[蝶弄足]]] = 90,
		[_s(557)--[[天地低昂]]] = 90,
		[_s(552)--[[邻里曲]]] = 400,
		[_s(569)--[[王母挥袂]]] = 15,
		[_s(555)--[[风袖低昂]]] = 45,
		[_s(558)--[[雷霆震怒]]] = 90,
		[_s(568)--[[繁音急节]]] = 120,
	},  {	-- 五毒
		[_s(2226)--[[蛊虫献祭]]] = 27,
		[_s(2230)--[[女娲补天]]] = 54,
		[_s(2227)--[[蛊虫狂暴]]] = 120,
		[_L["Call pet"]] = 30,
	},  {	-- 唐门
		[_s(3114)--[[惊鸿游龙]]] = 70,
		[_s(3090)--[[迷神钉]]] = 20,
		[_s(3089)--[[雷震子]]] = 25,
		[_s(3094)--[[心无旁骛]]] = 120,
		[_s(3112)--[[浮光掠影]]] = 90,
		[_s(3103)--[[飞星遁影]]] = 45,
		[_s(3101)--[[逐星箭]]] = 15,
	},  {	-- 藏剑
		[_s(1656)--[[啸日]]] = 10.5,
		[_s(1649)--[[醉月]]] = 14,
		[_s(1589)--[[梦泉虎跑]]] = 28,
		[_s(1596)--[[鹤归孤山]]] = 20,
		[_s(1613)--[[峰插云景]]] = 15,
	},  {	-- 丐帮
		[_s(5265)--[[见龙在田]]] = 23,
		[_s(5262)--[[龙跃于渊]]] = 9,
		[_s(5259)--[[棒打狗头]]] = 20,
		[_s(5267)--[[龙啸九天]]] = 36,
		[_s(5269)--[[烟雨行]]] = 40,
		[_s(5270)--[[笑醉狂]]] = 120,
		[_s(5272)--[[醉逍遥]]] = 60,
	},  {	-- 明教
		[_s(3977)--[[流光囚影]]] = 20,
		[_s(3975)--[[怖畏暗刑]]] = 28,
		[_s(3973)--[[贪魔体]]] = 45,
		[_s(3974)--[[暗尘弥散]]] = 45,
		[_s(3978)--[[生灭予夺]]] = 120,
		[_s(4910)--[[无明魂锁]]] = 25,
		[_s(3969)--[[光明相]]] = 90,
		[_s(3968)--[[如意法]]] = 60,
		[_s(3971)--[[极乐引]]] = 45,
	},  {	-- 其它
	}
}

--buff list (by type)
HM_TargetMon.tBuffList4 = {
	{
		szType = _L["Invincible"],	-- 1
		tName = {
			_b(377)--[[镇山河]], _b(961)--[[太虚]], _b(772)--[[回神]], _b(3425)--[[鬼斧神工]], _b(360)--[[御]],
			_b(6182)--[[冥泽]]
		},
	}, {
		szType = _L["Silence"],	-- 2
		tName = {
			_b(726)--[[剑飞惊天]], _b(692)--[[沉默]], _b(712)--[[兰摧玉折]],	-- 兰摧玉折2：712
			_b(4053)--[[怖畏暗刑]]
		},
	}, {
		szType = _L["Uncontrollable"],	--3
		tName = {
			_b(411)--[[星楼月影]], _b(1186)--[[折骨]], _b(2847)--[[素衿]], _b(855)--[[力拔]],
			_b(2756)--[[纵轻骑]], _b(2781)--[[转乾坤]], _b(3279)--[[生死之交]], _b(1856)--[[不工]], _b(1676)--[[玉泉鱼跃]], -- 转乾坤2：2781
			_b(1686)--[[梦泉虎跑]], _b(2840)--[[蛊虫狂暴]], _b(2544)--[[风蜈献祭]], _b(3822)--[[碧蝶献祭]], _b(4245)--[[圣体]],
			_b(4421)--[[灵辉]], _b(4468)--[[超然]], _b(6373)--[[出渊]], _b(6361)--[[飞将]], _b(6314)--[[零落]], _b(6292)--[[吞日月]],
			_b(6247)--[[迷心蛊]], _b(6192)--[[菩提身]], _b(6131)--[[青阳]], _b(5995)--[[笑醉狂]], _b(6459)--[[烟雨行]],
			_b(6015)--[[龙跃于渊]], _b(6369)--[[酒中仙]], _b(6087)--[[流火飞星]], _b(5754)--[[霸体]], _b(5950)--[[蛊虫献祭]],
		},
	}, {
		szType = _L["Halt"],	-- 4
		tName = {
			_b(415)--[[眩晕]], _b(533)--[[致盲]], _b(567)--[[五蕴皆空]], _b(572)--[[大狮子吼]], _b(682)--[[雷霆震怒]],
			_b(548)--[[突]], _b(2275)--[[断魂刺]], _b(740)--[[中注]], _b(1721)--[[醉月]], _b(1904)--[[鹤归孤山]], _b(1927)--[[碧王]],
			_b(2489)--[[蝎心迷心]], _b(2780)--[[剑冲阴阳]], _b(3223)--[[雷震子]], _b(3224)--[[迷神钉]], _b(727)--[[崩]],
			_b(1938)--[[峰插云景]], _b(4029)--[[日劫]], _b(4871)--[[无明魂锁]], _b(4875)--[[镇魔]], _b(6276)--[[幻光步]],
			_b(6128)--[[虎贲]], _b(6107)--[[弩击]], _b(5876)--[[善护]], _b(6365)--[[净世破魔击]], _b(6380)--[[醉逍遥]]
		},
	}, {
		szType = _L["Entrap"],	-- 5
		tName = {
			_b(1937)--[[三才化生]], _b(679)--[[影痕]], _b(706)--[[止水]], _b(4038)--[[锁足]], _b(2289)--[[五方行尽]],
			_b(2492)--[[百足迷心]], _b(2547)--[[天蛛献祭]], _b(1931)--[[吐故纳新]], _b(6364)--[[滞]],
			_b(5809)--[[太乙]], _b(5764)--[[百足]], _b(5694)--[[太阴指]], _b(5793)--[[碎冰]]
		},
	}, {
		szType = _L["Freeze"],	-- 6
		tName = {
			-- 大道无术可能改为：6082
			-- _b(998)--[[太阴指]],
			_b(678)--[[傍花随柳]], _b(686)--[[帝骖龙翔]], _b(554)--[[大道无术]], _b(556)--[[七星拱瑞]], _b(675)--[[芙蓉并蒂]],
			_b(737)--[[完骨]], _b(1229)--[[破势]], _b(1247)--[[同归]], _b(4451)--[[定身]], _b(1857)--[[松涛]],
			_b(1936)--[[绛唇珠袖]], _b(2555)--[[丝牵]], _b(6317)--[[金针]], _b(6108)--[[天绝地灭]], _b(6091)--[[迷影]],
		},
	}, {
		szType = _L["Breakout"],	-- 7
		tName = {
			_b(200)--[[疾如风]], _b(2719)--[[青荷]], _b(2757)--[[紫气东来]], _b(538)--[[繁音急节]], _b(1378)--[[弱水]],
			_b(3468)--[[心无旁骛]], _b(3859)--[[香疏影]], _b(2726)--[[乱洒]], _b(5994)--[[酒中仙]], _b(2779)--[[渊]],
		},
	}, {
		szType = _L["Reduce-injury"],	-- 8
		tName = {
			-- 春泥可能已改为：6264 了，但没重名不影响
			_b(367)--[[守如山]], _b(384)--[[转乾坤]], _b(399)--[[无相诀]], _b(122)--[[春泥护花]], _b(3068)--[[雾体]],
			_b(1802)--[[御天]], _b(684)--[[天地低昂]], _b(4439)--[[贪魔体]], _b(6315)--[[零落]],
			_b(6240)--[[玄水蛊]], _b(5996)--[[笑醉狂]], _b(5810)--[[脑户]], _b(6200)--[[龙啸九天]]
		},
	}, {
		szType = _L["Dodge"],	-- 9
		tName = {
			_b(677)--[[鹊踏枝]], _b(3214)--[[惊鸿游龙]], _b(2065)--[[云栖松]], _b(5668)--[[风吹荷]], _b(6434)--[[醉逍遥]],
			_b(6299)--[[御风而行]],
		},
	}, {
		szType = _L["Uncontrollable2"],	-- 10
		tName = {
			_b(374)--[[生太极]], _b(1903)--[[啸日]]
		},	-- 生太极2：374
	}, {
		szType = _L["Reduce-heal"],	-- 11
		tName = {
			_b(2774)--[[霹雳]], _b(3195)--[[穿心弩]], _b(3538)--[[穿心]], _b(574)--[[无相]], _b(576)--[[恒河劫沙]],
			_b(2496)--[[百足枯残]], _b(2502)--[[蝎蛰]], _b(4030)--[[月劫]], _b(6155)--[[神龙降世]]
		},
	}, {
		szType = _L["Slower"],	-- 12
		tName = {
			-- 剑主天地可能改为：6072
			-- _b(733)--[[太乙]],
			_b(4928)--[[减速]], _b(549)--[[穿]], _b(450)--[[玄一]], _b(523)--[[步迟]], _b(2274)--[[缠足]], _b(560)--[[生太极]],
			_b(563)--[[抱残式]], _b(584)--[[少阳指]], _b(1553)--[[剑主天地]], _b(1720)--[[惊涛]],
			_b(2297)--[[千丝]], _b(2839)--[[玳弦]], _b(3226)--[[毒蒺藜]], _b(4054)--[[业海罪缚]], _b(6275)--[[火舞长空]],
			_b(6259)--[[雪中行]], _b(6191)--[[业力]], _b(6162)--[[山阵]], _b(6130)--[[埋骨]], _b(6078)--[[暴雨梨花针]]
		},
	}, {
		szType = _L["Others"],	-- 13
		tName = {
			_b(535)--[[半步颠]], _b(678)--[[傍花随柳]], _b(3929)--[[龙魂]], _b(198)--[[徐如林]], _b(203)--[[啸如虎]],
			_b(3858)--[[声趣]], _b(994)--[[倒地]], _b(3399)--[[无声]], _b(3276)--[[追命无声]], _b(4028)--[[圣月佑]],
			_b(6354)--[[虚回]], _b(6346)--[[风过无痕]], _b(6350)--[[临风]], _b(6266)--[[行气血]], _b(6224)--[[枭泣]],
			_b(6172)--[[鹰目]], _b(6143)--[[泉凝月]], _b(6121)--[[风虎]], _b(6122)--[[牧云]], _b(6425)--[[天地根]],
			_b(6085)--[[影捷]], _b(5970)--[[锋针]], _b(5875)--[[善护]], _b(5789)--[[繁音急节]], _b(5666)--[[雾外江山]],
			_b(999)--[[雨集]], _b(6074)--[[恶狗拦路]], _b(376)--[[冲阴阳]], _b(4937)--[[日月灵魂]], _b(4937,2)--[[日月同辉]],
			_b(2315)--[[女娲补天]], _b(2795)--[[罗汉金身]], _b(2778)--[[渊]], _b(3215)--[[荆天棘地]],
			_b(6256)--[[沃土]], _b(2542)--[[玉蟾献祭]],  _b(2920)--[[急曲]]
		},
	}, {
		szType = _L["Silence2"],	-- 14
		tName = {
			_b(445)--[[抢珠式]], _b(690)--[[剑心通明]], _b(2182)--[[八卦洞玄]], _b(2838)--[[剑破虚空]],
			_b(3227)--[[梅花针]], _b(2807)--[[凄切]], _b(2490)--[[蟾啸迷心]]
		},
	}
}

-- customdata
HM.RegisterCustomData("HM_TargetMon")

---------------------------------------------------------------------
-- 本地函数和变量
---------------------------------------------------------------------
local _HM_TargetMon = {
	tCD = {},
}

-- save data to restore
_HM_TargetMon.tBakSkill = HM_TargetMon.tSkillList4
_HM_TargetMon.tBakBuff = HM_TargetMon.tBuffList4

-- reset cd
_HM_TargetMon.tSkillReset = {
	[_s(552)--[[邻里曲]]] = { _s(557)--[[天地低昂]], _s(550)--[[鹊踏枝]], _s(574)--[[蝶弄足]], _s(548)--[[龙池乐]] },
	[_s(425)--[[御奔突]]] = { _s(428)--[[断魂刺]], _s(433)--[[任驰骋]], _s(426)--[[破坚阵]], _s(479)--[[裂苍穹]] },
	--[_s(346)--[[梯云纵]]] = { _s(9003)--[[蹑云逐月]] },
	--[_s(2645)--[[乱洒青荷]]] = { _s(182)--[[玉石俱焚]] },
	[_s(372)--[[转乾坤]]] = { _s(358)--[[生太极]], _s(361)--[[凌太虚]], _s(357)--[[化三清]], _s(363)--[[吞日月]] },
	[_s(1651)--[[断潮]]] = { _s(1593)--[[云飞玉皇]] },
	[_s(3978)--[[生灭予夺]]] = { _s(3974)--[[暗尘弥散]], _s(3975)--[[怖畏暗刑]], _s(4910)--[[无明魂锁]], _s(3977)--[[流光囚影]], _s(3976)--[[业海罪缚]], _s(3979)--[[驱夜断愁]] },
	--[_s(153)--[[带脉·光明]]] = { _s(413)--[[守如山]], _s(313)--[[韬光养晦]], _s(1645)--[[风来吴山]], _s(3114)--[[惊鸿游龙]] },
	--[_s(1959)--[[任脉·神阙]]] = { _s(131)--[[碧水滔天]], _s(555)--[[风袖低昂]], _s(2235)--[[千蝶吐瑞]] },
	--[_s(167)--[[冲脉·幽门]]] = { _s(371)--[[镇山河]], _s(573)--[[满堂势]], _s(136)--[[水月无间]], _s(257)--[[锻骨诀]], _s(3094)--[[心无旁骛]], _L["Call pet"], _s(3969)--[[光明相]] },
}

-- special repeat-name buff
_HM_TargetMon.tFixedBuffEx = {
	[_L("Invincible_%s", _b(6182)--[[冥泽]])] = 6182,
	[_L("Silence_%s", _b(712)--[[兰摧玉折]])] = 712,
	[_L("Halt_%s", _b(2780)--[[剑冲阴阳]])] = 2780,
	[_L("Halt_%s", _b(5876)--[[善护]])] = 5876,
	[_L("Entrap_%s", _b(1931)--[[吐故纳新]])] = 1931,
	[_L("Entrap_%s", _b(5809)--[[太乙]])] = 5809,
	[_L("Entrap_%s", _b(5764)--[[百足]])] = 5764,
	[_L("Entrap_%s", _b(5793)--[[碎冰]])] = 5793,
	[_L("Freeze_%s", _b(685)--[[傍花随柳]])] = 685,
	[_L("Freeze_%s", _b(1936)--[[绛唇珠袖]])] = 1936,
	[_L("Freeze_%s", _b(2113)--[[泉凝月]])] = 2113,
	[_L("Freeze_%s", _b(6108)--[[天绝地灭]])] = 6108,
	[_L("Uncontrollable2_%s", _b(374)--[[生太极]])] = 374,
	[_L("Uncontrollable_%s", _b(730)--[[风府]])] = 730,
	[_L("Uncontrollable_%s", _b(2781)--[[转乾坤]])] = 2781,
	[_L("Uncontrollable_%s", _b(6314)--[[零落]])] = 6314,
	[_L("Uncontrollable_%s", _b(6292)--[[吞日月]])] = 6292,
	[_L("Uncontrollable_%s", _b(6247)--[[迷心蛊]])] = 6247,
	[_L("Uncontrollable_%s", _b(5995)--[[笑醉狂]])] = 5995,
	[_L("Uncontrollable_%s", _b(6369)--[[酒中仙]])] = 6369,
	[_L("Uncontrollable_%s", _b(6015)--[[龙跃于渊]])] = 6015,
	[_L("Uncontrollable_%s", _b(5754)--[[霸体]])] = 5754,
	[_L("Uncontrollable_%s", _b(5950)--[[蛊虫献祭]])] = 5950,
	[_L("Breakout_%s", _b(5994)--[[酒中仙]])] = 5994,
	[_L("Breakout_%s", _b(2779)--[[渊]])] = 2779,
	[_L("Slower_%s", _b(560)--[[生太极]])] = 560,
	[_L("Slower_%s", _b(733)--[[太乙]])] = 733,
	[_L("Slower_%s", _b(2839)--[[玳弦]])] = 2839,
	[_L("Slower_%s", _b(6162)--[[山阵]])] = 6162,
	[_L("Slower_%s", _b(6078)--[[暴雨梨花针]])] = 6078,
	[_L("Halt_%s", _b(548)--[[突]])] = 548,
	[_L("Dodge_%s", _b(5668)--[[风吹荷]])] = 5668,
	[_L("Dodge_%s", _b(6299)--[[御风而行]])] = 6299,
	[_L("Reduce-dealing_%s", _b(3195)--[[穿心弩]])] = 3195,
	[_L("Reduce-injury_%s", _b(384)--[[转乾坤]])] = 384,
	[_L("Reduce-injury_%s", _b(4439)--[[贪魔体]])] = 4439,
	[_L("Reduce-injury_%s", _b(6315)--[[零落]])] = 6315,
	[_L("Reduce-injury_%s", _b(6240)--[[玄水蛊]])] = 6240,
	[_L("Reduce-injury_%s", _b(5996)--[[笑醉狂]])] = 5996,
	[_L("Reduce-injury_%s", _b(5810)--[[脑户]])] = 5810,
	[_L("Others_%s", _b(6354)--[[虚回]])] = 6354,
	[_L("Others_%s", _b(6266)--[[行气血]])] = 6266,
	[_L("Others_%s", _b(5970)--[[锋针]])] = 5970,
	[_L("Others_%s", _b(5875)--[[善护]])] = 5875,
	[_L("Others_%s", _b(5789)--[[繁音急节]])] = 5789,
	[_L("Others_%s", _b(6425)--[[天地根]])] = 6425,
	[_L("Others_%s", _b(2778)--[[渊]])] = 2778,
	[_L("Others_%s", _b(6256)--[[沃土]])] = 6256,
}

-- special skill alias
_HM_TargetMon.tFixedSkill = {
	[_s(2965)--[[碧蝶引]]] = _L["Call pet"],
	[_s(2221)--[[圣蝎引]]] = _L["Call pet"],
	[_s(2222)--[[玉蟾引]]] = _L["Call pet"],
	[_s(2223)--[[灵蛇引]]] = _L["Call pet"],
	[_s(2224)--[[风蜈引]]] = _L["Call pet"],
	[_s(2225)--[[天蛛引]]] = _L["Call pet"],
}

-- load buffex cache
_HM_TargetMon.LoadBuffEx = function()
	local aCache = {}
	for k, v in ipairs(HM_TargetMon.tBuffList4) do
		for _, vv in ipairs(v.tName) do
			local dwFixedID = _HM_TargetMon.tFixedBuffEx[v.szType .. "_" .. vv]
			if dwFixedID then
				aCache[dwFixedID] = { v.szType, k }
			else
				aCache[vv] = { v.szType, k }
			end
		end
	end
	_HM_TargetMon.tBuffCache = aCache
end

-- load  monskill cache
_HM_TargetMon.LoadSkillMon = function()
	local aCache = {}
	for _, v in ipairs(HM_TargetMon.tSkillList4) do
		for kk, vv in pairs(v) do
			if vv > 0 then
				aCache[kk] = vv
			end
		end
	end
	_HM_TargetMon.tSkillCache = aCache
end

-- get buffex type, type index
_HM_TargetMon.GetBuffExType = function(dwBuffID, dwLevel, tNo)
	if not _HM_TargetMon.tBuffCache then
		_HM_TargetMon.LoadBuffEx()
	end
	if not tNo or not tNo[dwBuffID] then
		local rec = _HM_TargetMon.tBuffCache[dwBuffID]
		if not rec and type(dwBuffID) == "number" then
			local szName = HM.GetBuffName(dwBuffID, dwLevel)
			if szName and szName ~= "" and (not tNo or not tNo[szName]) then
				rec = _HM_TargetMon.tBuffCache[szName]
			end
		end
		if rec then
			return rec[1], rec[2]
		end
	end
end

-- get buffex list
_HM_TargetMon.GetBuffExList = function(aBuff, tNo)
	local mBuff, nFrame = {}, GetLogicFrameCount()
	for _, v in ipairs(aBuff) do
		if v.nEndFrame > nFrame then
			local szType, nType = _HM_TargetMon.GetBuffExType(v.dwID, v.nLevel, tNo)
			if szType then
				table.insert(mBuff, { buff = v, szType = szType, nType = nType })
			end
		end
	end
	if #mBuff > 1 then
		table.sort(mBuff, function(a, b) return a.nType < b.nType end)
	end
	return mBuff
end

-- get skillmon cooldown
_HM_TargetMon.GetSkillMonCD = function(szName)
	if not _HM_TargetMon.tSkillCache then
		_HM_TargetMon.LoadSkillMon()
	end
	return _HM_TargetMon.tSkillCache[szName]
end

-- purge: [dwCaster] => { { nEnd, nTotal, dwIconID, szName }, ... }
_HM_TargetMon.PurgeData = function()
	local nExpire , nFrame = 960, GetLogicFrameCount()
	if not _HM_TargetMon.nPurgeFrame then
		_HM_TargetMon.nPurgeFrame = nFrame
	elseif (nFrame - _HM_TargetMon.nPurgeFrame) > nExpire then
		_HM_TargetMon.nPurgeFrame = nFrame
		for k, v in pairs(_HM_TargetMon.tCD) do
			for kk, vv in ipairs(v) do
				if vv.nEnd < nFrame then
					table.remove(v, kk)
				end
			end
			if table.getn(v) == 0 then
				_HM_TargetMon.tCD[k] = nil
			end
		end
	end
end

-- get mon cd for player
_HM_TargetMon.GetPlayerCD = function(dwPlayer)
	local aCD, nFrame = {}, GetLogicFrameCount()
	if _HM_TargetMon.tCD[dwPlayer] then
		aCD = _HM_TargetMon.tCD[dwPlayer]
		for k, v in ipairs(aCD) do
			if v.nEnd < nFrame then
				table.remove(aCD, k)
			end
		end
	end
	return aCD
end

-- get forcetitle
_HM_TargetMon.GetForceTitle = function(nForce)
	if nForce >= 1 and nForce <= 10 then
		return g_tStrings.tForceTitle[nForce]
	end
	return _L["Others"]
end

-- get skill belong force
-- 1：天策，2：万花，3：纯阳，4：七秀，5：少林，6：藏剑，7：丐帮，8：明教，9：五毒，10：唐门
-- 1：少林，2：万花，3：天策，4：纯阳，5：七秀，6：五毒，7：唐门，8：藏剑，9:丐帮，10：明教
_HM_TargetMon.tSchoolToForce = { 3, 2, 4, 5, 1, 8, 9, 10, 6, 7 }
_HM_TargetMon.GetSkillForce = function(szName)
	local nCount = g_tTable.Skill:GetRowCount()
	for i = 1, nCount do
		local tLine = g_tTable.Skill:GetRow(i)
		if tLine.bShow and tLine.dwIconID ~= 13 and tLine.szName == szName then
			local skill = GetSkill(tLine.dwSkillID, 1)
			if skill then
				if skill.dwBelongSchool >= 1 and skill.dwBelongSchool <= 10 then
					return _HM_TargetMon.tSchoolToForce[skill.dwBelongSchool]
				elseif skill.dwBelongSchool == 0 or skill.dwBelongSchool == 14
					or skill.dwBelongSchool == 15 or skill.dwBelongSchool == 16
				then	-- 江湖，轻功，经脉，装备
					return 11
				end
			end
		end
	end
end

-- edit skill
_HM_TargetMon.EditSkill = function(nForce, szName)
	local frm = _HM_TargetMon.sFrame
	if not frm then
		-- input
		frm = HM.UI.CreateFrame("HM_TARMON_SKILL", { close = false, w = 381, h = 270 })
		frm:Append("Text", { txt = _L["Skill name"], x = 0, y = 0, font = 27 })
		frm:Append("WndEdit", "Edit_Name", { x = 0, y = 28, limit = 100, w = 290, h = 25 } )
		frm:Append("Text", { txt = _L["Skill CD (unit: sec)"], x = 0, y = 60, font = 27 })
		frm:Append("WndEdit", "Edit_Time", { x = 0, y = 88, limit = 100, w = 290, h = 25 } )
		-- buttons
		frm:Append("WndButton", "Btn_Save", { txt = _L["Save"], x = 45, y = 140 }):Click(function()
			local szName = frm:Fetch("Edit_Name"):Text()
			local nTime = tonumber(frm:Fetch("Edit_Time"):Text())
			if szName == "" then
				HM.Alert(_L["Skill name can not be empty"])
			elseif not nTime then
				HM.Alert(_L["Invalid value of skill CD"])
			else
				local nForce = frm.nForce or _HM_TargetMon.GetSkillForce(szName)
				if not nForce then
					HM.Alert(_L("Invalid skill name [%s]", szName))
				else
					HM_TargetMon.tSkillList4[nForce][szName] = nTime
					if not frm.nForce then
						HM.Sysmsg(_L("Added skill CD monitor [%s-%s]", _HM_TargetMon.GetForceTitle(nForce), szName))
					end
					frm:Toggle(false)
					_HM_TargetMon.tSkillCache = nil
				end
			end
		end)
		frm:Append("WndButton", "Btn_Cancel", { txt = _L["Cancel"], x = 145, y = 140 }):Click(function() frm:Toggle(false) end)
		_HM_TargetMon.sFrame = frm
	end
	-- show frm
	frm.nForce = nForce
	if not nForce then
		frm:Title(_L["Add skill CD"])
		frm:Fetch("Edit_Name"):Text(""):Enable(true)
		frm:Fetch("Edit_Time"):Text("")
	else
		frm:Title(_L["Edit skill CD"])
		frm:Fetch("Edit_Name"):Text(szName):Enable(false)
		frm:Fetch("Edit_Time"):Text(tostring(math.abs(HM_TargetMon.tSkillList4[nForce][szName])))
	end
	frm:Toggle(true)
end

-- get skill setting menu
_HM_TargetMon.GetSkillMenu = function()
	local m0 = {
		{ szOption = _L["* New *"], fnAction = _HM_TargetMon.EditSkill },
		{
			szOption = _L["* Reset *"],
			fnAction = function()
				HM_TargetMon.tSkillList4 = clone(_HM_TargetMon.tBakSkill)
				_HM_TargetMon.tSkillCache = nil
			end
		},
		{ bDevide = true, }
	}
	for k, v in ipairs(HM_TargetMon.tSkillList4) do
		if not IsEmpty(v) then
			local m1 = { szOption = _HM_TargetMon.GetForceTitle(k) }
			for kk, vv in pairs(v) do
				table.insert(m1, {
					szOption = kk .. " (" .. math.abs(vv) .. ")",
					bCheck = true, bChecked = vv > 0,
					fnAction = function() v[kk] = 0 - vv end,
					{ szOption = _L["Edit"], fnAction = function() _HM_TargetMon.EditSkill(k, kk) end },
					{ szOption = _L["Remove"], fnAction = function() v[kk] = nil
						_HM_TargetMon.tSkillCache = nil
						HM.Sysmsg(_L("Removed skill CD monitor [%s-%s]", _HM_TargetMon.GetForceTitle(k), kk)) end },
				})
			end
			table.insert(m0, m1)
		end
	end
	return m0
end

-- edit buff
_HM_TargetMon.EditBuff = function()
	local frm = _HM_TargetMon.bFrame
	if not frm then
		-- input
		frm = HM.UI.CreateFrame("HM_TARMON_BUFF", { close = false, w = 381, h = 200 })
		local nX = frm:Append("Text", { txt = _L["Name"], x = 0, y = 20, font = 27 }):Pos_()
		nX = frm:Append("WndEdit", "Edit_Name", { x = nX + 5, y = 20, limit = 100, w = 160, h = 25 } ):Pos_()
		frm:Append("WndComboBox", "Combo_Type", { x = nX + 5, y = 20, w = 80, h = 25 } ):Menu( function()
			local m0 = {}
			for k, v in ipairs(HM_TargetMon.tBuffList4) do
				table.insert(m0, { szOption = v.szType, fnAction = function()
					frm.nType = k
					frm:Fetch("Combo_Type"):Text(v.szType)
				end})
			end
			return m0
		end)
		-- buttons
		frm:Append("WndButton", "Btn_Save", { txt = _L["Save"], x = 45, y = 80 }):Click(function()
			local szName = frm:Fetch("Edit_Name"):Text()
			if szName == "" then
				HM.Alert(_L["Buff name can not be empty"])
			else
				local tBuff = HM_TargetMon.tBuffList4[frm.nType]
				if tBuff then
					for _, v in ipairs(tBuff.tName) do
						if v == szName then
							return HM.Alert(_L["Buff name already exists"])
						end
					end
					table.insert(tBuff.tName, szName)
					HM.Sysmsg(_L("Added buff monitor [%s-%s]", tBuff.szType, szName))
					frm:Toggle(false)
					_HM_TargetMon.tBuffCache = nil
				end
			end
		end)
		frm:Append("WndButton", "Btn_Cancel", { txt = _L["Cancel"], x = 145, y = 80 }):Click(function() frm:Toggle(false) end)
		_HM_TargetMon.bFrame = frm
	end
	-- show frm
	frm.nType = table.getn(HM_TargetMon.tBuffList4)
	frm:Fetch("Edit_Name"):Text("")
	frm:Fetch("Combo_Type"):Text(HM_TargetMon.tBuffList4[frm.nType].szType)
	frm:Title(_L["Add buff monitor"])
	frm:Toggle(true)
end

-- get buff setting menu
_HM_TargetMon.GetBuffMenu = function()
	local m0 = {
		{ szOption = _L["* New *"], fnAction = _HM_TargetMon.EditBuff },
		{
			szOption = _L["* Reset *"],
			fnAction = function()
				HM_TargetMon.tBuffList4 = clone(_HM_TargetMon.tBakBuff)
				_HM_TargetMon.tBuffCache = nil
			end
		},
		{ bDevide = true, }
	}
	for _, v in ipairs(HM_TargetMon.tBuffList4) do
		if not IsEmpty(v.tName) then
			local m1 = { szOption = v.szType }
			for kk, vv in ipairs(v.tName) do
				local vk = _HM_TargetMon.tFixedBuffEx[v.szType .. "_" .. vv] or vv
				table.insert(m1, { szOption = vv,
					{ szOption = _L["Monitor target"], bCheck = true, bChecked = not HM_TargetMon.tNTBuffEx[vk], fnAction = function()
						if HM_TargetMon.tNTBuffEx[vk] then
							HM_TargetMon.tNTBuffEx[vk] = nil
						else
							HM_TargetMon.tNTBuffEx[vk] = true
						end
					end }, { szOption = _L["Monitor myself"], bCheck = true, bChecked = not HM_TargetMon.tNSBuffEx[vk], fnAction = function()
						if HM_TargetMon.tNSBuffEx[vk] then
							HM_TargetMon.tNSBuffEx[vk] = nil
						else
							HM_TargetMon.tNSBuffEx[vk] = true
						end
					end }, { szOption = _L["Remove"], fnAction = function()
						table.remove(v.tName, kk)
						_HM_TargetMon.tBuffCache = nil
						HM.Sysmsg(_L("Removed buff monitor [%s_%s]", v.szType, vv))
					end },
				})
			end
			table.insert(m0, m1)
		end
	end
	return m0
end

---------------------------------------------------------------------
-- 窗口界面
---------------------------------------------------------------------
-- add box/text pair
_HM_TargetMon.GetBoxText = function(hBox, hText)
	local nCount = hBox:GetItemCount()
	if hBox.nIndex < nCount then
		nCount = hBox.nIndex
	else
		hBox:AppendItemFromString("<box> w=" .. HM_TargetMon.nSize .. " h=" .. HM_TargetMon.nSize .. " postype=7 eventid=768 </box>")
		hText:AppendItemFromString("<text> w=" .. HM_TargetMon.nSize .. " h=15 postype=7 halign=1 valign=1 </text>")
		if not HM_TargetMon.bBoxEvent2 then
			hBox:Lookup(nCount):ClearEvent()
		end
	end
	hBox.nIndex = nCount + 1
	return hBox:Lookup(nCount), hText:Lookup(nCount)
end

-- get time & font
_HM_TargetMon.GetLeftTime = function(nEndFrame, bFloat)
	local nSec = (nEndFrame - GetLogicFrameCount()) / 16
	if nSec < 100 then
		if bFloat and nSec < 3 then
			return string.format("%.1f\"", nSec), 204
		else
			return string.format("%d\"", nSec), 204
		end
	elseif nSec < 3600 then
		return string.format("%d'", nSec / 60), 203
	elseif nSec < 36000 then
		return string.format("%d", nSec / 3600), 203
	else
		return "", 203
	end
end

-- update skill box
_HM_TargetMon.UpdateSkillBox = function(data, box, txt)
	if not box.dwID then
		txt:SetFontScheme(15)
		box:SetOverTextFontScheme(0, 15)
		box:SetOverTextPosition(1, 3)
		box.OnItemMouseEnter = function()
			this:SetObjectMouseOver(1)
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputSkillTip(this.dwID, this.dwLevel, { x, y, w, h })
		end
		box.OnItemMouseLeave = function()
			this:SetObjectMouseOver(0)
			HideTip()
		end
	end
	if box.dwID ~= data.dwSkillID or box.dwLevel ~= data.dwLevel then
		box.dwID = data.dwSkillID
		box.dwLevel = data.dwLevel
		box:SetObject(UI_OBJECT_SKILL, data.dwSkillID, data.dwLevel)
		box:SetObjectIcon(data.dwIconID)
		box:SetObjectCoolDown(1)
		if string.len(data.szName) > 6 and HM_TargetMon.nSize < 70  then
			txt:SetText(string.sub(data.szName, 1, 4))
		elseif string.len(data.szName) > 4 and HM_TargetMon.nSize < 45 then
			txt:SetText(string.sub(data.szName, 3, 6))
		else
			txt:SetText(data.szName)
		end
	end
	local szTime, nFont = _HM_TargetMon.GetLeftTime(data.nEnd)
	box:SetOverText(1, szTime)
	box:SetOverTextFontScheme(1, nFont)
	box:SetCoolDownPercentage(1 - (data.nEnd - GetLogicFrameCount()) / data.nTotal)
	box:Show()
	txt:Show()
end

-- update buff box
_HM_TargetMon.UpdateBuffBox = function(data, box, txt, szType)
	if not box.dwID then
		box:SetOverTextFontScheme(0, 15)
		box:SetOverTextPosition(1, 3)
		box.OnItemMouseEnter = function()
			this:SetObjectMouseOver(1)
			local dwOwner = this:GetParent().dwOwner
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputBuffTip(dwOwner, this.dwID, this.nLevel, 1, false, 0, { x, y, w, h })
		end
		box.OnItemMouseLeave = function()
			this:SetObjectMouseOver(0)
			HideTip()
		end
	end
	if box.dwID ~= data.dwID or box.nLevel ~= data.nLevel then
		local szName, dwIconID = HM.GetBuffName(data.dwID, data.nLevel)
		box.dwID = data.dwID
		box:SetObject(UI_OBJECT_NOT_NEED_KNOWN, data.dwID)
		box:SetObjectIcon(dwIconID)
		if szType ~= _L["Others"] then
			szName = string.gsub(szType, "%d+$", "")
		end
		txt:SetText(szName)
		if box:GetParent().dwOwner == GetClientPlayer().dwID then
			if data.bCanCancel then
				txt:SetFontScheme(167)
			else
				txt:SetFontScheme(17)
			end
		else
			if data.bCanCancel then
				txt:SetFontScheme(16)
			else
				txt:SetFontScheme(159)
			end
		end
	end
	box.nLevel = data.nLevel
	if data.nStackNum > 1 then
		box:SetOverText(0, data.nStackNum)
	else
		box:SetOverText(0, "")
	end
	local szTime, nFont = _HM_TargetMon.GetLeftTime(data.nEndFrame, true)
	box:SetOverText(1, szTime)
	box:SetOverTextFontScheme(1, nFont)
	box:Show()
	txt:Show()
end

-- adjust size
_HM_TargetMon.AdjustSize = function(frame)
	local nW, nH = HM_TargetMon.nSize * 3, HM_TargetMon.nSize + 25
	local handle = frame:Lookup("", "")
	local hBox, hText = handle:Lookup("Handle_Box"), handle:Lookup("Handle_Text")
	frame:SetSize(nW, nH)
	handle:SetSize(nW, nH)
	hBox:SetSize(nW, HM_TargetMon.nSize)
	hText:SetSize(nW, 25)
	hText:SetRelPos(0, HM_TargetMon.nSize + 5)
	hBox:Clear()
	hText:Clear()
	handle:FormatAllItemPos()
end

-- anchor
_HM_TargetMon.UpdateAnchor = function(frame)
	local an = HM_TargetMon.tAnchor[frame.nIndex]
	if an then
		-- custom pos
		frame:SetPoint(an.s, 0, 0, an.r, an.x, an.y)
	else
		-- default pos
		local dir = Station.Lookup("Normal/HM_TargetDir")
		if dir then
			local x, y = dir:GetAbsPos()
			if frame.nIndex == 3 then
				local _, h = dir:GetSize()
				frame:SetAbsPos(x, y + h)
			else
				frame:SetAbsPos(x, y - (3 - frame.nIndex) * (HM_TargetMon.nSize + 25))
			end
		else
			frame:SetAbsPos(460, 220 + (frame.nIndex - 1) * (HM_TargetMon.nSize + 25))
		end
	end
	frame:CorrectPos()
end

-- create
_HM_TargetMon.OnFrameCreate = function()
	this:RegisterEvent("ON_ENTER_CUSTOM_UI_MODE")
	this:RegisterEvent("ON_LEAVE_CUSTOM_UI_MODE")
	this:RegisterEvent("UI_SCALED")
	_HM_TargetMon.AdjustSize(this)
	_HM_TargetMon.UpdateAnchor(this)
	if this.nIndex == 1 then
		UpdateCustomModeWindow(this, _L["HM skill CD"])
	elseif this.nIndex == 2 then
		UpdateCustomModeWindow(this, _L["HM target BUFF"])
	elseif this.nIndex == 3 then
		UpdateCustomModeWindow(this, _L["HM self BUFF"])
	end
end

-- breathe
_HM_TargetMon.OnFrameBreathe = function()
	-- base check
	local nFrame, me = GetLogicFrameCount(), GetClientPlayer()
	if not me or (nFrame % 3) ~= (this.nIndex - 1) then return end
	--if not me then return end
	local tar = GetTargetHandle(me.GetTarget())
	-- draw data
	local hBox, hText, bHide = this:Lookup("", "Handle_Box"), this:Lookup("", "Handle_Text"), true
	if this.nIndex == 1 then
		if tar and _HM_TargetMon.tCD[tar.dwID] then
			hBox.nIndex = 0
			for _, v in ipairs(_HM_TargetMon.tCD[tar.dwID]) do
				if v.nEnd > nFrame then
					local box, txt = _HM_TargetMon.GetBoxText(hBox, hText)
					_HM_TargetMon.UpdateSkillBox(v, box, txt)
					bHide = false
				end
			end
		end
	else
		local aBuff, tNo = nil, nil
		if this.nIndex == 2 and tar then	-- target buff
			aBuff = HM.GetAllBuff(tar)
			hBox.dwOwner = tar.dwID
			tNo = HM_TargetMon.tNTBuffEx
		elseif this.nIndex == 3 then -- and (not tar or tar.dwID ~= me.dwID or not HM_TargetMon.bTargetBuffEx) then
			aBuff = HM.GetAllBuff(me)
			hBox.dwOwner = me.dwID
			tNo = HM_TargetMon.tNSBuffEx
		end
		if aBuff then
			local mBuff = _HM_TargetMon.GetBuffExList(aBuff, tNo)
			hBox.nIndex = 0
			if #mBuff > 0 then
				bHide = false
				for _, v in ipairs(mBuff) do
					local box, txt = _HM_TargetMon.GetBoxText(hBox, hText)
					_HM_TargetMon.UpdateBuffBox(v.buff, box, txt, v.szType)
				end
			end
		end
	end
	if bHide then
		hBox:Hide()
		hText:Hide()
	else
		for i = hBox:GetItemCount() - 1, hBox.nIndex, -1 do
			hBox:Lookup(i):Hide()
			hText:Lookup(i):Hide()
		end
		hBox:FormatAllItemPos()
		hText:FormatAllItemPos()
		hBox:Show()
		hText:Show()
		-- right align
		local handle = this:Lookup("", "")
		if (HM_TargetMon.bSkillRight and this.nIndex == 1)
			or (HM_TargetMon.bTargetRight and this.nIndex == 2)
			or (HM_TargetMon.bSelfRight and this.nIndex == 3)
		then
			local w1, _ = handle:GetSize()
			local w2 = hBox.nIndex * HM_TargetMon.nSize
			--local w2, _ = hBox:GetAllItemSize()
			hBox:SetRelPos(w1 - w2, 0)
			hText:SetRelPos(w1 - w2, HM_TargetMon.nSize + 5)
		else
			hBox:SetRelPos(0, 0)
			hText:SetRelPos(0, HM_TargetMon.nSize + 5)
		end
		handle:FormatAllItemPos()
	end
end

-- drag
_HM_TargetMon.OnFrameDragEnd = function()
	this:CorrectPos()
	HM_TargetMon.tAnchor[this.nIndex] = GetFrameAnchor(this)
end

-- event
_HM_TargetMon.OnEvent = function(event)
	if event == "ON_ENTER_CUSTOM_UI_MODE" or event == "ON_LEAVE_CUSTOM_UI_MODE" then
		UpdateCustomModeWindow(this)
	elseif event == "UI_SCALED" then
		_HM_TargetMon.UpdateAnchor(this)
	end
end

-- update frame
_HM_TargetMon.UpdateFrame = function(bEnable, nIndex)
	local frame = Station.Lookup("Normal/HM_TargetMon_" .. nIndex)
	if bEnable then
		if not frame then
			frame = Wnd.OpenWindow("interface\\HM\\HM_TargetMon\\HM_TargetMon.ini", "HM_TargetMon_" .. nIndex)
			frame.nIndex = nIndex
			frame.OnFrameBreathe = _HM_TargetMon.OnFrameBreathe
			frame.OnFrameDragEnd = _HM_TargetMon.OnFrameDragEnd
			frame.OnEvent = _HM_TargetMon.OnEvent
			local _this = this
			this = frame
			_HM_TargetMon.OnFrameCreate()
			this = _this
		end
	elseif frame then
		Wnd.CloseWindow(frame)
	end
end

-- update frames
_HM_TargetMon.UpdateFrames = function()
	_HM_TargetMon.UpdateFrame(HM_TargetMon.bSkillMon, 1)
	_HM_TargetMon.UpdateFrame(HM_TargetMon.bTargetBuffEx, 2)
	_HM_TargetMon.UpdateFrame(HM_TargetMon.bSelfBuffEx, 3)
end

-- adjust all size
_HM_TargetMon.AdjustSizeAll = function()
	for i = 1, 3, 1 do
		local frame = Station.Lookup("Normal/HM_TargetMon_" .. i)
		if frame then
			_HM_TargetMon.AdjustSize(frame)
			_HM_TargetMon.UpdateAnchor(frame)
			UpdateCustomModeWindow(frame)
		end
	end
end

---------------------------------------------------------------------
-- 事件处理函数
---------------------------------------------------------------------
_HM_TargetMon.OnSkillCast = function(dwCaster, dwSkillID, dwLevel, szEvent)
	if not HM_TargetMon.bSkillMon then
		return
	end
	-- get name
	local szName, dwIconID = HM.GetSkillName(dwSkillID, dwLevel)
	if not szName or szName == "" or dwIconID == 13 then
		return
	end
	_HM_TargetMon.PurgeData()
	if not HM_Jabber then
		HM.Debug3("#" .. dwCaster .. "#" .. szEvent .. " (" .. szName .. "#" .. dwSkillID .. ", Lv" .. dwLevel .. ")")
	end
	-- check reset
	local aReset = _HM_TargetMon.tSkillReset[szName] or {}
	for _, v in ipairs(aReset) do
		local aCD = _HM_TargetMon.tCD[dwCaster] or {}
		for kk, vv in ipairs(aCD) do
			if vv.szName == v then
				table.remove(aCD, kk)
			end
		end
	end
	-- check cd
	if _HM_TargetMon.tFixedSkill[szName] then
		szName = _HM_TargetMon.tFixedSkill[szName]
	end
	local nSec = _HM_TargetMon.GetSkillMonCD(szName)
	if nSec then
		if not _HM_TargetMon.tCD[dwCaster] then
			_HM_TargetMon.tCD[dwCaster] = {}
		else
			for k, v in ipairs(_HM_TargetMon.tCD[dwCaster]) do
				if v.szName == szName then
					table.remove(_HM_TargetMon.tCD[dwCaster], k)
					break
				end
			end
		end
		local nTotal = nSec * 16
		local nEnd = GetLogicFrameCount() + nTotal
		table.insert(_HM_TargetMon.tCD[dwCaster], {
			nEnd = nEnd, nTotal = nTotal,
			dwSkillID = dwSkillID, dwLevel = dwLevel,
			dwIconID = dwIconID, szName = szName
		})
	end
end

---------------------------------------------------------------------
-- 设置界面
---------------------------------------------------------------------
_HM_TargetMon.PS = {}

-- init panel
_HM_TargetMon.PS.OnPanelActive = function(frame)
	local ui, nX = HM.UI(frame), 0
	-- skillmon
	ui:Append("Text", { txt = _L["Target skill"], font = 27 })
	nX = ui:Append("WndCheckBox", { txt = _L["Enable monitor target skill CD"], checked = HM_TargetMon.bSkillMon })
	:Pos(10, 28):Click(function(bChecked)
		HM_TargetMon.bSkillMon = bChecked
		_HM_TargetMon.UpdateFrame(bChecked, 1)
		if not bChecked then _HM_TargetMon.tCD = {} end
	end):Pos_()
	ui:Append("WndCheckBox", { txt = _L["Right aligment"], checked = HM_TargetMon.bSkillRight })
	:Pos(nX + 10, 28):Click(function(bChecked) HM_TargetMon.bSkillRight = bChecked end)
	ui:Append("WndComboBox", { txt = _L["Set monitor skill"], x = 10, y = 58 }):Menu(_HM_TargetMon.GetSkillMenu)
	-- buffex
	ui:Append("Text", { txt = _L["Important BUFF"], font = 27, x = 0, y = 94 })
	nX = ui:Append("WndCheckBox", { txt = _L["Monitor target important BUFF"], checked = HM_TargetMon.bTargetBuffEx })
	:Pos(10, 122):Click(function(bChecked)
		HM_TargetMon.bTargetBuffEx = bChecked
		_HM_TargetMon.UpdateFrame(bChecked, 2)
	end):Pos_()
	ui:Append("WndCheckBox", { txt = _L["Right aligment"], checked = HM_TargetMon.bTargetRight })
	:Pos(nX + 10, 122):Click(function(bChecked) HM_TargetMon.bTargetRight = bChecked end)
	ui:Append("WndCheckBox", { txt = _L["Monitor own important BUFF"], checked = HM_TargetMon.bSelfBuffEx })
	:Pos(10, 150):Click(function(bChecked)
		HM_TargetMon.bSelfBuffEx = bChecked
		_HM_TargetMon.UpdateFrame(bChecked, 3)
	end)
	ui:Append("WndCheckBox", { txt = _L["Right aligment"], checked = HM_TargetMon.bSelfRight })
	:Pos(nX + 10, 150):Click(function(bChecked) HM_TargetMon.bSelfRight = bChecked end)
	ui:Append("WndComboBox", { txt = _L["Set monitor buff"], x = 10, y = 178 }):Menu(_HM_TargetMon.GetBuffMenu)
	-- other
	ui:Append("Text", { txt = _L["Others"], font = 27, x = 0, y = 212 })
	nX = ui:Append("Text", { txt = _L["Adjust icon size of monitor buff/skill"], x = 10, y = 240 }):Pos_()
	ui:Append("WndComboBox", "Combo_Size", { x = nX + 5, y = 240, w = 60, h = 25 })
	:Text(tostring(HM_TargetMon.nSize)):Menu(function()
		local m0 = {}
		for i = 35, 80, 5 do
			table.insert(m0, { szOption = tostring(i), fnAction = function()
				HM_TargetMon.nSize = i
				HM.UI.Fetch(frame, "Combo_Size"):Text(tostring(i))
				_HM_TargetMon.AdjustSizeAll()
			end })
		end
		return m0
	end)
	ui:Append("WndCheckBox", { txt = _L["Show buff/skill tips when mouse enter the icon (affect to rotate lens)"], checked = HM_TargetMon.bBoxEvent2 })
	:Pos(10, 268):Click(function(bChecked)
		HM_TargetMon.bBoxEvent2 = bChecked
	end)
	-- tips
	ui:Append("Text", { txt = _L["Tips"], font = 27, x = 0, y = 304 })
	ui:Append("Text", { txt = _L["1. Press SHIFT-U to adjust the monitor position"], x = 10, y = 329 })
	ui:Append("Text", { txt = _L["2. As buff name often conflict, please tell me if you find wrong"], x = 10, y = 354 })
end

---------------------------------------------------------------------
-- 注册事件、初始化
---------------------------------------------------------------------
HM.RegisterEvent("PLAYER_ENTER_GAME", _HM_TargetMon.UpdateFrames)
HM.RegisterEvent("SYS_MSG", function()
	if arg0 == "UI_OME_SKILL_HIT_LOG" and arg3 == SKILL_EFFECT_TYPE.SKILL then
		_HM_TargetMon.OnSkillCast(arg1, arg4, arg5, arg0)
	elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" and arg4 == SKILL_EFFECT_TYPE.SKILL then
		_HM_TargetMon.OnSkillCast(arg1, arg5, arg6, arg0)
	elseif (arg0 == "UI_OME_SKILL_BLOCK_LOG" or arg0 == "UI_OME_SKILL_SHIELD_LOG"
			or arg0 == "UI_OME_SKILL_MISS_LOG" or arg0 == "UI_OME_SKILL_DODGE_LOG")
		and arg3 == SKILL_EFFECT_TYPE.SKILL
	then
		_HM_TargetMon.OnSkillCast(arg1, arg4, arg5, arg0)
	end
end)
HM.RegisterEvent("DO_SKILL_CAST", function()
	_HM_TargetMon.OnSkillCast(arg0, arg1, arg2, "DO_SKILL_CAST")
end)

-- add to HM panel
HM.RegisterPanel(_L["Target BUFF/CD"], 332, _L["Target"], _HM_TargetMon.PS)

-- public api
HM_TargetMon.GetBuffExType = _HM_TargetMon.GetBuffExType
HM_TargetMon.GetBuffExList = _HM_TargetMon.GetBuffExList
HM_TargetMon.UpdateFrames = _HM_TargetMon.UpdateFrames
HM_TargetMon.GetLeftTime  = _HM_TargetMon.GetLeftTime
HM_TargetMon.GetPlayerCD = function(dwPlayer) return _HM_TargetMon.tCD[dwPlayer] or {} end
