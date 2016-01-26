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
