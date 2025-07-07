local json = require('cjson')
--local api = require('litepms.api')
local date = require("date")
local md5 = require "md5"
local array = require('utils.array')

local t = {
	notes = "first event calendar", 
	amount = 2000, 
	begin_date = "2016-03-26",	
	end_date = "2016-03-29", 
	status = 4, 
	client_attributes = {fio = "Test Test Testov", phone = "791231223123", email = "test@example.com"}
}

local secret = 'sdjfkajeiruqfjkadjfaad'

local str = array.traverse(t)..secret

print(str)

print(md5.sumhexa(str))



