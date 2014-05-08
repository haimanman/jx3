海鳗、插件集：基础库 API
==========================

前言
----

海鳗插件集中的 `HM.lua` 包含了大量常用的函数库封装，以及动态创建插件设置面板中
的 UI 元件的方法。为方便自己复查，以及大家了解这些 API 特意编写了这份说明。

想要使用这些函数库，必须在 JX3 客户端中装有海鳗插件最新版本。如果实在不想安装
整个插件，您可以复制插件目录中的 `HM.lua` 用于单独加载亦可。


常用 API
---------

1.  `HM.szTitle` - 静态属性：插件集名称


2.  `HM.szBuildDate` - 静态属性：插件更新打包日期，格式：YYYYMMDD


3.  `HM.bDebug` - 静态属性：用于表示是否开启 DEBUG 信息，设为 *true* 可在头像菜单设置 DEBUG 信息级别。
    级别越高（最高3级），输出的信息越多，参见：`HM.Debug() HM.Debug2() HM.Debug3()`


4.  `(string, number) HM.GetVersion()` - 取得字符串版本号和整型版本号


5.  `(bool) HM.IsPanelOpened()` - 判断设置面板是否已打开，已打开返回 *true*


6.  `(void) HM.OpenPanel([string szTitle])` - 打开名称为 *szTitle* 的插件或分组设置界面，
    若省略参数则打开整个面板。例如：
    ```lua
    HM.OpenPanel("其它")  -- 打开“其它”分组
    HM.OpenPanel("团队标记/集火") -- 打开“团队标记/集火”功能设置界面
    ```

7. `(void) HM.ClosePanel([bool real = false])` - 隐藏设置面板，参数 *real* 若为 *true* 则彻底销毁面板


8.  `(void) HM.TogglePanel()` - 显示/隐藏设置面板


9.  `(void) HM.RegisterTempTarget(number dwID)` - 登记需要临时设为目标的玩家，
    在非战斗状态会临时切换目标然后再还原之前的目标，用以获取目标玩家的内功。

    > 参数 *dwID* -- 需要关注的玩家 ID（数字）


10. `(void) HM.AppendPlayerMenu(table|func menu)` - 登记需要添加到头像菜单的项目，
    该方法添加的为海鳗菜单的子项目，要添加顶层项目请用官方的 `Player_AppendAddonMenu()`。

    > 参数 *menu* -- 类型为`table`表示要加入的单个菜单项，类型为`function`则要求返回值是一个菜单项。

    ```lua
    HM.AppendPlayerMenu({ szOption = "Test1" }) -- 静态
    HM.AppendPlayerMenu(function() return { szOption = "Test2" } end) -- 动态
    ```

11. `(void) HM.Sysmsg(string szMsg[, string szHead])` - 在聊天栏输出一段黄字（只有当前用户可见）

    > 参数 *szMsg* -- 要输出的文字内容
	> 可选 *szHead* --  输出前缀，自动加上中括号，默认为：`海鳗插件`

12. `(void) HM.Debug(string szMsg[, string szHead])`
    `(void) HM.Debug2(string szMsg[, string szHead])`
    `(void) HM.Debug3(string szMsg[, string szHead])` - 输出调试信息，类似 `HM.Sysmsg`，但多了2个标记。

13.  `(void) HM.Alert(string szMsg, func fnAction[, string szSure])` - 在屏幕正中弹出带一行文本和一个确定按纽的警示框

	> 参数 *szMsg* -- 警示文字内容
	> 参数 *fnAction* -- 按下确认按纽后触发的回调函数
	> 可选 *szSure* -- 确认按纽的文字，默认值：`确定`

14. `(void) HM.Confirm(string szMsg, func fnAction, func fnCancel[, string szSure[, string szCancel]])` - 在屏幕中间弹出带两个按纽的确认框，并带有一行文本提示

	> 参数 *szMsg* -- 警示文字内容
	> 参数 *fnAction* -- 按下确认按纽后触发的回调函数
	> 参数 *fnCancel* -- 按下取消按纽后触发的回调函数
	> 可选 *szSure* -- 确认按纽的文字，默认：`确定`
	> 可选 *szCancel* -- 取消按纽的文字，默认：`取消`

15. `(void) HM.AddHotKey(string szName, string szTitle, func fnAction)` - 增加系统快捷键设置

    > 参数 *szName* -- 名称标识，默认会自动加上 HM_ 开头
    > 参数 *szTitle* -- 按键的中文描述
	> 参数 *fnAction* -- 按下后触发的回调函数

