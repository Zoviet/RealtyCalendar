local json = require('cjson')
local cURL = require("cURL")
local log = require('utils.log')
local url = require('utils.url')
local config = require('config.realty')
local array = require('utils.array')
local md5 = require('md5')
local date = require('date')

local _M = {}
_M.result = nil
log.outfile = 'logs/realty_'..os.date('%Y-%m-%d')..'.log' 
log.level = 'trace'	
_M.base = config.url
_M.apartments = {} 
_M.bookings = {}

local error = {
	NO_BEGIN_DATE = {code = 400, error = 'Не указана дата начала брони(ей)'},
	NO_END_DATE = {code = 400, error = 'Не указана дата конца брони(ей)'},
	BAD_END_DATE = {code = 400, error = 'Неверная дата конца выборки броней: не может быть позднее завтрашнего дня'},
	NO_ID = {code = 400, error = 'Не указан ID аппартаментов или брони'},
	NO_STATUS = {code = 400, error = 'Не указан статус брони'},
	BAD_STATUS = {code = 400, error = 'Неверный статус брони. Допустимы: 4 - подана заявка, 5 - забронировано'},
	BAD_ATTRIBUTES = {code = 400, error = 'Атрибуты пользователя должны быть массивом'},
}

local function sign(data)
	return md5.sumhexa(array.traverse(data)..config.private_key)
end

local function request(data)
	if data.event_calendar then data.sign = sign(data.event_calendar)
	else data.sign = sign(data) end
	return json.encode(data)
end

local function get_result(str,url)
	local result, err = pcall(json.decode,str)
	if result then
		_M.result = json.decode(str)
	else
		log.error(url..':'..err)
		return nil,	err
	end	
	return _M.result
end

function post(url,data)
	local str = ''
	url = _M.base..url
	local headers = {
		'Content-Type: application/json',
		'Accept: application/json'
	}
	local c = cURL.easy{		
		url = url,
		post = true,
		postfields = request(data),  
		httpheader = headers,
		writefunction = function(st)
			str = str..st
		end
	}
	local ok, err = c:perform()	
	local code = c:getinfo_response_code()
	c:close()
	if not ok then return nil, err end
	if code > 201 then 
		log.error(url..':'..str)
		return nil,str 
	end
	res,err = get_result(str,url)
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
		customrequest = 'PUT',
		postfields = request(data),
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
	res,err = get_result(str,url)
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
	if code ~= 204 then 
		log.error(url..':'..str)
		return nil,str 
	end
	return true
end

--[[ 
	Bookings
--]]

--[[

begin_date - обязательный параметр, дата изменения брони в формате “yyyy-mm-dd”, с которой нужно начать поиск.;
end_date - обязательный параметр, дата изменения брони в формате “yyyy-mm-dd”, по которую нужно произвести поиск. Не может быть больше завтрашнего дня по Москве;
event_begin_date_start - необязательный параметр, дата заезда быть больше чем это значение
event_begin_date_end - необязательный параметр, дата заезда должна быть меньше чем это значение
event_end_date_start - необязательный параметр, дата выезда должна быть больше чем это значение
event_end_date_end - необязательный параметр, дата выезда должна быть меньше чем это значение

--]]

function _M.bookings.get(begin_date,end_date,event_begin_date_start,event_begin_date_end,event_end_date_start,event_end_date_end)
	local data = {}
	if not begin_date then return nil, error.NO_BEGIN_DATE end
	data.begin_date = date(begin_date):fmt('%Y-%m-%d')
	if not end_date then 
		data.end_date = date():adddays(1):fmt('%Y-%m-%d') 
	else
	    end_date = date(end_date)
	    if date.diff(end_date,date(false):addhours(3):adddays(1)):spandays()>1 then return nil, error.BAD_END_DATE end   
		data.end_date = end_date:fmt('%Y-%m-%d')
	end
	if event_begin_date_start then data.event_begin_date_start = date(event_begin_date_start):fmt('%Y-%m-%d') end
	if event_begin_date_end then data.event_begin_date_end = date(event_begin_date_end):fmt('%Y-%m-%d') end
	if event_end_date_start then data.event_end_date_start = date(event_end_date_start):fmt('%Y-%m-%d') end
	if event_end_date_end then data.event_end_date_end = date(event_end_date_end):fmt('%Y-%m-%d') end
	return post('bookings/'..config.public_key,data)
