# RealtyCalendar Lua SDK

RealtyCalendar API: https://docs.google.com/document/d/1Gzo05YgY_rNS8vXmiFQQHCpK_2hxiWIN16NGl74vkkE/edit?tab=t.0

## Usage

```
local api = require('realty.api')

```

### Получение броней

```
api.bookings.get(begin_date,end_date,event_begin_date_start,event_begin_date_end,event_end_date_start,event_end_date_end)

```

- begin_date - обязательный параметр, дата изменения брони в формате “yyyy-mm-dd”, с которой нужно начать поиск.;
- end_date - обязательный параметр, дата изменения брони в формате “yyyy-mm-dd”, по которую нужно произвести поиск. Не может быть больше завтрашнего дня по Москве;
- event_begin_date_start - необязательный параметр, дата заезда быть больше чем это значение
- event_begin_date_end - необязательный параметр, дата заезда должна быть меньше чем это значение
- event_end_date_start - необязательный параметр, дата выезда должна быть больше чем это значение
- event_end_date_end - необязательный параметр, дата выезда должна быть меньше чем это значение

### Добавление брони

```
api.bookings.add(apartment_id,begin_date,end_date,status,amount,notes,client_attributes)

```

- begin_date - обязательный параметр, дата начала события;
- end_date - обязательный параметр, дата окончания события; 
- status - обязательный параметр, статус события, принимает одно из значенией 4 - подана заявка, 5 - забронировано;
- amount - сумма оплаты;
- notes - примечание;
- client_attributes - данный о клиенте с полями:
	- fio - Фамилия Имя Отчество клиента;
	- phone -  телефон клиента;
	- additional_phone - дополнительный телефон клиента;
	- email - электронная почта клиента;
- apartment_id - номер квартиры(лот), для которой нужно создать событие.

### Редактирование брони

```
api.bookings.edit(apartment_id,id,begin_date,end_date,status,amount,notes,client_attributes)

```

- begin_date - обязательный параметр, дата начала события;
- end_date - обязательный параметр, дата окончания события;
- status - обязательный параметр, статус события, принимает одно из значенией 4 - подана заявка, 5 - забронировано;
- amount - сумма оплаты;
- notes - примечание;
- apartment_id - идентификатор квартиры, для перемещения события на другой объект
- client_attributes - данные о клиенте с полями:
	- fio - Фамилия Имя Отчество клиента;
	- phone - телефон клиента;
	- additional_phone - дополнительный телефон клиента;
	- email - электронная почта клиента;
- APARTMENT_ID - номер квартиры(лот), на которой находится событие
- ID - идентификатор события (брони)

### Удаление брони

```
api.bookings.delete(apartment_id,id)

```

- APARTMENT_ID - номер квартиры(лот), на которой находиться событие
- ID - идентификатор события

