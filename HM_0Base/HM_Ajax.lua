--
--  cUrl wrapper in jQuery-style
-- @Author webster-jx3
-- @Modifier hightman
--
local CLIENT_LANG = select(3, GetVersion())
local nSerial = 1		-- 请求流水号
local tRequest = {}	-- 请求回调映射表
local tDefaultOption = {
	charset = "utf8",
	type = "get",
	data = {},
	dataType = "text",
	timeout = 3,
	done = function(res, opt)
		HM.Debug("success - " .. opt.url, "HM_Ajax_" .. opt.type:upper())
		end,
	fail = function(res, opt)
		HM.Debug(" error - " .. opt.url, "HM_Ajax_" .. opt.type:upper())
	end,
	always = function(res, opt)
		HM.Debug("completed - " .. opt.url, "HM_Ajax_" .. opt.type:upper())
	end,
}

local function ConvertToUTF8(data)
	if type(data) == "table" then
		local t = {}
		for k, v in pairs(data) do
			if type(k) == "string" then
				k = AnsiToUTF8(k)
			end
			t[k] = ConvertToUTF8(v)
		end
		return t
	elseif type(data) == "string" then
		return AnsiToUTF8(data)
	else
		return data
	end
end

local function EncodePostData(data, prefix)
	if type(data) ~= "table" then
		return data .. ""
	end
	local t = {}
	for k, v in pairs(data) do
		if prefix then
			k = prefix .. "[" .. k .. "]"
		end
		if type(v) == "table" then
			table.insert(t, EncodePostData(v, k))
		else
			table.insert(t, UrlEncode(k) .. "=" .. UrlEncode(v))
		end
	end
	return table.concat(t, "&")
end

local cUrl = {}
function cUrl:ctor(option)
	assert(option and option.url)
	setmetatable(option, { __index = tDefaultOption })
	
	local szKey = "HM_Ajax_" .. nSerial
	tRequest[szKey] = option
	nSerial = nSerial + 1
	
	local url, data = option.url, option.data or {}
	local bSSL = url:sub(1, 6) == "https:"
	if option.charset:lower() == "utf8" and CLIENT_LANG == "zhcn" then
		url  = ConvertToUTF8(url)
		data = ConvertToUTF8(data)
	end
	
	if option.type:lower() == "post" then
		CURL_HttpPost(szKey, url, data, bSSL, option.timeout)
	else
		data = EncodePostData(data)
		if data == "" then
		elseif not url:find("?") then
			url = url .. "?"
		elseif url:sub(-1) ~= "&" then
			url = url .. "&"
		end
		CURL_HttpRqst(szKey, url .. data,  bSSL, option.timeout)
	end

	local inst = setmetatable({}, { __index = cUrl })
	inst.szKey = szKey
	return inst
end

function cUrl:done(func)
	local option = tRequest[self.szKey]
	if option then
		option.done = func
	end
	return self
end

function cUrl:fail(func)
	local option = tRequest[self.szKey]
	if option then
		option.fail = func
	end
	return self
end

function cUrl:always(func)
	local option = tRequest[self.szKey]
	if option then
		option.always = func
	end
	return self
end

-- arg0=szKey, arg1=bSuccess, arg2=szContent, arg3=dwBufferSize
HM.RegisterEvent("CURL_REQUEST_RESULT", function()
	local szKey, bSuccess, szContent = arg0, arg1, arg2
	local option = tRequest[szKey]
	if not option then
		return
	end
	tRequest[szKey] = nil
	-- utf8 decode
	if option.charset:lower() == "utf8" and CLIENT_LANG == "zhcn" then
		szContent = UTF8ToAnsi(szContent)
	end
	-- json
	if option.dataType == "json" then
		local data, err = HM.JsonDecode(szContent)
		if data == nil then
			bSuccess = false
			HM.Debug("cUrl#JsonDecode ERROR: " .. err)
		else
			szContent = data
		end
	end
	-- always
	local res, err = pcall(option.always, szContent, option)
	if not res then
		HM.Debug("cUrl#always(" .. option.url .. ") ERROR: " .. err)
	end
	-- done & fail
	if bSuccess then
		local res, err = pcall(option.done, szContent, option)
		if not res then
			HM.Debug("cUrl#done(" .. option.url .. ") ERROR: " .. err)
		end
	else
		local res, err = pcall(option.fail, szContent, option)
		if not res then
			HM.Debug("cUrl#fail(" .. option.url .. ") ERROR: " .. err)
		end
	end
end)

--
-- Public API
--
HM.Ajax = setmetatable({}, {
	__call = function(me, ...) return cUrl:ctor(...) end,
	__newindex = function() end,
	__metatable = true,
})

-- (cUrl) HM.Get(szUrl[, data])
HM.Get = function(szUrl, data) return HM.Ajax({url = szUrl, data = data}) end

-- (cUrl) HM.Post(szUrl[, data])
HM.Post = function(szUrl, data) return HM.Ajax({url = szUrl, data = data, type = "post"}) end

-- (cUrl) HM.GetJson(szUrl[, data])
HM.GetJson = function(szUrl, data) return HM.Ajax({url = szUrl, data = data, dataType = "json"}) end

-- (cUrl) HM.PostJson(szUrl[, data])
HM.PostJson = function(szUrl, data) return HM.Ajax({url = szUrl, data = data, type = "post", dataType = "json"}) end