end

--[[
begin_date - обязательный параметр, дата начала события;
end_date - обязательный параметр, дата окончания события; 
status - обязательный параметр, статус события, принимает одно из значенией 4 - подана заявка, 5 - забронировано;
amount - сумма оплаты;
notes - примечание;
client_attributes - данный о клиенте с полями:
	fio - Фамилия Имя Отчество клиента;
	phone -  телефон клиента;
	additional_phone - дополнительный телефон клиента;
	email - электронная почта клиента;
apartment_id - номер квартиры(лот), для которой нужно создать событие.
--]]

function _M.bookings.add(apartment_id,begin_date,end_date,status,amount,notes,client_attributes)
	local data = {}
	data.event_calendar = {}
	if not apartment_id then return nil, error.NO_ID end
	if not begin_date then return nil, error.NO_BEGIN_DATE else data.event_calendar.begin_date = date(begin_date):fmt('%Y-%m-%d %T') end
	if not end_date then return nil, error.NO_END_DATE else data.event_calendar.end_date = date(end_date):fmt('%Y-%m-%d %T') end
	if not status then return nil, error.NO_STATUS else data.event_calendar.status = tonumber(status) end
	if amount then data.event_calendar.amount = tonumber(amount) end
	if not(data.event_calendar.status==4 or data.event_calendar.status==5) then return nil, error.BAD_STATUS end
	if notes then data.notes = tostring(notes) end
	if client_attributes and type(client_attributes) ~= 'table' then return nil, error.BAD_ATTRIBUTES else data.event_calendar.client_attributes = client_attributes end	
	return post('apartments/'..apartment_id..'/event_calendars',data)
end

--[[
begin_date - обязательный параметр, дата начала события;
end_date - обязательный параметр, дата окончания события;
status - обязательный параметр, статус события, принимает одно из значенией 4 - подана заявка, 5 - забронировано;
amount - сумма оплаты;
notes - примечание;
apartment_id - идентификатор квартиры, для перемещения события на другой объект
client_attributes - данные о клиенте с полями:
	fio - Фамилия Имя Отчество клиента;
	phone - телефон клиента;
	additional_phone - дополнительный телефон клиента;
	email - электронная почта клиента;
APARTMENT_ID - номер квартиры(лот), на которой находится событие
ID - идентификатор события (брони)
--]]

function _M.bookings.edit(apartment_id,id,begin_date,end_date,status,amount,notes,client_attributes)
	local data = {}
	data.event_calendar = {}
	if not apartment_id or not id then return nil, error.NO_ID end
	if not begin_date then return nil, error.NO_BEGIN_DATE else data.event_calendar.begin_date = date(begin_date):fmt('%Y-%m-%d %T') end
	if not end_date then return nil, error.NO_END_DATE else data.event_calendar.end_date = date(end_date):fmt('%Y-%m-%d %T') end
	if not status then return nil, error.NO_STATUS else data.event_calendar.status = tonumber(status) end
	if amount then data.event_calendar.amount = tonumber(amount) end
	if not(data.event_calendar.status==4 or data.event_calendar.status==5) then return nil, error.BAD_STATUS end
	if notes then data.notes = tostring(notes) end
	if client_attributes and type(client_attributes) ~= 'table' then return nil, error.BAD_ATTRIBUTES else data.event_calendar.client_attributes = client_attributes end	
	return put('apartments/'..apartment_id..'/event_calendars/'..id,data)
end

--[[
APARTMENT_ID - номер квартиры(лот), на которой находиться событие
ID - идентификатор события
--]]

function _M.bookings.delete(apartment_id,id)
	if not apartment_id or not id then return nil, error.NO_ID end
	local sign = sign({apartment_id=apartment_id,id=id})
	return delete('apartments/'..apartment_id..'/event_calendars/'..id..'?sign='..sign)
end

return _M
