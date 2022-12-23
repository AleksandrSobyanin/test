#Область СлужебныеПроцедурыИФункции
Функция ВыполнитьВФоновомРежиме(Операция,МассивДанных)Экспорт
	Если Тип(МассивДанных) = Тип("Массив") И МассивДанных.Количество() = 1 Тогда
		ПараметрыФЗ = МассивДанных;
	Иначе
		ПараметрыФЗ = Новый Массив;
		Если ЗначениеЗаполнено(МассивДанных) Тогда
			ПараметрыФЗ.Добавить(МассивДанных);
		КонецЕсли;
	КонецЕсли;
	Возврат ФоновыеЗадания.Выполнить(Операция, ПараметрыФЗ);
КонецФункции

Процедура ИнициироватьЗагрузкуФайла(ДД) Экспорт
	Чтение = Новый ЧтениеДанных(ДД); 
	СтрокаРезультат = Чтение.ПрочитатьСтроку(); 
	
	МассивНаПоток = Новый Массив;
    Индекс = 0;
    КоличествоСтрокНаПоток = 20000;
	Пока Истина Цикл
		СтрокаРезультат = Чтение.ПрочитатьСтроку();
		Если Индекс = КоличествоСтрокНаПоток Или НЕ ЗначениеЗаполнено(СтрокаРезультат) Тогда 
			
			Задание = ВыполнитьВФоновомРежиме("ОбщегоНазначенияСервер.ЗаписьОбъектовПриЗагрузке",МассивНаПоток);
			
			Индекс = 0;
			МассивНаПоток.Очистить(); 
			Если НЕ ЗначениеЗаполнено(СтрокаРезультат) Тогда
				Прервать;	
			КонецЕсли;
		КонецЕсли;
		МассивНаПоток.Добавить(СтрокаРезультат);
		Индекс = Индекс + 1;
	КонецЦикла;
	Чтение = Неопределено; 

КонецПроцедуры

Процедура ЗаписьОбъектовПриЗагрузке(МассивСтрок) Экспорт 
	
	МассивСсылокХранения = Новый Массив; 
	ТекущееКоличество = 0;  
	НачатьТранзакцию();
	Для каждого СтрокаМассива Из МассивСтрок Цикл
		ТекущееКоличество = ТекущееКоличество + 1;
		МассивЗначений = СтрРазделить(СтрокаМассива,",");  
		ГМ = Справочники.ГрузовоеМесто.СоздатьЭлемент(); 
		ГМСсылка = Справочники.ГрузовоеМесто.ПолучитьСсылку(Новый УникальныйИдентификатор);
    	ГМ.УстановитьСсылкуНового(ГМСсылка);		
		ГМ.Наименование = МассивЗначений[2];
		ГМ.ЗаказКлиента = МассивЗначений[3];
		ГМ.ИдентификаторЕдиницыОбработки = МассивЗначений[4];
		ГМ.ОтпСклМс = МассивЗначений[5]; 
		ГМ.КодТипаОбработки = ПолучитьТипГрузовогоМеста(МассивЗначений[8]); 
		ГМ.Дата_Убытие = ПолучитьДату(МассивЗначений[0],МассивЗначений[1]);
		ГМ.Дата_Прибытие = ПолучитьДату(МассивЗначений[6],МассивЗначений[7]);
		КоличествоДнейХранения = Окр((ГМ.Дата_Убытие - ГМ.Дата_Прибытие)/(60*60*24),0,РежимОкругления.Окр15как10);
		ГМ.КоличествоДнейХранения = КоличествоДнейХранения;
		Попытка
			ГМ.Записать();
		Исключение
			ИнфОбОшибке = ИнформацияОбОшибке();
			ЗаписьЖурналаРегистрации("Ошибка записи ГМ",УровеньЖурналаРегистрации.Ошибка,,ИнфОбОшибке.Описание,ИнфОбОшибке.Причина); 
			ОтменитьТранзакцию();
			Прервать;
		КонецПопытки;	
		
		Если КоличествоДнейХранения > 0 Тогда
			МассивСсылокХранения.Добавить(ГМСсылка);
		КонецЕсли;
		
		Если ТекущееКоличество = 1000 Тогда
			Если ТранзакцияАктивна() Тогда
				ЗафиксироватьТранзакцию();
				НачатьТранзакцию();
			КонецЕсли;
			ТекущееКоличество = 0;
		КонецЕсли;
		
	КонецЦикла;
	
	Если ТранзакцияАктивна() Тогда
		ЗафиксироватьТранзакцию();
	КонецЕсли;	
	
	Если МассивСсылокХранения.Количество() > 0 Тогда
		Задание = ВыполнитьВФоновомРежиме("ОбщегоНазначенияСервер.ВыполнитьРасчетУслугХранения",МассивСсылокХранения);
	КонецЕсли;
		
	МассивСсылокХранения.Очистить();
	МассивЗначений.Очистить();
	КоличествоДнейХранения = 0; 
	ТекущееКоличество = 0;
