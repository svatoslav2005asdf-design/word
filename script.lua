local Environment = getgenv and getgenv() or _G
local Previous = Environment.WordAutoType
if type(Previous) == "table" and type(Previous.Unload) == "function" then
    Previous.Unload()
    task.wait(0.6)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
if game.PlaceId ~= 71106427459865 then
    warn("Word Auto Type: this game is not supported.")
    return
end

local Network = ReplicatedStorage:WaitForChild("WordGame", 15)
local Action = Network and Network:WaitForChild("Action", 10)
local StateEvent = Network and Network:WaitForChild("State", 10)
if not Action or not StateEvent then
    warn("Word Auto Type: the game connection is unavailable.")
    return
end

local LibraryUrl = "https://github.com/Footagesus/WindUI"
local DictionaryUrl = "https://raw.githubusercontent.com/Harrix/Russian-Nouns/main/dist/russian_nouns.txt"
local CachePath = "WordAutoType_dictionary_v1.txt"
local Randomizer = Random.new()
local Connections = {}
local Threads = {}
local Alive = true
local Window
local WindUI
local Controls = {}
local CurrentState
local CurrentTurn
local CurrentMatch
local CurrentRound
local RoundWords = {}
local Used = {}
local Rejected = {}
local Tried = {}
local Completed = {}
local Attempts = 0
local Pending
local Job
local TypingBox
local TextConnection
local ManualTurn
local SuppressedTurn
local ChoiceSent
local ExpectedText
local AutoEnabled = false
local SmartEnabled = false
local AntiAfkEnabled = true
local Speed = 8
local function GetSpeed()
    -- The control updates Default before dispatching its callback.
    -- Read the current state directly so delayed callbacks cannot restore old values.
    local control = Controls.Speed
    local value = control and control.Value
    local current = type(value) == "table" and tonumber(value.Default) or nil
    if current and current == current and current > -math.huge and current < math.huge then
        Speed = math.clamp(current, 0.01, 100)
    end
    return Speed
end
local Mode = "Common"
local Dictionary = {}
local WordCount = 0
local DictionaryStatus = "Loading dictionary..."
local Status = "Waiting for game state"
local SelectedWord = "None"
local StatusPanel
local CreditsAddress = "t.me/Lesxov"
local CopyField
local NextAttemptAt = 0
local LastPanelText
local LastManualInput = -math.huge
local MobileKeyboard
local EngineAvailable = type(firesignal) == "function" or type(getconnections) == "function"

