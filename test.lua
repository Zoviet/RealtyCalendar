local json = require('cjson')
local api = require('realty.api')
local date = require("date")

res,err = api.bookings.get(date():fmt('%Y-%m-%d'))

if not res then print(json.encode(err))
else print(json.encode(res)) end

res,err = api.bookings.add(291102,date():fmt('%Y-%m-%d'),date():adddays(2):fmt('%Y-%m-%d'),4,1234,'test')

if not res then print(json.encode(err))
else 
	print(json.encode(res)) 
	local id = string.format("%u", res.id)
	print(id)
	res,err = api.bookings.edit(291102,id,date():fmt('%Y-%m-%d'),date():adddays(3):fmt('%Y-%m-%d'),4,4321,'test edit')
	if not res then print(json.encode(err))
	else print(json.encode(res)) end
	res,err = api.bookings.delete(291102,id)
	if not res then print(json.encode(err))
	else print(json.encode(res)) end
end