КонецПроцедуры

Процедура ВыполнитьРасчетУслугХранения(МассивСсылок) Экспорт
	
	Текст = 
		"ВЫБРАТЬ ПЕРВЫЕ 1000
		|	ВЗ_ГМ.ГМ КАК ГМ,
		|	ЗНАЧЕНИЕ(Перечисление.Услуга.Хранение) КАК Услуга,
		|	ВЗ_ГМ.КоличествоДнейХранения * 10 КАК Сумма,
		|	ВЗ_ГМ.Дата_Убытие КАК Период
		|ИЗ
		|	(ВЫБРАТЬ
		|		ГрузовоеМесто.Ссылка КАК ГМ,
		|		ГрузовоеМесто.КоличествоДнейХранения КАК КоличествоДнейХранения,
		|		ГрузовоеМесто.Дата_Убытие КАК Дата_Убытие
		|	ИЗ
		|		Справочник.ГрузовоеМесто КАК ГрузовоеМесто
		|	ГДЕ
		|		ГрузовоеМесто.Ссылка В(&МассивСсылок)) КАК ВЗ_ГМ
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.РасчетУслуг КАК РасчетУслуг
		|		ПО ВЗ_ГМ.ГМ = РасчетУслуг.ГМ
		|			И (РасчетУслуг.Услуга = ЗНАЧЕНИЕ(Перечисление.Услуга.Хранение))
		|ГДЕ
		|	РасчетУслуг.ГМ ЕСТЬ NULL";
	Запрос = Новый Запрос;
	Запрос.Текст = Текст; 
	Запрос.УстановитьПараметр("МассивСсылок", МассивСсылок);
	
	Пока Истина Цикл
		РезультатЗапроса = Запрос.Выполнить();
		Если РезультатЗапроса.Пустой() Тогда
			Прервать;	
		КонецЕсли;
		
		Выборка = РезультатЗапроса.Выбрать();
		
		НачатьТранзакцию(); 
		Пока Выборка.Следующий() Цикл
			МенеджерРасчета = РегистрыСведений.РасчетУслуг.СоздатьМенеджерЗаписи();
			ЗаполнитьЗначенияСвойств(МенеджерРасчета,Выборка);
			Попытка
				МенеджерРасчета.Записать();	
			Исключение
				ИнфОбОшибке = ИнформацияОбОшибке();
				ЗаписьЖурналаРегистрации("Ошибка записи расчета хранения",УровеньЖурналаРегистрации.Ошибка,,ИнфОбОшибке.Описание,ИнфОбОшибке.Причина);
				ОтменитьТранзакцию();
				Прервать;
			КонецПопытки;
		КонецЦикла;
		Если ТранзакцияАктивна() Тогда
			ЗафиксироватьТранзакцию();
		КонецЕсли;
	КонецЦикла;
			
КонецПроцедуры

Процедура ВыполнитьРасчетУслугОбработки(Период) Экспорт 
	ПериодДень = Новый СтандартныйПериод; 
	ПериодДень.ДатаНачала = Период.ДатаНачала;
	ПериодДень.ДатаОкончания = КонецДня(ПериодДень.ДатаНачала);
	Пока ПериодДень.ДатаНачала < Период.ДатаОкончания Цикл
		Массив = Новый Массив; 
		Массив.Добавить(ПериодДень);
		Задание = ВыполнитьВФоновомРежиме("ОбщегоНазначенияСервер.ВыполнитьРасчетУслугОбработкиЗаПериод",Массив);
		ПериодДень.ДатаНачала = ПериодДень.ДатаНачала + 60*60*24;
		ПериодДень.ДатаОкончания = ПериодДень.ДатаОкончания + 60*60*24;
	КонецЦикла;
