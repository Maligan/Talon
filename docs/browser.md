# Браузер

Лично мне очень нравится идея интерактивного программирования. По-этому я хотел бы поделится этим с вами - Talon Brower это часть Talon-а которая создана для предпросмотра UI шабловнов вне вашего приложения. Только представте, вам не нужно запускать целиком приложение чтобы проверить как оно будет выглядить для пользователя, больше не нужно перемещать элементы по пикселям, компилировать и сново запускть приложение.
Talon Browser - утилита котороая позволяет просматривать как будут выглядить ваше приложение на разных устройствах.

Давайте просмотрим как с ним работать. Запустите браузер и что вы увидите:
![](img/browser_1.png)

Первое на что хочется обратить внимание это заголовок окна - он содержит полезную информацию:
* Профиль устройства которое симулируется: высота x ширина, плотность пиксилей и коэфициент масштабирования (ретина x2)
* Имя профиля если он с чем-то совпадает (iPhone, iPad и т.п.)
* Масштаб просмотра (его может не быть если увеличение\уменьшение не используется)
* Версия браузера

#### Формат документ-файла






	Application
		+ starling
		+ stage
		+ settings
			* getProperty(name:String)
			* setProperty(name:String, value:*)
		+ profile
			* width
			* height
			* dpi
			* csf
		+ plugins
			* registerPlugin(plugin:IPlugin)
			* attach(plugin:IPlugin)
			* detach(plugin:IPlugin)
		+ document
			* registerFileType(checker:Function, type:Class)
			* messages
			* factory
			* assets
			* tasks
		- commands
			* registerCommand(name:String, type:Class)
			* execute(name:String, data:Object = null)
		- popups
			* registerPopup(name:String, type:Class)
			* open(popup:Popup, data:Object)
			* openByName(name:String, data:Object)
		- host
		- factory
		- menu
