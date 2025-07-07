local json = require('cjson')
local cURL = require("cURL")
local log = require('utils.log')
local url = require('utils.url')
local config = require('config.realty')
local array = require('utils.array')
local md5 = require('md5')

local _M = {}
_M.result = nil
log.outfile = 'logs/realty_'..os.date('%Y-%m-%d')..'.log' 
log.level = 'trace'	
_M.base = config.url
_M.apartments = {} 
_M.bookings = {}

local function sign(data)
	return md5.sumhexa(array.traverse(data)..config.private_key)
end

local function get_result(str,url,full)
	local result, err = pcall(json.decode,str)
	if result then
		_M.result = json.decode(str)
	else
		log.error(url..':'..err)
		return nil,	err
	end	
	if _M.result.result then 
		if full then return _M.result else return _M.result.result end
	end
	log.error(url..str)
	return nil
end

function _M.post(url,data,full)
	local str = ''
	url = _M.base..url
	local headers = {
		'Content-Type: application/json',
		'Accept: application/json'
	}
	local c = cURL.easy{		
		url = url,
		post = true,
		postfields = json.encode(data),  
		httpheader = headers,
		writefunction = function(st)		
			str = str..st
		end
	}
	local ok, err = c:perform()	
	local code = c:getinfo_response_code()
	c:close()
	if not ok then return nil, err end
	if code ~= 200 then 
		log.error(url..':'..str)
		return nil,str 
	end
	res,err = get_result(str,url,full)
	if not res then return nil,err end
	return res
end

function put(url,data)
	local str = ''
	url = _M.base..url
	local headers = {
		'Content-Type: application/json',
		'Accept: application/json',
	}
	local c = cURL.easy{		
		url = url,
		put = true,
		postfields =  json.encode(data),  
		httpheader  = headers,
		writefunction = function(st)		
			str = str..st
		end
	}
	local ok, err = c:perform()	
	local code = c:getinfo_response_code()
	c:close()
	if not ok then return nil, err end
	if code ~= 200 then 
		log.error(url..':'..str)
		return nil,str 
	end
	res,err = get_result(str,url,full)
	if not res then return nil,err end
	return res
end


function delete(url)
	local str = ''
	url = _M.base..url
	local headers = {
		'Content-Type: application/json',
		'Accept: application/json',
	}
	local c = cURL.easy{		
		url = url,
		httpheader  = headers,
		customrequest = 'DELETE',
		writefunction = function(st)		
			str = str..st
		end
	}
	local ok, err = c:perform()	
	local code = c:getinfo_response_code()
	c:close()
	if not ok then return nil, err end
	if code ~= 200 then 
		log.error(url..':'..str)
		return nil,str 
	end
	res,err = get_result(str,url,full)
	if not res then return nil,err end
	return res
end


--[[ 
	Items
--]]



return _M