local CommonText = [[
абрикос автобус автомобиль адрес азбука акула алмаз альбом ананас апельсин аптека арбуз артист астронавт
бабочка багаж банан банка барабан бассейн башня белка берег берёза билет библиотека бинт блин болото ботинок брат бревно бумага букет булка бутылка
вагон ваза валенок ванна варенье ведро велосипед веник верблюд верёвка ветер ветка вечер вилка виноград вишня вода водопад воздух вокзал волк волна воробей ворона врач время
газета гараж гвоздь герой гитара глаз глина гриб гроза гром груша город гора горох гость голубь гнездо
дверь девочка дедушка дерево деревня диван дождь дом дорога доска друг дупло дым дыня дятел
еда ёж ёлка ель енот ёрш железо жемчуг жираф живот жук журнал
забор завод заяц звезда звонок зверь зебра зеркало зерно зима змея знак золото зонт зуб
игла игрушка игра изюм индюк иней искра история йог йога йод
кабан кабачок камень капуста карандаш карман картофель карта картина касса качели каша кефир кисть кит клетка ключ книга кнопка ковёр коза колесо колокол комната компас конфета конь корабль корень коридор корова корзина костёр кошка край краска кресло кролик крыша кружка крыло кубик кузнечик курица куст кухня
лампа ласточка лебедь лев лёд лента лес лестница лето лиса лист лимон лодка ложка лошадь лук луна лужа луч лыжа
магазин майка мак малина мальчик мама масло машина медведь мёд месяц метла метро мешок мир молоко молоток море морковь мороз мост мука музыка муравей муха мыло мышь мяч
небо неделя нитка нож ножницы нора нос носок ночь
обед облако огонь огород огурец одежда одеяло озеро окно окунь олень орёл орех оса осень остров ответ очки
пакет палка пальто папа пар парк парта парус паук пена перец перо песня песок петух пещера пила пирог письмо планета платье площадка поезд поле полка полотенце помидор посуда потолок почта праздник подарок птица пчела пыль
работа радуга рак ракета ракушка рама растение река репа рис рисунок робот рог роза рот роща рубашка рука ручей ручка рыба рынок рюкзак
сад салат самолёт сапог сахар свеча свёкла свет свитер свинья север семя семья сено сердце сестра сеть сила скала скатерть сковорода слон слово смех снег сова собака сок сокол солдат солнце соль сорока сосна сосед спина спорт стакан стена стекло стол стул сумка суп сыр
таблица тарелка театр телефон тень тесто тигр торт точка трава трактор тропа труба туман тыква
угол уголь удача ужин узел улица улитка улыбка урок утка утро ухо ученик учитель
фабрика факел фартук фасоль февраль фонарь фонтан форма фотография футбол
халат хлеб хлопок холм холодильник хор хомяк хвост художник
цапля цветок цвет цепь цирк цифра цыплёнок
чай чайник чашка час часы человек черепаха черника чертёж чеснок число чулок чудо
шапка шар шахматы шкаф школа шляпа шмель шнур шорты шоссе шуба шум шутка
щенок щека щётка щука экран экскурсия электричество этаж эхо юбка юг юла юность яблоко ягода язык яйцо якорь яма ящик ящерица
]]
-- Built-in vocabulary: 1345 unique words.
-- Source: Harrix/Russian-Nouns, plus the original common words.
local BuiltInDictionaryText = [[
аббатство абитуриент абрикос авангардист авантюрность автобус автография автомобиль аггравация агитпункт
аджика адрес азбука акселерат акула акустик алгебра аллергология аллигатор алмаз
альбом американизация амулет ананас антивещество антитело апельсин аптека арбуз аргументированность
армянка артист артистичность архетип астронавт атаманец аффектация аэромеханика бабочка багаж
бактериология банан банка банщица барабан баранинка бассейн башня беззубка белец
белка белокровие белошвейка бензинчик берег берейтор берёза беснующийся беспокойство бессмертность
бестактность бесчинник библиотека билет бинт биржевик блин блокгауз богомолье богостроитель
боливийка болото большевик ботинок браман брандмейстер брат бревно бремя броня
брыкун брыла бузотёрство буква букет булка бум бумага бурчание бутылка
вагон ваза валенок валкование ванна варенье варильщик вдовец вдёргивание веда
ведро велосипед вельвет веник верблюд верноподданная вероника верстание верстачок вершительница
верёвка ветер ветка вечер взаимовыручка взблеск вздёржка вилка виноград висельник
вишня вклад вместимость внезапность вогнутость вода водка водоверть водогрейня водомёт
водонагреватель водоносность водопад водопойка водь военнообязанная возбуждение воздержавшийся воздух войлок
вокабула вокабулярий вокзал волк волна вольная воробей ворона воспроизведение восточник
врач вредоносность время вспаивание вставка всход выбуривание вывихнутость вывязывание выковка
выкуривание выпаривание выпрядание выпускание выселенец высушивание вытачивание выхухоль вышколка газета
газончик газохранилище гамлет гараж гваюла гвоздь гектолитр геохимик гермафродитизм героизм
герой гжель гибкость гидравлик гидрант гиперболичность гитара глаз глина гнездо
гоготание година голубь гонт гора горбина гореваньице горилка город горох
горюн гость граб граната гриб гримаса гроза гром груша грушка
гугнивость гуттаперча дверь двор деаэратор деблокада деваха девочка девчонка девяностолетие
деградация дегуманизация дедуня дедушка деревня дерево державец джейран джентльменство джокер
диафон диван динамит директорат дитя дифференциация добыча дождевик дождь докладывание
дом донашивание дорога доска драже драцена драчунья дрессировщица дрова дрожина
дрозофила друг дружелюбие дупло дух дым дымоуловитель дыня дятел еда
езда ель енот ехидник жарево жарища жаровыносливость жатка железнодорожница железо
желчь жемчуг живоглот живот жираф жирондист житняк жук журнал журналистика
забор завод заигрывание закрутка зализанность залишек заматерелость запах запоночка зарянка
затаённость затирание захват защищённость заяц звезда зверь звонок звякание звёздность
зебра зеленца землепашец земство зеркало зерно зернопровод зима зимушка злец
злоба змея знак знаточество золото зонт зооферма зуб игла игра
игрушка идеография иероглиф извращенка изломанность изюм ильм именинник имитаторство инвариантность
индоевропеист индюк иней институтство инсценирование интеграция интересант искра испанистка исповедание
исподнее истопница история исчисление иудейка ишурия йог йога йод кабан
кабачок каботинство каганец кадет казарка казино камень камешник канаус капитель
каптана капуста каракулька карандаш карась карман карта картина картофель касса
кастрюлька каталептик качели каша кашмирка каёмочка квартирование квартплата кернер кефир
кибернетик кивок кинопрокат киносъёмка кипрегель кирка кисть кит кишлак клетка
ключ книга книгодержатель кнопка кобылёнка ковёр ковёрщица кожник коза кокетка
колесо коловратность колокол коломазь колонизатор колориметр комиссионка коммерциализация комната комолость
комочек компактность компас компрометация компьютеризация кондёр коногон конституционист контрактация контрафакция
контузия конфета конъюнктурщина конь координирование копирование коптильщик корабль корень корзина
коридор коринка корова корообдирка корунд корячка костоправка костёр кошка край
красавица краска крах кресло кролик кромсание крохотка кружка крутоверть крыжовник
крыло крыша кубик кубок кузнечик кукельван кулак кулачок культурник курильщица
курица курорт куст кутила кухня лаг лазер лакфиоль ламаизм лампа
лапушка ларинголог ласточка лебедь лев лейкопластырь лента леопард лепидодендрон лес
лесенка лесовывозка лесоистребление лесотехникум лестница лето лигирование лилипутик лимон линовальщик
лиса лист листвяг лодка ложка ломка ломовик лопушняк лошадь лужа
лук луна лунит луч лыжа лыжник льдогенератор любостяжание любостяжательница ляшка
лёд магазин магазинщица мадьярка майка мак малина маловодье мальчик мальчуган
мама маниакальность маранта марго мародёрка марсель масло махинища машина маэстро
медаль медведь медиация медик медпункт медяк мезоглея мембрана мент месяц
метла метро мешок мешочек мидия микроскоп минарет министерство мир миролюбец
миропознание мичман многоводность многозначность многообразность многоплодность многосложность можжевелина молоко молоток
моментальность монструозность морда море морковь мороз мост мостостроение мотня мотовелосипед
мотоциклистка мотыль мстительность мудрствование мужеложство мужеубийца музыка мука муравей мурена
мусор муха мыло мыс мышь мышьяк мыщелок мяч мёд набирание
набойка награждение нагромождённость надлобье наживка называние налавливание намерзь намораживание напаривание
напускание напутывание напёрсточек наружное насаливание насечка насос натаивание натирка натурщик
науковидность нахрап национализм начальница начерчивание небо невозвращенка негодник неделя недоброжелательство
недогадка недоуменность недоумие некондиционность некромант нелюбовь неограниченность неодолимость неосуществимость неотчуждаемость
неохота непартийность неподвластность неправедность неровня несвежесть несовершеннолетняя несолидность неудовлетворительность нешуточность
низкость нилотка нитка ниточница ногата нож ножницы нора норма нос
носишко носок ночь нудность нумизматика обдёргивание обед обезлесение обесцвечивание обесценение
обжалование обилие обкраивание облако обмирщение обновляемость обновочка ободник обольститель оборка
оборотень обрубная обскурантизм обстановка обтягивание оглашение огонь огород огрубление огурец
одежда одеяло односоставность одностаничник одонтология ожидание озеро озимка окаёмка окно
окольничий октавист окунь олень олешек ольшанка ономатология опилка опустошённость опыт
орех ориентация орт оружейник орёл оса осень осинка осмотрщик основание
остров отбывание отведение отверделость ответ отводок отдалённость отделочница отложение отпарка
отповедь отрастание отрывистость отсвет охвостье охранение оценщик очки паж пакет
палка пальто папа папуша пар паранефрит парашечник парашют парк парта
парус паук пахит паясничество пена пепсин первичность первоисточник первотельная перевал
перегонка пережабина перековывание перекупывание перелезание перемежевание переминание перескабливание перестроение переходчивость
перец переярка перипатетик перо персик песня песок петух пещера пианино
пикетаж пила пирамидон пиранометр пирог письмена письмо плаксивость план планета
пластинка платье плафон плезиозавр плешанка плодовитость плоскость площадка площица плёс
побледнение поверье подарок подбавление подбел подбивка подбойщик подвешивание подвёрстывание подгузник
подзол подкапывание подкачивание подклёпывание подмешивание поднос подпарывание подрывщик подслеповатость подстрижка
подфарок поезд позиционность позолотчик позументщик покалывание поле полемарх поленика полесник
поликлиника полка пологость полонянка полотенце полухронометр поместьице помидор попечительша популяризатор
портняжничество посевщик посланец поспешность посуда посыльщик посягновение потворщица потолок почта
православие праздник прапрадед прах предосторожность предшественник предъявитель приветствие привинчивание привяливание
приговорочка придумывание прижимщица прилипчивость примерщица прирез присвоитель приспособляемость пристрастие притворщик
причёска пришелица пришпоривание приёмщик пробуривание провозгласитель продёржка прожектёр прозаичность проктит
пролысина промасливание промес промысловик прорастаемость простатит просфира противоборство противоречие процентовка
прошивальщик прощелыжник псаммон психоневролог птица пунктир пунктирование пуританизм пуританство путность
пчела пчеловод пыль пьяника пьянюга рабовладелец работа работища радиоактивность радиотрансляция
радуга разбрасывание разбухание развальцовка развозчик развратительница разгар разглядка разлучение размачтовывание
разноголосица разнообразие разнуздывание разок рак ракета ракушка рама рамооборот ранет
раскопка распивание распиловка расплавка распялка расспросчик растекание растение растениеводство растильня
расфасовщик расформирование расценка рахитичка реакция реалистка ребёночек реверс револьверишко регент
режиссёрство резонирование резонёрствование река реляция репа ретуширование рефлективность рецессивность ринк
рис рисунок робот рог рожденница роза рольмопс росянка рот роща
рубашка рублик рука руководительница ручей ручка рыба рыбёшка рынок рюкзак
ряженая рясник сабей сад садовник саепёк салат саммит самовосхваление самовяз
самолёт самотёк самочка сапог саранчук сарафанишко сахар сахарозавод сбруйка сварщик
свет светонепроницаемость светопроницаемость светосигнализация свеча свиносовхоз свинья свистун свитер свободолюбец
своеволие свёкла север седина сейид секстильон селекционер селёдочница семеноведение семья
семя сенаторша сено сердце сестра сетование сеть сила силуэтистка синкопа
синтетика синхронизатор сирокко сказуемое скакалка скала скатерть складчинка склейщица склочничество
сковорода сколка скопидомка сластолюбец следствие словинец слово слон смарывание смех
смолёвка смрадность снайпинг снег сновидец сноповязальщик соаренда собака сова соглядатай
сок сокамерник сокол сокрушительность солдат солидность солнце соль сопилка сопровождение
сопун сорока сосед сосна составитель сострастие спарывание спектрограф спина спиралька
спирогира спорость спорт спёртость срисовка сродственница стакан станичник станкостроитель староста
старшой створка стек стекло стена стихослагательство стожок стол сторонник стрелочница
стрепетёнок стригольничество стрижка стружка структура стул ступенчатость су суданец сумасброд
сумка суммирование суп сусальность суслик существование сфалерит счерпывание сыр сычонок
табаковод таблица табун тарелка татуировка театр театрализация телевизор телефон темница
тендер тень теплоэнергетика терренкур теснина тесто техник тигр токсикология толкач
торизм торт точка трава травонька трактамент трактор трахеотомия трепальня треста
третьекурсница трещание трилобит трифтонг трихинелла тромбофлебит тропа трость труба трясение
тулумбас туман туннельщик тускловатость тухлость тушёвка тыква тюк убийственность увеличение
увечье увёртка увёртывание угол уголь удача ужин узел улитка улица
уличение улыбка умыкание уплотнитель урок успение устроительница утка утолока утро
ухо учащение ученик учитель учителька фабианство фабрика фабрикант факел фанзочка
фантазёрка фартук фасоль фаталистичность февраль фединг фенакит фи фиг фила
финикиянин фонарь фонтан форма форштадт фотография фрахтователь фрачишко фреза френч
фригийка фульгурит фундирование футбол халат хвост хедерник хижинка хина хлам
хлеб хлебофураж хлопок холм холодильник хомутишко хомутник хомяк хор храпак
хромая хрусталик художник цапля цвет цветок цевьё цепь цирк цифра
цыплёнок цыпочка чай чайник чалма час часы чашка чеканка человек
человеконенавистничество черепаха черника черпальщица чертёж чеснок четвертак четырёхклассник четырёхклассница число
чресла чудо чулок чумная чёсанец шабёр шаг шаманка шапка шар
шаромыжничество шахматы шезлонг шериф шерсточесалка шингард шипучее шишельница шкаторина шкаф
школа шлакование шлейка шлихтовка шлюз шляпа шмель шнур шорты шоссе
шпингалет шпротина шу шуба шугание шум шутка щека щелкопёрство щелчок
щенок щипальщик щука щётка эконом экономность экран экскурсия эластик электричество
электробритва электросварщик элиминирование эмальер энциклопедистка эпикурейство эстакада эстрадность этаж эхо
эшарп юбка юг юла юность юрага юстирование яблоко ягель ягода
язык яйцеклетка яйцо якорь яма ярлык ярь ятаган ятовь ячменка
ящерица ящик ёж ёлка ёрш
]]
local CommonWords = {}
local CommonSet = {}