КонецПроцедуры

Процедура ВыполнитьРасчетУслугОбработкиЗаПериод(Период) Экспорт
	
	Текст = 
		"ВЫБРАТЬ
		|	ГрузовоеМесто.Ссылка КАК ГМ,
		|	ЗНАЧЕНИЕ(Перечисление.Услуга.Сортировка) КАК Услуга,
		|	ВЗ_РасчитанныеТарифы.СтоимостьТарифа * ВЫБОР
		|		КОГДА ГрузовоеМесто.КодТипаОбработки = ЗНАЧЕНИЕ(Перечисление.ТипГрузовогоМеста.МГТ)
		|			ТОГДА 10
		|		КОГДА ГрузовоеМесто.КодТипаОбработки = ЗНАЧЕНИЕ(Перечисление.ТипГрузовогоМеста.шина)
		|			ТОГДА 50
		|		КОГДА ГрузовоеМесто.КодТипаОбработки = ЗНАЧЕНИЕ(Перечисление.ТипГрузовогоМеста.КГТ)
		|			ТОГДА 100
		|		ИНАЧЕ 1
		|	КОНЕЦ КАК Сумма,
		|	&ДатаНачала КАК Период
		|ИЗ
		|	Справочник.ГрузовоеМесто КАК ГрузовоеМесто
		|		ЛЕВОЕ СОЕДИНЕНИЕ (ВЫБРАТЬ
		|			ВЗ_СреднеденевноеКоличество.КодТипаОбработки КАК КодТипаОбработки,
		|			ВЫБОР
		|				КОГДА ВЗ_СреднеденевноеКоличество.СреднедневноеКоличество МЕЖДУ ВЗ_Тарифы.НижняяГраница И ВЗ_Тарифы.ВерхняяГраница
		|						ИЛИ ВЗ_СреднеденевноеКоличество.СреднедневноеКоличество > ВЗ_Тарифы.НижняяГраница
		|							И ВЗ_Тарифы.ВерхняяГраница = 0
		|					ТОГДА ВЗ_Тарифы.Сумма
		|				ИНАЧЕ 0
		|			КОНЕЦ КАК СтоимостьТарифа
		|		ИЗ
		|			(ВЫБРАТЬ
		|				ГрузовоеМесто.КодТипаОбработки КАК КодТипаОбработки,
		|				ОКР(КОЛИЧЕСТВО(ГрузовоеМесто.Ссылка) / РАЗНОСТЬДАТ(НАЧАЛОПЕРИОДА(&ДатаНачала, МЕСЯЦ), ДОБАВИТЬКДАТЕ(&ДатаОкончанияМесяца, СЕКУНДА, 1), ДЕНЬ), 0) КАК СреднедневноеКоличество
		|			ИЗ
		|				Справочник.ГрузовоеМесто КАК ГрузовоеМесто
		|			ГДЕ
		|				ГрузовоеМесто.Дата_Убытие МЕЖДУ &ДатаНачала И &ДатаОкончанияМесяца
		|			
		|			СГРУППИРОВАТЬ ПО
		|				ГрузовоеМесто.КодТипаОбработки) КАК ВЗ_СреднеденевноеКоличество,
		|			(ВЫБРАТЬ
		|				Тарифы.Период КАК Период,
		|				Тарифы.Услуга КАК Услуга,
		|				Тарифы.Диапазон КАК Диапазон,
		|				Тарифы.Сумма КАК Сумма,
		|				Характеристика.НижняяГраница КАК НижняяГраница,
		|				Характеристика.ВерхняяГраница КАК ВерхняяГраница
		|			ИЗ
		|				РегистрСведений.Тарифы КАК Тарифы
		|					ЛЕВОЕ СОЕДИНЕНИЕ Справочник.Характеристика КАК Характеристика
		|					ПО Тарифы.Диапазон = Характеристика.Ссылка
		|			ГДЕ
		|				Тарифы.Услуга = ЗНАЧЕНИЕ(Перечисление.Услуга.Сортировка)) КАК ВЗ_Тарифы
		|		ГДЕ
		|			ВЫБОР
		|					КОГДА ВЗ_СреднеденевноеКоличество.СреднедневноеКоличество МЕЖДУ ВЗ_Тарифы.НижняяГраница И ВЗ_Тарифы.ВерхняяГраница
		|							ИЛИ ВЗ_СреднеденевноеКоличество.СреднедневноеКоличество > ВЗ_Тарифы.НижняяГраница
		|								И ВЗ_Тарифы.ВерхняяГраница = 0
		|						ТОГДА ВЗ_Тарифы.Сумма
		|					ИНАЧЕ 0
		|				КОНЕЦ > 0) КАК ВЗ_РасчитанныеТарифы
		|		ПО ГрузовоеМесто.КодТипаОбработки = ВЗ_РасчитанныеТарифы.КодТипаОбработки
		|ГДЕ
		|	ГрузовоеМесто.Дата_Убытие МЕЖДУ &ДатаНачала И &ДатаОкончания";
	Запрос = Новый Запрос;
	Запрос.Текст = Текст;
	Запрос.УстановитьПараметр("ДатаНачала", Период.ДатаНачала);
	Запрос.УстановитьПараметр("ДатаОкончания", Период.ДатаОкончания);
	Запрос.УстановитьПараметр("ДатаОкончанияМесяца", КонецМесяца(Период.ДатаОкончания));
	РезультатЗапроса = Запрос.Выполнить();
	Выборка = РезультатЗапроса.Выбрать();
	
	КоличествоДляОбработки = 1000;
	
	Индекс = 0; 
	НачатьТранзакцию();
	Пока Выборка.Следующий() Цикл
		Если Индекс < КоличествоДляОбработки Тогда
			МенеджерЗаписи = РегистрыСведений.РасчетУслуг.СоздатьМенеджерЗаписи();
			ЗаполнитьЗначенияСвойств(МенеджерЗаписи,Выборка);
			
			Попытка
				МенеджерЗаписи.Записать();
			Исключение
				ИнфОбОшибке = ИнформацияОбОшибке();
				ЗаписьЖурналаРегистрации("Ошибка записи расчета обработки",УровеньЖурналаРегистрации.Ошибка,,ИнфОбОшибке.Описание,ИнфОбОшибке.Причина);
				ОтменитьТранзакцию();
				Прервать;
			КонецПопытки;
			Индекс = Индекс + 1;
		Иначе
			Если ТранзакцияАктивна() Тогда
				ЗафиксироватьТранзакцию();	
				НачатьТранзакцию();
				Индекс = 0;
			КонецЕсли; 
		КонецЕсли;		
	КонецЦикла;
	Если ТранзакцияАктивна() Тогда
		ЗафиксироватьТранзакцию();	
	КонецЕсли; 
	
КонецПроцедуры

Функция ПолучитьТипГрузовогоМеста(Строка)
	Если Строка = "МГТ" Тогда
		Возврат	Перечисления.ТипГрузовогоМеста.МГТ;
	ИначеЕсли Строка = "КГТ" Тогда
		Возврат	Перечисления.ТипГрузовогоМеста.КГТ;
	ИначеЕсли Строка = "Хаб" Тогда
		Возврат	Перечисления.ТипГрузовогоМеста.Хаб;
	ИначеЕсли Строка = "Шина" Тогда
		Возврат	Перечисления.ТипГрузовогоМеста.Шина;
	Иначе
		Возврат Перечисления.ТипГрузовогоМеста.ПустаяСсылка();
	КонецЕсли;		
КонецФункции

Функция ПолучитьДату(ДатаСтрока,ВремяСтрока)
	Массив = Новый Массив; 
	Массив.Добавить(ДатаСтрока);
	Массив.Добавить("T");
	Массив.Добавить(ВремяСтрока);
	ДатаВремяСтрока = СтрСоединить(Массив);
	Массив.Очистить();
	Возврат ПрочитатьДатуJSON(ДатаВремяСтрока, ФорматДатыJSON.ISO);		
КонецФункции

#КонецОбласти