16. `(string) HM.GetHotKey(string szName[, boolean bBracket[, boolean bShort]])` - 取得快捷键名称

	> 参数 *szName* -- 名称标识，默认会自动加上 HM_ 开头
	> 可选 *bBracket* -- 是否加入小括号，形如：(`Ctrl-W)`
	> 可选 *bShort* -- 是否返回缩写，形如：`C-W` 代表 `Ctrl-W`

17. `(void) HM.SetHotKey([string szGroup])` - 打开快捷键设置面板

    > 可选 *szGroup* -- 要打开的分组名称，默认为 `HM.szTitle`

    ```lua
	HM.SetHotKey("界面开关")	-- 打开“界面开关“的快捷键设置
	```

18. `(void) HM.BreatheCall(string szKey, func fnAction[, number nTime])` - 注册呼吸循环调用函数

	> 参数 *szKey* -- 呼吸名称，必须唯一，重复则覆盖
	> 参数 *fnAction* -- 循环呼吸调用函数，设为 nil 则表示取消这个 key 下的呼吸处理函数
    > 可选 *nTime* -- 调用间隔，单位：毫秒，默认为 62.5，即每秒调用 16次，其值自动被处理成 62.5 的整数倍

19. `(void) HM.DelayCall(number nDelay, func fnAction)` - 延迟调用

	> 参数 *nTime* -- 延迟调用时间，单位：毫秒，实际调用延迟延迟是 62.5 的整倍数
    > 参数 *fnAction* -- 调用函数

20. `(void) HM.RemoteRequest(string szUrl, func fnAction)` - 发起远程 HTTP 请求

	> 参数 *szUrl* -- 请求的完整 URL（包含 http:// 或 https://）
    > 参数 *fnAction* -- 请求完成后的回调函数，回调原型：`function(szTitle)`

21. `(KObject) HM.GetTarget()` - 取得当前目标操作对象

22. `(KObject) HM.GetTarget([number dwType, ]number dwID)` - 根据 dwType 类型和 dwID 取得操作对象

	> 可选 *dwType* 目标类型，`TARGET.xxx`
	> 参数 *dwID* 目标的数字 ID

23. `(string) HM.GetTargetName(userdata KNpc/KPlayer)` - 根据目标对像显示其名字，支持宠物属主等

24. `(void) HM.Talk(string szTarget, string szText[, boolean bNoEmotion])`
    `(void) HM.Talk([number nChannel, ] string szText[, boolean bNoEmotion])` - 发布聊天

	> 参数 *szTarget* -- 密聊的目标角色名
	> 可选 *nChannel* -- 聊天频道，PLAYER_TALK_CHANNLE.xxx，默认为近聊
    > 参数 *szText* -- 聊天内容，（亦可为兼容 KPlayer.Talk 的 table）
    > 可选 *bNoEmotion* -- 不解析聊天内容中的表情图片，默认为 false
	> **特别注意** `nChannel`, `szText` 两者的参数顺序可以调换，团队频道在战场会智能切换为战场频道

	```lua
	HM.Talk("海鳗鳗", "你好啊！") -- 密聊 [海鳗鳗]
	HM.Talk("你好啊！")	-- 在近聊发布
	HM.Talk(PLAYER_TALK_CHANNEL.TONG, "你好啊！#玫瑰") -- 在帮会频道发布
	```

25. `(void) HM.BgTalk(string szTarget, ...)`
    `(void) HM.BgTalk(number nChannel, ...)` - 发布后台聊天通讯数据

    > 参数 *szTarget* -- 密聊的目标角色名
	> 参数 *nChannel*  -- 聊天频道，PLAYER_TALK_CHANNLE.xxx，默认为近聊
	> 参数 *...* -- 若干个字符串参数组成，可原样被接收到，此为通讯数据

26. `(table) HM.BgHear([string szKey])` - 读取后台聊天数据，在 `ADDON_BG_TALK`
    事件处理函数中使用才有意义

	> 可选 *szKey* -- 通讯类型，也就是 `HM.BgTalk` 的第一数据参数，若不匹配则忽略
	> 返回值：其余通讯数据组成的 table
    > **特别说明** arg0: dwTalkerID, arg1: nChannel, arg2: bEcho, arg3: szName

27. `(boolean) HM.IsDps([KPlayer tar])` - 检查玩家是否为 DPS 内功，省略判断则判断自身

28. `(boolean) HM.IsParty(number dwID)` - 根据玩家 ID 判断是否为队友

29. `(table) HM.GetAllPlayer([number nLimit])` - 获取场景内的所有玩家对象

	> 可选 *nLimit* -- 个数上限，默认不限

30. `(table) HM.GetAllNpc([number nLimit])` -- 获取场景内的所有 NPC对象

    > 可选 *nLimit* -- 个数上限，默认不限

32. `(number) HM.GetDistance(KObject tar)`
    `(number) HM.GetDistance(number nX, number nY[, number nZ])` -  计算目标与自身的距离

	> 参数 *tar* -- 带有 nX，nY，nZ 三属性的 table 或 KPlayer，KNpc，KDoodad
    > 参数 *nX* -- 世界坐标系下的目标点 X 值
    > 参数 *nY* -- 世界坐标系下的目标点 Y 值
    > 可选 *nZ* -- 世界坐标系下的目标点 Z 值
    > 返回值 -- 距离大小，单位是尺

	```lua
	local nDis = HM.GetDistance(GetTargetHandle(GetClientPlayer().GetTarget())) -- 计算当前目标距离
	```

33. `(number, number) HM.GetScreenPoint(KObject tar)`
    `(number, number) HM.GetScreenPoint(number nX, number nY, number nZ)` - 根据目标所在位置、
	世界坐标点计算在屏幕上的相应位置

    > 参数 *tar* -- 带有 nX，nY，nZ 三属性的 table 或 KPlayer，KNpc，KDoodad
    > 参数 *nX* -- 世界坐标系下的目标点 X 值
    > 参数 *nY* -- 世界坐标系下的目标点 Y 值
    > 可选 *nZ* -- 世界坐标系下的目标点 Z 值
    > 返回值 -- 屏幕坐标的 X，Y 值，转换失败返回 nil

34. `(number, number) HM.GetTopPoint(KObject tar[, number nH])`
    `(number, number) HM.GetTopPoint(number dwID[, number nH])` - 根据目标所在位置计算在屏幕上的头顶相应位置

	> 参数 *tar* -- 目标对象 KPlayer，KNpc，KDoodad
    > 参数 *dwID* -- 目标 ID
    > 可选 *nH* -- 高度，单位是：尺*64，默认对于 NPC/PLAYER 可智能计算头顶

35. `(table) HM.Split(string szFull, string szSep)` - 根据 szSep 分割字符串 szFull，不支持表达式，和官方的 `SplitString` 一样

36. `(string) HM.Trim(string szText)` - 清除字符串首尾的空白字符

37. `(string) HM.UrlEncode(string szText)` - 转换为 URL 编码，%xx%xx ...

38. `(string, number) HM.GetSkillName(number dwSkillID[, number dwLevel])` - 根据技能 ID 及等级获取技能的名称及图标 ID（内置缓存处理）

39. `(string, number) HM.GetBuffName(number dwBuffID[, number dwLevel])` - 根据Buff ID 及等级获取 BUFF 的名称及图标 ID（内置缓存处理）

40. `(void) HM.RegisterEvent(string szEvent, func fnAction)` - 注册事件，和系统的区别在于可以指定一个 KEY 防止多次加载

	> 参数 *szEvent* -- 事件，可在后面加一个点并紧跟一个标识字符串用于防止重复或取消绑定，如 LOADING_END.xxx
    > 参数 *fnAction* -- 事件处理 arg0 ~ arg9，传入 nil 相当于取消该事件
    > **特别注意** 当 `fnAction` 为 nil 时会取消所有通过本函数注册的事件处理器

41. `(void) HM.UnRegisterEvent(string szEvent)` - 取消事件处理函数

42. `(bool) HM.CanUseSkill(number dwSkillID)` - 根据技能 ID 判断当前用户是否可用某个技能，可以返回 true 否则 false

43. `(class) HM.HandlePool(userdata handle, string szXml)` - 创建容器元件缓存池（略）

44. `(void) HM.RegisterCustomUpdater(func fnAction, number nUpdateDate)` - Role Custom Data 加载后判断比较 nUpdateDate 然后调用 fnAction


添加插件设置项
---------------

1. 往海鳗插件设置面板中添加一个设置按纽可以通过下面的函数很容易的完成，请看原型：
   ```
   (void) HM.RegisterPanel(string szTitle, number dwIcon, string szClass, table fn)
   ```
   > 参数 *szTitle* -- 插件名称
   > 参数 *dwIcon* -- 插件图标 ID
   > 参数 *szClass* -- 分类名称，设为 nil 代表常用
   > 参数 *fn* -- 处理函数集合 (table)
   > ```lua
   > local fn = {
   >   OnPanelActive = (void) function(WndWindow frame),   -- 设置面板激活时调用，参数为设置画面的窗体对象
   >   OnPanelDeactive = (void) function(WndWindow frame), -- *可选* 设置面板被切出时调用，参数同上
   >   OnConflictCheck = (void) function(),                -- *可选* 插件冲突检测函数（每次上线后调用一次）
   >   OnPlayerMenu = (table) function(),                  -- *可选* 返回附加的头像菜单列表，多项
   >   GetAuthorInfo = (string) function(),                -- *可选* 返回该插件的作者、版权信息
   > }
   > ```

2. 如果你想修改已注册海鳗设置面板中的处理函数，可以用下面函数区取函数集：
   ```lua
   (table) HM.GetPanelFunc(szTitle)	-- 参数 szTitle 是插件名称
   ```
   这相当于得到已注册的 fn 参数，然后可以对其进行 HOOK 处理，用于实现插件补丁。


海鳗的 UI 封装
---------------

根据在制作设置面板时的需求，为了简化操作针对常用的 UI 元件进行了对象封装处理，参照了 jQuery 的思路，
对 setter/getter 进行了函数名称合并处理，带参数的调用表示设置，不带参数时则表示取值，并且每个设置
函数都返回对象自身，以便实现串接。

先看下面一个简单例子，在用户头像下方添加一个按纽，点击后在聊在窗显示一段文字，是不是很简单呢？

```lua
HM.UI(Player_GetFrame()):Append("WndButton", {x=50,y=100,txt="按我试试"}):Click(function() HM.Sysmsg("您好，测试") end)
```

** 小提示** 为测试方便可以将此段代码前加上 /script 拷入聊天窗口执行即可！！


### 将现有对象中提取 UI 封装对象 ###

1.  `HM.UI.Fetch(userdata hRaw)` - 将一个原始 UI 对象转换为 HM.UI 封装对象，支持各种 WndXXX 和 容器组件

2.  `HM.UI.Fetch(userdata hParent, szName)` - 从原始对象 *hParent* 中提取名为 *szName* 的子元件并转换为 `HM.UI` 对象

3.  `HM.UI(...)` - 通过元表戏法，可以用 HM.UI() 来代替 HM.UI.Fetch() 函数，返回通用的  HM.UI 对象，
    可直接调用封装方法，失败或出错返回 nil


### 打开空白对话窗体，并返回 HM.UI 封装对象 ###

```
HM.UI.OpenFrame([[string szName, ]table tArg])
```

> 可选 *szName* -- 窗口唯一名称，若省略则自动编序号，同名重复调用会先关闭存在的
> 可选 *tArg* -- 初始化配置参数，自动调用相应的封装方法，所有属性均可选
> ```lua
> local tArg = {
>     w = 234, h = 200,   -- 宽和高，成对出现用于指定大小，注意宽度会自动被就近调节为：770/380/234，高度最小 200
>     x = 0, y = 0,       -- 位置坐标，默认在屏幕正中间
>     title = "无标题",   -- 窗体标题
>     drag = true,        -- 设置窗体是否可拖动，true/false
>     close = false,      -- 点击关闭按纽是是否真正关闭窗体（若为 false 则是隐藏方便复用）
>     empty = false,      -- 创建空窗体，不带背景，全透明，只是界面需求，默认为 false
>     fnCreate = function(frame) end,	    -- 打开窗体后的初始化函数，frame 为内容窗体，在此设计 UI
>     fnDestroy = function(frame) end,    -- 关闭销毁窗体时调用，frame 为内容窗体，可在此清理变量
> }
> ```

### 往父窗体/容器添加 INI 配置文件，并返回 HM.UI 封装对象 ###

```
HM.UI.Append(userdata hParent, string szIniFile, string szTag, string szName)
```

> 参数 *hParent* -- 父窗体或容器原始对象（HM.UI 对象请直接用  :Append 方法）
> 参数 *szIniFile* --  INI 文件路径
> 参数 *szTag* -- 要添加的对象源，即中括号内的部分 [XXXX]，请与 hParent 匹配采用 Wnd 或容器组件
> 可选）*szName* -- 对象名称，若不指定则沿用原名称
> 返回值：通用的  HM.UI 对象，可直接调用封装方法，失败或出错返回 nil


### 往父窗体/容器添加 UI 元件，并返回 HM.UI 封装对象 ###

```
HM.UI.Append(userdata hParent, string szType[, string szName], table tArg)
```

> 参数 *hParent* -- 父窗体或容器原始对象（HM.UI 对象请直接用  :Append 方法）
> 参数 *szType* -- 要添加的组件类型（如：WndWindow，WndEdit，Handle，Text ……）
> 可选 *szName* -- 元件名称，若省略则自动编序号
> 可选 *tArg* -- 初始化配置参数，自动调用相应的封装方法，所有属性均可选
> ```lua
> local tArg = {
>     w = 100, h = 100,       -- 宽和高，成对出现用于指定大小
>     x = 0, y = 0,           -- 位置坐标，成对出现
>
>     txt = "",               -- 文本内容
>     font = 27,              -- 文本字体
>     multi = false,          -- 是否多行文本，true/false
>     limit = 1024,           -- 文字长度限制
>     align = 0,              -- 对齐方式（0：左，1：中，2：右）
>
>     color = {255,255,255},	-- 颜色 { nR, nG, nB }
>     alpha = 100,            -- 不透明度，0 - 255
>     checked	= false,        -- 是否勾选，WndCheckBox/WndRadioBox/WndTabBox 专用
>     enable = true,          -- 是否启用，默认 true
>
>     file = "", icon = 1, type = 0,  -- 图片文件地址，图标编号，类型
>     group = nil,                    -- 单选框分组设置，参见 checked
> }
> ```
> 返回值 -- 通用的  HM.UI 对象，可直接调用封装方法，失败或出错返回 nil


### HM.UI 封装的元件类型列表 ###

UI 元件类型，也就是 HM.UI.Append 中 szType 参数的值，目前已封装的包含：

1.  **窗体级对象*** 这类对象只能作为 `WndFrame` 或 `WndWindow` 对象的子元件
    - `WndActionWindow` 带事件支持的虚窗口
    - `WndWindow`       伪虚窗口
    - `WndButton`       按纽
    - `WndCheckBox`     方形复选框
    - `WndRadioBox`     圆形复选项
    - `WndTabBox`       按纽复选框
    - `WndComboBox`     下拉菜单选择器
    - `WndEdit`         编辑框
    - `WndTrackBar`     水平滑动条
    - `WndWebPage`      嵌入网页

2.  容器元件，这类对象只能作为 `Handle` 容器的子元件
    - `Handle2`         容器，类型为 Handle
    - `Box`             盒子类型
    - `BoxButton`       带图标的按纽
    - `TxtButton`       文字按纽
    - `Text`            文字
    - `Label`           符号标识，和 Text 类型，但多一层容器
    - `Shadow`          阴影绘制
    - `Image`           图片

### HM.UI 封装的对象方法列表 ###

所有的封装方法通过类似下面的方式调用，设置类的方法均可以串接调用，以下为示范代码：

```lua
-- 在头像窗体上添加一个文字组件
local ui = HM.UI(Player_GetFrame()):Append("Text")
ui:Pos(10, 100):Text("text2"):Color(255, 0, 0)

-- 获取文字内容
local szText = ui:Text()
```

1. 通用方法接口，适合各种类型的元件。
   - `ui:Raw()` 返回 userdata 原始对象
   - `ui:Remove()` 删除当前对象
   - `ui:Name([szName])` 获取/设置元件名称
   - `ui:Toggle([bShow])` 切换/显示/隐藏元件
   - `ui:Size([nW, nH])` 获取/设置元件大小
   - `ui:Pos([nX, nY])` 获取/设置元件位置
   - `ui:Pos_()` 获取元件的右下角坐标位置

   - `ui:CPos_()` 获取容器或窗体的最后一个元素的右下角坐标，只支持 Handle/WndFrame
   - `ui:Append(szType, ...)` 在当前元件下添加子元件，只支持 Handle/WndFrame，参见 HM.UI.Append()
   - `ui:Fetch(szName)` 根据名称获取当前元件的子元件，只支持 Handle/WndFrame，参见 HM.UI.Fetch()

   - `ui:Align([nHAlign[, nVAlign]])` 获取/设置元件中的文字对齐方式，参数为分别为水平和垂直方向的对齐
   - `ui:Font([nFont])` 获取/设置文字字体
   - `ui:Color([nR, nG, nB])` 获取/设置元件颜色
   - `ui:Alpha([nAlpha])` 获取/设置元件的不透明度

2. WndFrame 特有方法，HM.UI.OpenFrame() 的返回值
   - `ui:Size([nW, nH])` 获取/设置窗口大小，最小高度 200，宽度自动按接近取 234/380/770
   - `ui:Title[szTitle])` 获取/设置窗口标题
   - `ui:Drag([bEnable])` 获取/设置是窗口是否能拖动
   - `ui:Relation(szName)` 改变窗口的父对象，名称如：Normal/Topmost/Lowest ...
   - `ui:Lookup(...)` 在窗口原始对象中检索子元件

3. WndXXX 的窗体对象专用方法
   - `ui:Enable([bEnable])` 获取/设置窗口是否可用（禁用后会是灰色）
   - `ui:AutoSize([hPad, vPad])` 自动调整某些元件的宽和高（只支持 WndTabBox/WndButton/WndComboBox），参数为填充距离
   - `ui:Check([bCheck])` 判断是否选中/选中、取消复选框（只支持 WndTabBox/WndRadioBox/WndCheckBox）
   - `ui:Group([szName])` 获取/设置复选框的分组名称，同组的选框只有一个能被选中（只支持 WndTabBox/WndRadioBox/WndCheckBox）
   - `ui:Url([szUrl])` 获取/设置 WndWebPage 元件的当前网址
   - `ui:Range([nMin, nMax[, nStep])` 获取/设置 WndTracBar 的最小值，最大值，步数，默认为 0,100,100
   - `ui:Value([nVal])` 获取/设置 WndTracBar 的当前值
   - `ui:Text([szText])` 获取/设置文本的内容
   -` ui:Mutli([bEnable])` 获取/设置文本是否为多行
   - `ui:Limit([nLimit])` 获取/设置文本长度上限

   - `ui:Change([func fnAction])` 执行/设置 WndEdit/WndTrackBar 发生改变时的事件函数
   - `ui:Menu((table|func)` menu)` 设置 WndComboBox 的下拉菜单，参数可以是菜单或是返回菜单的函数
   - `ui:Click([fnAction])` 执行/设置元件在鼠标左键点击时的回调函数
   - `ui:Hover(fnEnter[, fnLeave])` 设置元件在鼠标进出时的处理函数，fnLeave 为可选函数，若省略则使用 fnEnter，
     进入函数传入 true 作为参数，离开函数则传入 false 为参数。

4. 容器组件的专用方法
   - `ui:Zoom(bEnable)` 设置 BoxButton 是否在点击后适当放大，值为 true/false
   - `ui:Text([szText])` 获取/设置文本的内容
   - `ui:Mutli([bEnable])` 获取/设置文本是否为多行
   - `ui:File(szFile[, nFrame])` 设置 Image 元件的图片路径及帧数，帧数可以省略直接使用 TGA 图片
   - `ui:Icon([dwIcon])` 设置 Image 或 BoxButton 或 Box 元件的图标 ID
   - `ui:Type([nType])` 获取/设置 Image 类型，BoxButton 的背景图片类型（1,2,3三种）

   - `ui:Click([fnAction])` 执行/设置元件在鼠标左键点击时的回调函数
   - `ui:Hover(fnEnter[, fnLeave])` 设置元件在鼠标进出时的处理函数，fnLeave 为可选函数，若省略则使用 fnEnter
   进入函数传入 true 作为参数，离开函数则传入 false 为参数。


简单的示范代码
---------------

API 说明已经写完了，至此大家应该还是会比较迷糊，在此以列出所有系统图标为例子写个范围。
系统图标 ID 大约从 1 - 3481，下面为测试代码讲解。

1. 先在 interface 目录下创建一个 HM_ListIcon 目录

2. 在 HM_ListIcon 目录下创建 info.ini 内容如下，这是插件开发的基础不过多解释。
```ini
[HM_ListIcon]
name=海鳗、系统图标列表
desc=列出系统所有图标 -- by 海鳗测试
version=0.8
default=1
lua_0=interface\HM_ListIcon\HM_ListIcon.lua
```

3. 在 HM_ListIcon 目录下创建 HM_ListIcon.lua 作为代码主文件，代码内容及注释如下：

<pre>
-- 全局变量表
HM_ListIcon = {
    szTitle = "系统图标列表",
}

-- 本地变量表
local _HM_ListIcon = {
    nCur = 0,            -- 图标 ID 最小值
    nMax = 3481,    -- 图标 ID 最大值
}

-- 获取返回作者信息
_HM_ListIcon.GetAuthorInfo = function()
    return "海鳗鳗@电信二区荻花宫 (v1.0b)"
end

-- 加的头像菜单列表
_HM_ListIcon.OnPlayerMenu = function()
    -- 菜单中点击后直接打开设置面板
    return { szOption = "查看系统图标", fnAction = function() HM.OpenPanel(HM_ListIcon.szTitle) end }
end

-- 冲突检测函数，首次上线时执行
_HM_ListIcon.OnConflictCheck = function()
    HM.Sysmsg("执行 HM_ListIcon 冲突检测函数 ……")
end

-- 设置界面初始化函数
_HM_ListIcon.OnPanelActive = function(frame)
    -- 将设置面板窗体转换为 封装好的 HM.UI 对象
    local ui = HM.UI(frame)
    local imgs, txts = {}, {}

    -- 在界面中添加黄色的标题文字，字体为 27 号
    ui:Append("Text", { txt = "系统图标大全", x = 0, y = 0, font = 27 })

    -- 将外观设计为 每页 40个，每页 4行，每行 10个 图标
    for i = 1, 40 do
        local x = ((i - 1) % 10) * 50
        local y = math.floor((i - 1) / 10) * 70 + 40
        -- 添加一个 48x48 的图片
        imgs[i] = ui:Append("Image", { w = 48, h = 48, x = x, y = y})
        -- 在图片下方添加 48x20 的文字，居中对齐
        txts[i] = ui:Append("Text", { w = 48, h = 20, x = x, y = y + 48, align = 1 })
    end

    -- 在下方添加 2 个按纽
    local btn1 = ui:Append("WndButton", { txt = "上一页", x = 0, y = 320 })
    local nX, _ = btn1:Pos_()
    local btn2 = ui:Append("WndButton", { txt = "下一页", x = nX, y = 320 })
    -- 设置上一页的点击处理函数
    btn1:Click(function()
        _HM_ListIcon.nCur = _HM_ListIcon.nCur - #imgs
        if _HM_ListIcon.nCur <= 0 then
            _HM_ListIcon.nCur = 0
            -- 已经是第一页，将按纽设为不可点击
            btn1:Enable(false)
        end
        -- 下一页肯定要设为可以点击
        btn2:Enable(true)
        -- 刷新图片和文字的内容
        for k, v in ipairs(imgs) do
            local i = _HM_ListIcon.nCur + k - 1
            if i > _HM_ListIcon.nMax then
                break
            end
            imgs[k]:Icon(i)
            txts[k]:Text(tostring(i))
        end
    end):Click()
    -- 设置下一页按纽的处理函数
    btn2:Click(function()
        _HM_ListIcon.nCur = _HM_ListIcon.nCur + #imgs
        if (_HM_ListIcon.nCur + #imgs) >= _HM_ListIcon.nMax then
            -- 已经最后一页，将按纽设为不可点击
            btn2:Enable(false)
        end
        -- 上一页肯定要设为可以点击
        btn1:Enable(true)
        -- 刷新图片和文字的内容
        for k, v in ipairs(imgs) do
            local i = _HM_ListIcon.nCur + k - 1
            if i > _HM_ListIcon.nMax then
                break
            end
            imgs[k]:Icon(i)
            txts[k]:Text(tostring(i))
        end
    end)
end

-- 把设置界面添加到海鳗插件集，分类为“开发”，图标 ID：591，函数集合在 _HM_ListIcon
HM.RegisterPanel(HM_ListIcon.szTitle, 591, "开发", _HM_ListIcon)
</pre>

4. 小退进游戏看看就明白了~_~


后语
----

至此，HM 插件的 API 说明写完了。总体上目前插件作者并不多，大部分也已有自己的开发函数库，
我写这个主要还是为了自己记录和一直以来的一个小心愿。

不过还是很欢迎和乐意见到大家把自己开发的插件添加到海鳗设置面板中统一管理。^o^

2012/7/17 - by HM