local function Spawn(callback)
    local thread = task.defer(function()
        local ok, failure = xpcall(callback, debug.traceback)
        if not ok and Alive then
            warn("Word Auto Type: " .. tostring(failure))
            Status = "An operation failed; check the console"
        end
    end)
    Threads[thread] = true
    return thread
end

local function Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Connections, connection)
    return connection
end

local function Notify(message)
    if Alive and WindUI then
        pcall(function()
            WindUI:Notify({Title = "Word Auto Type", Content = message, Duration = 4})
        end)
    end
end

local function Normalize(word)
    if type(word) ~= "string" then
        return nil
    end
    local ok, result = pcall(function()
        local characters = {}
        for _, code in utf8.codes(word) do
            if code >= 1040 and code <= 1071 then
                code = code + 32
            elseif code == 1025 then
                code = 1105
            end
            if not (code >= 1072 and code <= 1103 or code == 1105) then
                return nil
            end
            table.insert(characters, utf8.char(code))
        end
        if #characters < 2 or #characters > 30 then
            return nil
        end
        return table.concat(characters)
    end)
    return ok and result or nil
end

local function Canonical(word)
    return (word:gsub("ё", "е"))
end

local function FirstLetter(word)
    return word:sub(1, utf8.offset(word, 2) - 1)
end

for word in CommonText:gmatch("%S+") do
    local normalized = Normalize(word)
    if normalized and not CommonSet[normalized] then
        CommonSet[normalized] = true
        table.insert(CommonWords, normalized)
    end
end

local function BuildDictionary(text)
    local index = {}
    local unique = {}
    local count = 0
    local scanned = 0
    for line in text:gmatch("[^\r\n]+") do
        local word = Normalize(line:gsub("^\239\187\191", ""))
        if word and not unique[word] then
            unique[word] = true
            local letter = FirstLetter(word)
            local length = utf8.len(word)
            index[letter] = index[letter] or {}
            index[letter][length] = index[letter][length] or {}
            table.insert(index[letter][length], word)
            count = count + 1
        end
        scanned = scanned + 1
        if scanned % 1500 == 0 then
            task.wait()
            if not Alive then
                return nil, 0
            end
        end
    end
    return index, count
