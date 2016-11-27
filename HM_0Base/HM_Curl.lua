--
--  CURL wrapper in jQuery-style
-- @Author webster-jx3
-- @Modifier hightman
--
local tRequest = {}
local nReqestIndex = 1
local Curl = {}

local tDefaultOption = {
	charset = "utf8",
	type = "get",
	data = {},
	dataType = "text",
	timeout = 3,
	done = function(res, opt)
		HM.Sysmsg("success - " .. opt.url, "HM_Curl")
	end,
	fail = function(res, opt)
		HM.Sysmsg("error - " .. opt.url, "HM_Curl")
	end,
	always = function(res, opt)
		HM.Sysmsg("completed - " .. opt.url, "HM_Curl")
	end,
}

local function ConvertToUTF8(data)
	if type(data) == "table" then
		local t = {}
		for k, v in pairs(data) do
			if type(k) == "string" then
				t[ConvertToUTF8(k)] = ConvertToUTF8(v)
			else
				t[k] = ConvertToUTF8(v)
			end
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

function Curl:ctor(option)
	assert(option and option.url)
	setmetatable(option, { __index = tDefaultOption })
	
	local szKey = "HM_Curl_" .. nReqestIndex
	tRequest[szKey] = option
	nReqestIndex = nReqestIndex + 1
	
	local url, data = option.url, option.data
	local bSSL = url:sub(1, 6) == "https:"
	
	if option.charset:lower() == "utf8" then
		url  = ConvertToUTF8(url)
		data = ConvertToUTF8(data)
	end
	if option.type:lower() == "post" then
		CURL_HttpPost(szKey, url, data, bSSL, option.timeout)
	else
		data = EncodePostData(data)
		if not url:find("?") then
			url = url .. "?"
		elseif url:sub(-1) ~= "&" then
			url = url .. "&"
		end
		CURL_HttpRqst(szKey, url .. data,  bSSL, option.timeout)
	end
	
	local t = setmetatable({}, { __index = Curl })
	t.szKey = szKey
	return t
end

function Curl:done(func)
	local option = tRequest[self.szKey]
	if option then
		option.done = func
	end
	return self
end

function Curl:fail(func)
	local option = tRequest[self.szKey]
	if option then
		option.fail = func
	end
	return self
end

function Curl:always(func)
	local option = tRequest[self.szKey]
	if option then
		option.always = func
	end
	return self
end

-- arg0=szKey, arg1=bSuccess, arg2=szContent, arg3=dwBufferSize
HM.RegisterEvent("CURL_REQUEST_RESULT.curl", function()
	local szKey, bSuccess, szContent = arg0, arg1, arg2
	local option = tRequest[szKey]
	if not option then
		return
	end
	tRequest[szKey] = nil
	-- json
	if option.dataType == "json" then
		local data, err = HM.JsonDecode(szContent)
		if data == nil then
			bSuccess = false
			HM.Debug("CURL#JsonDecode ERROR: " .. err)
		else
			szContent = data
		end
	end
	-- always
	local res, err = pcall(option.always, szContent, option)
	if not res then
		HM.Debug("CURL#always(" .. option.url .. ") ERROR: " .. err)
	end
	-- done & fail
	if bSuccess then
		local res, err = pcall(option.done, szContent, option)
		if not res then
			HM.Debug("CURL#done(" .. option.url .. ") ERROR: " .. err)
		end
	else
		local res, err = pcall(option.fail, szContent, option)
		if not res then
			HM.Debug("CURL#fail(" .. option.url .. ") ERROR: " .. err)
		end
	end
end)

--
-- HM API
--
HM.Curl = setmetatable({}, {
	__call = function(me, ...) return Curl:ctor(...) end,
	__newindex = function() end,
	__metatable = true,
})

-- (cURL) HM.Get(szUrl)
HM.Get = function(szUrl) return HM.Curl({url = szUrl}) end

-- (cURL) HM.Post(szUrl, data)
HM.Post = function() return HM_Curl({url = szUrl, data = data or {}, type = "post"}) end

-- (cURL) HM.GetJson(szUrl)
HM.GetJson = function(szUrl) return HM.Curl({url = szUrl, dataType = "json"}) end

-- (cURL) HM.PostJson(szUrl, data)
HM.PostJson = function() return HM_Curl({url = szUrl, data = data or {}, type = "post", dataType = "json"}) end