end

local Features = {
    Words = {}, MatchWords = {}, Serial = 0, History = {},
    ConfigName = "default", WordsName = "words", IncludeWords = true, Input = "",
}
if type(Environment.WordAutoTypeHistory) == "table" then
    Features.History = Environment.WordAutoTypeHistory
end
Environment.WordAutoTypeHistory = Features.History
Features.Serial = tonumber(Environment.WordAutoTypeMatchSerial) or 0

function Features.ParseWords(value)
    local result, seen = {}, {}
    local function add(token)
        local word = Normalize(token)
        if word and not seen[Canonical(word)] then
            seen[Canonical(word)] = true
            table.insert(result, word)
        end
    end
    if type(value) == "string" then
        for token in value:gmatch("[^%s,;]+") do add(token) end
    elseif type(value) == "table" then
        for _, token in ipairs(value) do add(token) end
    else
        error("Words must be text or a list")
    end
    return result
end

function Features.Rebuild(words)
    local normalized = Features.ParseWords(words)
    local index, count = BuildDictionary((BuiltInDictionaryText .. "\n" .. table.concat(normalized, "\n")):gsub("%s+", "\n"))
    if not Alive or not index then return false end
    Features.Words = normalized
    Dictionary, WordCount = index, count
    DictionaryStatus = "Built-in + custom | " .. tostring(count) .. " words"
    CommonWords, CommonSet = {}, {}
    for word in (CommonText .. "\n" .. table.concat(normalized, "\n")):gmatch("%S+") do
        local normalizedWord = Normalize(word)
        if normalizedWord and not CommonSet[Canonical(normalizedWord)] then
            CommonSet[Canonical(normalizedWord)] = true
            table.insert(CommonWords, normalizedWord)
        end
    end
    return true
end

function Features.NewMatch()
    Features.MatchWords = {}
    Features.Serial = Features.Serial + 1
    Environment.WordAutoTypeMatchSerial = Features.Serial
end

function Features.Remember(word)
    local key = Canonical(word)
    if Features.MatchWords[key] then return end
    Features.MatchWords[key] = true
    local previous = Features.History[key]
    Features.History[key] = {
        uses = math.min(100000, (type(previous) == "table" and tonumber(previous.uses) or 0) + 1),
        match = Features.Serial,
    }
end

function Features.Choose(pool)
    local weights, total = {}, 0
    for i, word in ipairs(pool) do
        local previous = Features.History[Canonical(word)]
        local uses = type(previous) == "table" and tonumber(previous.uses) or 0
        local age = type(previous) == "table" and Features.Serial - (tonumber(previous.match) or 0) or 100
        local weight = 1 / (1 + math.max(0, uses)) ^ 2
        if age <= 1 then weight = weight * 0.05
        elseif age <= 3 then weight = weight * 0.25 end
        weights[i] = weight
        total = total + weight
    end
    local target = Randomizer:NextNumber() * total
    for i, word in ipairs(pool) do
        target = target - weights[i]
        if target <= 0 then return word end
    end
    return pool[#pool]
end

local function Fetch(url, fresh)
    if fresh then
        url = url .. "?wat=" .. HttpService:GenerateGUID(false)
    end
    local requestFunction = request or http_request or (syn and syn.request)
    local ok, result = pcall(function()
        if requestFunction then
            local response = requestFunction({Url = url, Method = "GET", Headers = { ["Cache-Control"] = "no-cache" }, Timeout = 12})
            if response.StatusCode ~= 200 or type(response.Body) ~= "string" then
                error("HTTP request failed")
            end
            return response.Body
        end
        return game:HttpGet(url, true)
    end)
    return ok and type(result) == "string" and result or nil
end

local function TurnKey(state)
    if not state then
        return nil
    end
    return table.concat({tostring(state.tableId), tostring(state.generation or 0), tostring(state.round), tostring(state.turn), tostring(state.letter)}, ":")
end

local function MatchKey(state)
    return tostring(state.tableId) .. ":" .. tostring(state.generation or 0)
end

local function GetBox()
    local gui = Player.PlayerGui:FindFirstChild("WordGameUI")
    local canvas = gui and gui:FindFirstChild("Canvas")
    local match = canvas and canvas:FindFirstChild("Match")
    return match and match:FindFirstChild("TypingCapture")
end

local function Blocked()
    if Controls.Keybind and Controls.Keybind.Picking then
        return true
    end
    local focused = InputService:GetFocusedTextBox()
    return (focused ~= nil and focused ~= TypingBox) or (TypingBox and TypingBox:GetAttribute("ChatInputBlocked") == true)
end

local function CanPlay(key)
    local state = CurrentState
    local box = TypingBox
    local match = box and box.Parent
    local hearts = match and match:FindFirstChild("Hearts")
    local focusButton = match and match:FindFirstChild("FocusWord")
    local keyboard = match and match:FindFirstChild("WordKeyboard")
    local inputReady = match and match.Visible and hearts and hearts:GetAttribute("Actor") == (state and state.you)
        and (InputService.TouchEnabled and keyboard and keyboard.Visible or not InputService.TouchEnabled and focusButton and focusButton.Visible)
    return Alive and EngineAvailable and state ~= nil and state.phase == "playing" and state.turn == state.you
        and not state.acceptedWord and type(state.letter) == "string" and state.letter ~= ""
        and inputReady and (not key or CurrentTurn == key) and not Blocked()
        and type(state.deadline) == "number" and state.deadline - workspace:GetServerTimeNow() > 0.5
end

local function CancelTyping(message, suppress)
    local job = Job
    Job = nil
    if suppress then
        SuppressedTurn = CurrentTurn
        ManualTurn = nil
    end
    if job and job.thread and job.thread ~= coroutine.running() then
        pcall(task.cancel, job.thread)
        Threads[job.thread] = nil
    end
    if message then
        Status = message
    end
end

local function IsAvailable(word)
    local normalized = Canonical(word)
    return not Features.MatchWords[normalized] and not Used[normalized] and not Rejected[normalized] and not Tried[normalized] and not RoundWords[normalized]
end

local function Estimate(length)
    return (length - 1) / GetSpeed() + 0.05
end

local function CandidatePool(letter, seconds)
    local index = Dictionary[letter]
    if not index then
        return {}
    end
    local pool = {}
    if Mode == "Common" then
        for _, word in ipairs(CommonWords) do
            if FirstLetter(word) == letter and IsAvailable(word) and Estimate(utf8.len(word)) <= seconds then
                table.insert(pool, word)
            end
        end
        if #pool > 0 then
            return pool
        end
    end
    local startLength, endLength, step = 2, 30, 1
    if Mode == "Longest" then
        startLength, endLength, step = 30, 2, -1
    elseif Mode == "Common" then
        startLength, endLength = 4, 10
    end
    for length = startLength, endLength, step do
        if Estimate(length) <= seconds then
            for _, word in ipairs(index[length] or {}) do
                if IsAvailable(word) then
                    table.insert(pool, word)
                end
            end
            if #pool > 0 and Mode ~= "Common" then
                break
            end
        end
    end
    return pool
end

local function SetText(text)
    ExpectedText = text
    TypingBox.Text = text
end

local function Submit(job)
    local box = TypingBox
    local requestId = tonumber(box:GetAttribute("AnalyticsSubmit")) or 0
    Pending = {key = job.key, word = job.word, started = os.clock(), requestId = requestId + 1}
    Attempts = Attempts + 1
    Tried[Canonical(job.word)] = true
    Features.Remember(job.word)
    RoundWords[Canonical(job.word)] = job.word
    if type(firesignal) == "function" then
        local ok = pcall(firesignal, box.FocusLost, true)
        if ok then
            return true
        end
    end
    if type(getconnections) == "function" then
        local ok, listeners = pcall(getconnections, box.FocusLost)
        if ok then
            for _, listener in ipairs(listeners) do
                local callback = listener.Function
                if callback and pcall(callback, true) then
                    return true
                end
            end
        end
    end
    Pending = nil
    EngineAvailable = false
    Notify("This executor cannot submit words through the game input.")
    return false
end

local function StartTyping()
    if Job or Pending or not CanPlay() or Completed[CurrentTurn] or Attempts >= 3 then
        return false
    end
    local box = GetBox()
    if not box or box ~= TypingBox then
        Status = "Waiting for the game input"
        return false
    end
    if not AutoEnabled and box.Text ~= "" and box.Text ~= ExpectedText then
        SuppressedTurn = CurrentTurn
        ManualTurn = nil
        Status = "Paused: the game input contains your text"
        return false
    end
    local seconds = CurrentState.deadline - workspace:GetServerTimeNow() - 0.5
    local pool = CandidatePool(CurrentState.letter, seconds)
    if #pool == 0 then
        Status = "No available word fits this turn"
        return false
    end
    local word = Features.Choose(pool)
    local job = {key = CurrentTurn, word = word, smart = SmartEnabled}
    Job = job
    SelectedWord = word
    job.thread = Spawn(function()
        local function Valid()
            return Job == job and CanPlay(job.key) and (AutoEnabled or SuppressedTurn ~= job.key)
        end
        if not Valid() then
            if Job == job then CancelTyping("Paused", false) end
            return
        end
        SetText("")
        Status = "Typing..."
        local suffix = word:sub(utf8.offset(word, 2))
        local characters, weights = {}, {}
        local totalWeight = 0
        for _, code in utf8.codes(suffix) do
            table.insert(characters, utf8.char(code))
            local weight = job.smart and Randomizer:NextNumber(0.85, 1.15) or 1
            table.insert(weights, weight)
            totalWeight = totalWeight + weight
        end
        -- Smart rhythm preserves the same total typing time.
        if #characters > 0 then
            local scale = #characters / totalWeight
            for i = 1, #weights do weights[i] = weights[i] * scale end
        end
        local text = ""
        local nextCharacter = 1
        local progress = 0
        local lastTick = os.clock()
        local intervalSpeed = GetSpeed()
        while nextCharacter <= #characters do
            if not Valid() then
                if Job == job then CancelTyping("Paused", false) end
                return
            end
            task.wait()
            if not Valid() then
                if Job == job then CancelTyping("Paused", false) end
                return
            end
            local now = os.clock()
            progress = progress + (now - lastTick) * intervalSpeed
            lastTick = now
            intervalSpeed = GetSpeed()
            local changed = false
            -- Catch up all due characters after a slow frame, without extra waits.
            while nextCharacter <= #characters and progress >= weights[nextCharacter] do
                progress = progress - weights[nextCharacter]
                text = text .. characters[nextCharacter]
                nextCharacter = nextCharacter + 1
                changed = true
            end
            if changed then SetText(text) end
        end
        task.wait()
        if Valid() and box.Text == text then
            Status = Submit(job) and "Waiting for the server" or "Word submission is unavailable"
        end
        if Job == job then
            Job = nil
        end
    end)
    return true
end

local function UpdateBox()
    local box = GetBox()
    if box == TypingBox then
        return
    end
    CancelTyping(nil, false)
    if TextConnection then
        TextConnection:Disconnect()
    end
    TypingBox = box
    ExpectedText = nil
    if box then
        TextConnection = box:GetPropertyChangedSignal("Text"):Connect(function()
            if not Alive or TypingBox ~= box then
                return
            end
            if box.Text ~= ExpectedText and Job then
                if AutoEnabled then
                    if CanPlay(Job.key) then
                        SetText(ExpectedText or "")
                    else
                        CancelTyping("Waiting for the game input", false)
                    end
                elseif box.Text ~= "" or os.clock() - LastManualInput < 0.3 then
                    CancelTyping("Paused: manual input detected", true)
                else
                    ExpectedText = ""
                    NextAttemptAt = os.clock() + 0.25
                    CancelTyping("Waiting for the game input", false)
                end
            end
        end)
    end
    local keyboard = box and box.Parent:FindFirstChild("WordKeyboard")
    if keyboard and keyboard ~= MobileKeyboard then
        MobileKeyboard = keyboard
        for _, button in ipairs(keyboard:GetDescendants()) do
            if button:IsA("TextButton") then
                Connect(button.Activated, function()
                    LastManualInput = os.clock()
                    if Job and not AutoEnabled then CancelTyping("Paused: manual input detected", true) end
                end)
            end
        end
    end
end

local function HandlePacket(packet)
    if not Alive or type(packet) ~= "table" then
        return
    end
    if packet.kind == "match" then
        if CurrentState and packet.tableId == CurrentState.tableId then
            local generation, oldGeneration = packet.generation or 0, CurrentState.generation or 0
            if generation < oldGeneration or generation == oldGeneration and (packet.round or 0) < (CurrentState.round or 0) then
                return
            end
        end
        local match = MatchKey(packet)
        if CurrentMatch ~= match then
            CurrentMatch = match
            Features.NewMatch()
            Used = {}
            Rejected = {}
            Completed = {}
        end
        local round = match .. ":" .. tostring(packet.round)
        if CurrentRound ~= round then
            CurrentRound = round
            RoundWords = {}
        end
        local key = TurnKey(packet)
        if key ~= CurrentTurn then
            CancelTyping(nil, false)
            CurrentTurn = key
            Pending = nil
            Attempts = 0
            Tried = {}
            ManualTurn = nil
            SuppressedTurn = nil
            ChoiceSent = nil
            ExpectedText = nil
            NextAttemptAt = os.clock() + 0.25
            Status = packet.phase == "playing" and (packet.turn == packet.you and "Waiting for the game input" or "Waiting for the other player")
                or packet.phase == "choosing" and "Waiting for a letter" or "Waiting for the round"
        end
        CurrentState = table.clone(packet)
        if packet.acceptedWord then
            local word = Normalize(packet.acceptedWord)
            if word then
                Used[Canonical(word)] = true
                Features.Remember(word)
                RoundWords[Canonical(word)] = word
            end
            Completed[key] = true
        end
    elseif packet.kind == "accepted" then
        if not CurrentState or packet.tableId ~= CurrentState.tableId or (packet.generation or 0) ~= (CurrentState.generation or 0) then
            return
        end
        local word = Normalize(packet.word)
        if word then
            Used[Canonical(word)] = true
            Features.Remember(word)
        end
        if packet.round == CurrentState.round then
            if word then RoundWords[Canonical(word)] = word end
            CurrentState.acceptedWord = packet.word
            Completed[CurrentTurn] = true
            Pending = nil
            ManualTurn = nil
            CancelTyping("Word accepted", false)
        end
    elseif packet.kind == "invalid" or packet.kind == "wordRejected" or packet.kind == "missed" then
        if not Pending or not CurrentState then
            return
        end
        if packet.tableId and packet.tableId ~= CurrentState.tableId
            or packet.round and packet.round ~= CurrentState.round
            or packet.generation and packet.generation ~= (CurrentState.generation or 0)
            or packet.actor and packet.actor ~= CurrentState.you
            or packet.requestId and packet.requestId ~= Pending.requestId then
            return
        end
        if packet.kind == "missed" then
            Completed[CurrentTurn] = true
            Pending = nil
            ManualTurn = nil
            CancelTyping("Turn expired", false)
            return
        end
        local word = Canonical(Pending.word)
        if packet.reason == "used" then
            Used[word] = true
        else
            Rejected[word] = true
        end
        Pending = nil
        NextAttemptAt = os.clock() + 0.6
        Status = Attempts < 3 and "Word rejected; selecting another" or "Attempt limit reached"
        if Attempts >= 3 then ManualTurn = nil end
    elseif packet.kind == "lobby" or packet.kind == "result" then
        CancelTyping("Waiting for a match", false)
        CurrentState = nil
        CurrentTurn = nil
        CurrentMatch = nil
        CurrentRound = nil
        RoundWords = {}
        Pending = nil
        ManualTurn = nil
        ChoiceSent = nil
        Used = {}
        Completed = {}
    end
end

local function StopAll()
    AutoEnabled = false
    SmartEnabled = false
    ManualTurn = nil
    CancelTyping("Stopped", true)
    if Controls.Auto then Controls.Auto:Set(false) end
    if Controls.Smart then Controls.Smart:Set(false) end
end

function Features.Path(name, kind)
    if type(name) ~= "string" or not name:match("^[%w_-]+$") or #name > 48 then
        error("Use a config name with 1-48 Latin letters, digits, _ or -")
    end
    return "WordAutoType_" .. kind .. "_" .. name .. ".json"
end

function Features.HistorySnapshot()
    local copy = {}
    for word, item in pairs(Features.History) do
        if type(item) == "table" and Normalize(word) then
            copy[word] = {uses = item.uses, match = item.match}
        end
    end
    return copy
end

function Features.Save(name, wordsOnly)
    assert(type(writefile) == "function", "This executor cannot save files")
    local payload
    if wordsOnly then
        payload = {version = 1, kind = "words", words = Features.Words}
    else
        payload = {
            version = 1, kind = "config", speed = GetSpeed(), mode = Mode,
            auto = AutoEnabled, smart = SmartEnabled, antiAfk = AntiAfkEnabled,
            keybind = Controls.Keybind and Controls.Keybind.Value or "RightControl",
            history = Features.HistorySnapshot(), serial = Features.Serial,
        }
        if Features.IncludeWords then payload.words = Features.Words end
    end
    local path = Features.Path(name, wordsOnly and "words" or "config")
    writefile(path, HttpService:JSONEncode(payload))
    Notify("Saved: " .. path)
end

function Features.Load(name, wordsOnly)
    assert(type(readfile) == "function", "This executor cannot load files")
    local path = Features.Path(name, wordsOnly and "words" or "config")
    local payload = HttpService:JSONDecode(readfile(path))
    assert(type(payload) == "table" and payload.version == 1, "Unsupported config")
    assert(payload.kind == (wordsOnly and "words" or "config"), "Wrong config type")
    local words
    if payload.words ~= nil then
        assert(type(payload.words) == "table", "Invalid saved words")
        words = Features.ParseWords(payload.words)
    end
    if wordsOnly then
        assert(words, "No words in this file")
        local combined = table.clone(Features.Words)
        for _, word in ipairs(words) do table.insert(combined, word) end
        assert(Features.Rebuild(combined), "Dictionary loading cancelled")
    else
        local speed = tonumber(payload.speed)
        assert(speed and speed == speed and speed >= 0.01 and speed <= 100, "Invalid speed")
        assert(payload.mode == "Common" or payload.mode == "Shortest" or payload.mode == "Longest", "Invalid mode")
        for _, key in ipairs({"auto", "smart", "antiAfk"}) do
            assert(type(payload[key]) == "boolean", "Invalid toggle: " .. key)
        end
        assert(type(payload.keybind) == "string" and Enum.KeyCode[payload.keybind], "Invalid keybind")
        local history = {}
        local serial = tonumber(payload.serial) or 0
        assert(serial >= 0 and serial < 1e12 and serial == math.floor(serial), "Invalid match history")
        if payload.history ~= nil then
            assert(type(payload.history) == "table", "Invalid history")
            for word, item in pairs(payload.history) do
                local normalized = Normalize(word)
                if normalized and type(item) == "table" then
                    local uses, match = tonumber(item.uses), tonumber(item.match)
                    if uses and uses >= 0 and uses <= 100000 and match and match >= 0 and match <= serial then
                        history[Canonical(normalized)] = {uses = uses, match = match}
                    end
                end
            end
        end
        CancelTyping("Loading config", false)
        if words then assert(Features.Rebuild(words), "Dictionary loading cancelled") end
        -- Keep this match's exclusions when loading settings during a game.
        Features.Serial = math.max(Features.Serial, serial)
        for word, item in pairs(history) do
            item.match = Features.Serial - (serial - item.match)
            local existing = Features.History[word]
            if not existing or item.uses > (tonumber(existing.uses) or 0) then
                Features.History[word] = item
            end
        end
        Environment.WordAutoTypeMatchSerial = Features.Serial
        Speed = speed
        Controls.Speed:Set(speed)
        GetSpeed()
        Controls.Mode:Select(payload.mode)
        Mode = payload.mode
        Controls.Keybind:Set(payload.keybind)
        Controls.Smart:Set(payload.smart)
        Controls.AntiAfk:Set(payload.antiAfk)
        Controls.Auto:Set(payload.auto)
        SmartEnabled, AntiAfkEnabled, AutoEnabled = payload.smart, payload.antiAfk, payload.auto
    end
    Notify("Loaded: " .. path)
end

function Features.Safe(callback)
    local ok, failure = pcall(callback)
    if not ok then Notify(tostring(failure)) end
end

local Session = {}
Session.Controls = Controls
Session.StopAll = StopAll
Session.TypeWord = function()
    if not CanPlay() then
        Notify("Wait for your turn and close any text input.")
        return false
    end
    if Job or Pending then
        Notify("A word is already being processed.")
        return false
    end
    SuppressedTurn = nil
    ManualTurn = CurrentTurn
    return StartTyping()
end
Session.GetStatus = function()
    local roundWords = {}
    for _, word in pairs(RoundWords) do table.insert(roundWords, word) end
    table.sort(roundWords)
    return {
        alive = Alive, status = Status, word = SelectedWord, words = WordCount,
        dictionary = DictionaryStatus, auto = AutoEnabled, smart = SmartEnabled,
        antiAfk = AntiAfkEnabled, mode = Mode, speed = GetSpeed(), typing = Job ~= nil,
        pending = Pending ~= nil, attempts = Attempts, turn = CurrentTurn,
        phase = CurrentState and CurrentState.phase, submittedWord = Pending and Pending.word,
        roundWords = roundWords, round = CurrentState and CurrentState.round,
        yourTurn = CurrentState ~= nil and CurrentState.phase == "playing" and CurrentState.turn == CurrentState.you,
    }
end
Session.Unload = function(fromWindow)
    if not Alive then return end
    Alive = false
    AutoEnabled = false
    AntiAfkEnabled = false
    CancelTyping(nil, false)
    if TextConnection then TextConnection:Disconnect() end
    for _, connection in ipairs(Connections) do connection:Disconnect() end
    if type(getconnections) == "function" then
        for _, signal in ipairs({InputService.InputBegan, InputService.InputEnded}) do
            local ok, listeners = pcall(getconnections, signal)
            if ok then
                for _, listener in ipairs(listeners) do
                    local callback = listener.Function
                    if callback then
                        local found, source = pcall(debug.info, callback, "s")
                        if found and type(source) == "string" and source:find("WordAutoTypeWindUI", 1, true) then
                            pcall(function() listener:Disconnect() end)
                        end
                    end
                end
            end
        end
    end
    local running = coroutine.running()
    for thread in pairs(Threads) do
        if thread ~= running and coroutine.status(thread) ~= "dead" then pcall(task.cancel, thread) end
    end
    table.clear(Connections)
    table.clear(Threads)
    if Environment.WordAutoType == Session then Environment.WordAutoType = nil end
    if Window and not fromWindow then pcall(function() Window:Destroy() end) end
end
Environment.WordAutoType = Session

Connect(StateEvent.OnClientEvent, HandlePacket)
UpdateBox()
Action:FireServer("sync")

local librarySource = Fetch("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua")
local libraryOk, libraryResult = pcall(function()
    assert(librarySource, "WindUI download failed")
    return assert(loadstring(librarySource, "@WordAutoTypeWindUI"))()
end)
if not libraryOk or type(libraryResult) ~= "table" then
    warn("Word Auto Type: WindUI could not be loaded.")
    Session.Unload()
    return
end
WindUI = libraryResult

local setupOk, setupError = xpcall(function()
    local theme = table.clone(WindUI:GetThemes().Dark)
    theme.Name = "WordGold"
    for name, hex in pairs({
        Accent = "211E16", Background = "151410", Dialog = "1D1B15", Text = "F5F0E5",
        Placeholder = "AAA18D", Icon = "F6B940", Toggle = "F6B940", Slider = "F6B940",
        Checkbox = "F6B940", Primary = "F6B940", Button = "332D20", ElementBackground = "242119",
        Outline = "A38A52", PanelBackground = "211E17",
    }) do theme[name] = Color3.fromHex(hex) end
    theme.PanelBackgroundTransparency = 0
    WindUI:AddTheme(theme)
    Window = WindUI:CreateWindow({
        Title = "Word Auto Type", Icon = "keyboard", Theme = "WordGold", NewElements = true,
        Size = UDim2.fromOffset(570, 530), MinSize = Vector2.new(350, 330), MaxSize = Vector2.new(850, 700),
        SideBarWidth = 130, AutoScale = false, Acrylic = false, HideSearchBar = true,
        OpenButton = {Title = "Word Auto Type", Enabled = true, Draggable = true, OnlyMobile = false,
            CornerRadius = UDim.new(1, 0), Color = ColorSequence.new(Color3.fromHex("F6B940"))},
    })
    Session.Window = Window
    Window:OnDestroy(function() Session.Unload(true) end)
    local main = Window:Tab({Title = "Main", Icon = "keyboard"})
    local settings = Window:Tab({Title = "Settings", Icon = "settings"})
    main:Button({Title = "Type Word", Icon = "text-cursor-input", Callback = Session.TypeWord})
    Controls.Auto = main:Toggle({Title = "Auto Type", Value = false, Callback = function(value)
        AutoEnabled = value
        if value then
            SuppressedTurn = nil
            Status = "Auto Type enabled"
        else
            ManualTurn = nil
            CancelTyping("Auto Type disabled", true)
        end
    end})
    Controls.Speed = main:Slider({Title = "Typing Speed", Desc = "Characters per second (0.01-100)", Step = 0.01, IsTooltip = true, IsTextbox = true,
        Value = {Min = 0.01, Max = 100, Default = 8}, Callback = function() GetSpeed() end})
    Controls.Smart = main:Toggle({Title = "Smart Typing", Value = false, Callback = function(value) SmartEnabled = value end})
    Controls.Mode = main:Dropdown({Title = "Word Mode", Values = {"Common", "Shortest", "Longest"}, Value = "Common",
        AllowNone = false, Callback = function(value)
            if type(value) == "table" then value = value.Title end
            if value == "Common" or value == "Shortest" or value == "Longest" then Mode = value end
        end})
    StatusPanel = main:Paragraph({Title = "Status", Desc = "Loading..."})
    settings:Section({Title = "Session"})
    Controls.AntiAfk = settings:Toggle({Title = "Anti AFK", Value = true, Callback = function(value) AntiAfkEnabled = value end})
    settings:Button({Title = "Stop All", Icon = "square", Callback = StopAll})
    Controls.Keybind = settings:Keybind({Title = "Menu Keybind", Value = "RightControl",
        Blacklist = {"Return", "KeypadEnter", "MouseLeftButton", "MouseRightButton"}, Callback = function() end})
    settings:Button({Title = "Unload", Icon = "power", Callback = function() Session.Unload() end})
    local configs = Window:Tab({Title = "Configs", Icon = "save"})
    configs:Section({Title = "Settings config"})
    configs:Input({Title = "Config name", Value = "default", Callback = function(value) Features.ConfigName = value end})
    configs:Toggle({Title = "Include custom words", Value = true, Callback = function(value) Features.IncludeWords = value end})
    configs:Button({Title = "Save config", Callback = function()
        Features.Safe(function() Features.Save(Features.ConfigName, false) end)
    end})
    configs:Button({Title = "Load config", Callback = function()
        Features.Safe(function() Features.Load(Features.ConfigName, false) end)
    end})
    configs:Section({Title = "Custom dictionary"})
    configs:Input({Title = "Add words", Desc = "Russian words, separated by spaces, commas or newlines", Type = "Textarea", Value = "",
        Callback = function(value) Features.Input = value end})
    configs:Button({Title = "Add to dictionary", Callback = function()
        Features.Safe(function()
            local incoming = Features.ParseWords(Features.Input)
            assert(#incoming > 0, "Enter Russian words (2-30 letters)")
            local words = table.clone(Features.Words)
            for _, word in ipairs(incoming) do table.insert(words, word) end
            assert(Features.Rebuild(words), "Dictionary loading cancelled")
            Notify("Custom words: " .. tostring(#Features.Words) .. " | Total: " .. tostring(WordCount))
        end)
    end})
    configs:Input({Title = "Words config name", Value = "words", Callback = function(value) Features.WordsName = value end})
    configs:Button({Title = "Save words only", Callback = function()
        Features.Safe(function() Features.Save(Features.WordsName, true) end)
    end})
    configs:Button({Title = "Load words (merge)", Callback = function()
        Features.Safe(function() Features.Load(Features.WordsName, true) end)
    end})

    settings:Section({Title = "Credits"})
    local function CopyLink(link)
        local copy = setclipboard or toclipboard
        if copy and pcall(copy, link) then
            Notify("Link copied to clipboard.")
        else
            if not CopyField then CopyField = settings:Input({Title = "Link", Type = "Textarea", Value = link, Callback = function() end}) end
            CopyField:Set(link)
            Notify("Select and copy the link below Credits.")
        end
    end
    Controls.Credits = settings:Button({Title = "Credits - @Lesxov", Icon = "copy", Callback = function() CopyLink("https://" .. CreditsAddress) end})
    settings:Button({Title = "UI Library - github.com/Footagesus/WindUI", Icon = "copy", Callback = function() CopyLink(LibraryUrl) end})
    main:Select()
end, debug.traceback)

if not setupOk then
    warn("Word Auto Type: interface setup failed: " .. tostring(setupError))
    Session.Unload()
    return
end

local CameraConnection
local function FitWindow()
    local camera = workspace.CurrentCamera
    if not Alive or not camera or Window.IsFullscreen then return end
    local viewport = camera.ViewportSize
    local size = Window.Size
    Window:SetUIScale(math.clamp(math.min((viewport.X - 24) / size.X.Offset, (viewport.Y - 24) / size.Y.Offset), 0.3, 1))
    Window:SetToTheCenter()
end
local function WatchCamera()
    if CameraConnection then CameraConnection:Disconnect() end
    local camera = workspace.CurrentCamera
    if camera then CameraConnection = Connect(camera:GetPropertyChangedSignal("ViewportSize"), FitWindow) end
    FitWindow()
end
Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), WatchCamera)
WatchCamera()
Window:OnClose(function()
    Spawn(function()
        task.wait(0.4)
        if Alive and Window.Closed and not Window.Destroyed then Window.OpenButtonMain:Visible(true) end
    end)
end)

Connect(InputService.InputBegan, function(input)
    local bind = Controls.Keybind
    if Alive and bind and not bind.Picking and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == bind.Value then
        Window:Toggle()
    elseif input.UserInputType == Enum.UserInputType.Keyboard and InputService:GetFocusedTextBox() == TypingBox then
        LastManualInput = os.clock()
        if Job and not AutoEnabled then CancelTyping("Paused: manual input detected", true) end
    end
end)

Connect(Player.Idled, function()
    if not Alive or not AntiAfkEnabled then return end
    local ok = pcall(function()
        local virtualUser = game:GetService("VirtualUser")
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.zero)
    end)
    if not ok then
        Controls.AntiAfk:Set(false)
        Notify("Anti AFK is unavailable in this executor.")
    end
end)


Features.Rebuild({})

Spawn(function()
    local nextSync = os.clock() + 2
    while Alive do
        task.wait(0.1)
        UpdateBox()
        for thread in pairs(Threads) do
            if coroutine.status(thread) == "dead" then Threads[thread] = nil end
        end
        if Pending and os.clock() - Pending.started > 5 then
            Completed[Pending.key] = true
            Pending = nil
            ManualTurn = nil
            Status = "No server confirmation; waiting for the next turn"
        end
        if os.clock() >= nextSync then
            nextSync = os.clock() + 15
            Action:FireServer("sync")
        end
        local state = CurrentState
        if EngineAvailable and WordCount > 0 and not Blocked() and os.clock() >= NextAttemptAt then
            if AutoEnabled and state and state.phase == "choosing" and state.chooser == state.you and type(state.choices) == "table" then
                local choiceKey = MatchKey(state) .. ":" .. tostring(state.round)
                if ChoiceSent ~= choiceKey then
                    local best, choices = -1, {}
                    for _, letter in ipairs(state.choices) do
                        local count = #CandidatePool(letter, math.huge)
                        if count > best then best, choices = count, {letter}
                        elseif count == best then table.insert(choices, letter) end
                    end
                    if best > 0 then
                        ChoiceSent = choiceKey
                        Action:FireServer("choose", choices[Randomizer:NextInteger(1, #choices)])
                        Status = "Letter selected"
                    else
                        Status = "No words available for these letters"
                    end
                end
            elseif (AutoEnabled or ManualTurn == CurrentTurn and ManualTurn ~= nil) and (AutoEnabled or SuppressedTurn ~= CurrentTurn) then
                StartTyping()
            end
        elseif Blocked() and not Job then
            Status = "Paused: text input or keybind selection"
        end
        if not state and not Job then Status = "Waiting for a match" end
        local roundCount = 0
        for _ in pairs(RoundWords) do roundCount = roundCount + 1 end
        local panelText = Status .. "\nWord: " .. SelectedWord .. "\nWords this round: " .. roundCount .. "\nDictionary: " .. DictionaryStatus
        if panelText ~= LastPanelText then
            LastPanelText = panelText
            StatusPanel.ParagraphFrame:SetDesc(panelText)
        end
    end
end)

if not EngineAvailable then Notify("This executor does not support word submission. Menu controls remain available.") end
Notify("Ready. Start a match, then use Type Word or enable Auto Type.")