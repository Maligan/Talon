package browser
{
	import browser.commands.CloseCommand;
	import browser.commands.NewProjectCommand;
	import browser.commands.ExportCommand;
	import browser.commands.OpenCommand;
	import browser.commands.OrientationCommand;
	import browser.commands.ProfileCommand;
	import browser.commands.SelectCommand;
	import browser.commands.SettingCommand;
	import browser.commands.ZoomCommand;
	import browser.dom.DocumentEvent;
	import browser.dom.log.DocumentMessage;
	import browser.popups.Popup;
	import browser.AppConstants;
	import browser.utils.DeviceProfile;
	import browser.utils.EventDispatcherAdapter;
	import browser.utils.NativeMenuAdapter;

	import flash.desktop.NativeApplication;
	import flash.events.UncaughtErrorEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.TouchEvent;

	import talon.Attribute;
	import talon.starling.TalonFactoryStarling;
	import talon.utils.ITalonElement;
	import talon.utils.TalonFactoryBase;
	import talon.starling.TalonSprite;
	import talon.layout.Layout;
	import talon.enums.Orientation;
	import starling.filters.BlurFilter;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	public class AppUI extends Sprite
	{
		[Embed(source="/../assets/interface.zip", mimeType="application/octet-stream")]
		private static const INTERFACE:Class;

		private var _controller:AppController;

		private var _factory:TalonFactoryBase;
		private var _interface:TalonSprite;
		private var _errorPage:TalonSprite;
		private var _popupContainer:TalonSprite;
		private var _isolatorContainer:TalonSprite;
		private var _isolator:Sprite;
		private var _container:TalonSprite;

		private var _documentDispatcher:EventDispatcherAdapter;
		private var _menu:NativeMenuAdapter;
		private var _template:DisplayObject;
		private var _templateProduceMessage:DocumentMessage;
		private var _locked:Boolean;

		public function AppUI(controller:AppController)
		{
			_controller = controller;
			_controller.addEventListener(AppController.EVENT_PROFILE_CHANGE, refreshWindowTitle);
			_controller.addEventListener(AppController.EVENT_PROTOTYPE_CHANGE, refreshCurrentTemplate);
			_controller.addEventListener(AppController.EVENT_DOCUMENT_CHANGE, onDocumentChange);

			_documentDispatcher = new EventDispatcherAdapter();
			_documentDispatcher.addEventListener(DocumentEvent.CHANGED, onDocumentChanged);

			_factory = new TalonFactoryStarling();
			_factory.addArchiveContentAsync(new INTERFACE() as ByteArray, onFactoryComplete);

			_container = new TalonSprite();
			_container.node.setAttribute(Attribute.LAYOUT, Layout.ABSOLUTE);
			_container.node.setAttribute(Attribute.VALIGN, VAlign.CENTER);
			_container.node.setAttribute(Attribute.HALIGN, HAlign.CENTER);

			_isolator = new Sprite();
			_isolator.addChild(_container);

			setTimeout(initializeNativeMenu, 1);
		}

		private function initializeNativeMenu():void
		{
			_menu = new NativeMenuAdapter();

			_menu.addItem("file",         AppConstants.T_MENU_FILE);
			_menu.addItem("file/new",     AppConstants.T_MENU_FILE_NEW_PROJECT,    new NewProjectCommand(_controller), "n", 3);
			_menu.addItem("file/open",    AppConstants.T_MENU_FILE_OPEN,           new OpenCommand(_controller),   "o", 2);
			_menu.addItem("file/close",   AppConstants.T_MENU_FILE_CLOSE,          new CloseCommand(_controller),  "w");
			_menu.addItem("file/-1");
			_menu.addItem("file/export",  AppConstants.T_MENU_FILE_EXPORT_AS,      new ExportCommand(_controller), "s");

			_menu.addItem("view",                       AppConstants.T_MENU_VIEW);
			_menu.addItem("view/theme",                 AppConstants.T_MENU_VIEW_BACKGROUND);
			_menu.addItem("view/theme/transparent",     AppConstants.T_MENU_VIEW_BACKGROUND_CHESS, new SettingCommand(_controller, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_CHESS));
			_menu.addItem("view/theme/dark",            AppConstants.T_MENU_VIEW_BACKGROUND_DARK,  new SettingCommand(_controller, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_DARK));
			_menu.addItem("view/theme/light",           AppConstants.T_MENU_VIEW_BACKGROUND_LIGHT, new SettingCommand(_controller, AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_LIGHT));
			_menu.addItem("view/stats",                 AppConstants.T_MENU_VIEW_STATS,            new SettingCommand(_controller, AppConstants.SETTING_STATS, true, false));
			_menu.addItem("view/resize",                AppConstants.T_MENU_VIEW_LOCK_RESIZE,      new SettingCommand(_controller, AppConstants.SETTING_LOCK_RESIZE, true, false));
			_menu.addItem("view/alwaysOnTop",           AppConstants.T_MENU_VIEW_ALWAYS_ON_TOP,    new SettingCommand(_controller, AppConstants.SETTING_ALWAYS_ON_TOP, true, false));
			_menu.addItem("view/-1");
			_menu.addItem("view/zoomIn",                AppConstants.T_MENU_VIEW_ZOOM_IN,          new ZoomCommand(_controller, +25),   "+");
			_menu.addItem("view/zoomOut",               AppConstants.T_MENU_VIEW_ZOOM_OUT,         new ZoomCommand(_controller, -25),   "-");
			_menu.addItem("view/-2");
			_menu.addItem("view/orientation",           AppConstants.T_MENU_VIEW_ORIENTATION);
			_menu.addItem("view/orientation/Portrait",  AppConstants.T_MENU_VIEW_ORIENTATION_PORTRAIT,     new OrientationCommand(_controller, Orientation.VERTICAL));
			_menu.addItem("view/orientation/Landscape", AppConstants.T_MENU_VIEW_ORIENTATION_LANDSCAPE,    new OrientationCommand(_controller, Orientation.HORIZONTAL));

			_menu.addItem("view/profile",               AppConstants.T_MENU_VIEW_PROFILE);
			_menu.addItem("view/profile/custom",        AppConstants.T_MENU_VIEW_PROFILE_CUSTOM, new ProfileCommand(_controller, DeviceProfile.CUSTOM));
			_menu.addItem("view/profile/-1");
			for each (var profile:DeviceProfile in DeviceProfile.getProfiles())
				_menu.addItem("view/profile/" + profile.id, null, new ProfileCommand(_controller, profile));

			_controller.settings.addSettingListener(AppConstants.SETTING_RECENT_ARRAY, refreshRecent);
			refreshRecent();

			NativeApplication.nativeApplication.activeWindow.menu = _menu.menu;
		}

		//
		// Logic
		//
		private function onFactoryComplete():void
		{
			_interface = _factory.produce("interface") as TalonSprite;
			addChild(_interface);

			_interface.getChildByName("shade").visible = false;

			_errorPage = _interface.getChildByName("bsod") as TalonSprite;
			_errorPage.visible = false;

			_popupContainer = _interface.getChildByName("popups") as TalonSprite;
			_isolatorContainer = _interface.getChildByName("container") as TalonSprite;
			_isolatorContainer.addChild(_isolator);
			Popup.initialize(this, _popupContainer);

			_controller.settings.addSettingListener(AppConstants.SETTING_BACKGROUND, onBackgroundChange); onBackgroundChange(null);
			_controller.settings.addSettingListener(AppConstants.SETTING_STATS, onStatsChange); onStatsChange(null);
			_controller.settings.addSettingListener(AppConstants.SETTING_ZOOM, onZoomChange); onZoomChange(null);
			_controller.settings.addSettingListener(AppConstants.SETTING_ALWAYS_ON_TOP, onAlwaysOnTopChange); onAlwaysOnTopChange(null);

			stage && resizeTo(stage.stageWidth, stage.stageHeight);
		}

		private function onBackgroundChange(e:Event):void
		{
			_isolatorContainer.node.classes = new <String>[_controller.settings.getValueOrDefault(AppConstants.SETTING_BACKGROUND, AppConstants.SETTING_BACKGROUND_DEFAULT)];
		}

		private function onStatsChange(e:Event):void
		{
			Starling.current.showStats = _controller.settings.getValueOrDefault(AppConstants.SETTING_STATS, false);
		}

		private function onZoomChange(e:Event):void
		{
			zoom = _controller.settings.getValueOrDefault(AppConstants.SETTING_ZOOM, 100) / 100;
		}

		private function onAlwaysOnTopChange(e:Event):void
		{
			_controller.root.stage.nativeWindow.alwaysInFront = _controller.settings.getValueOrDefault(AppConstants.SETTING_ALWAYS_ON_TOP, false);
		}

		private function onDocumentChange(e:Event):void
		{
			_documentDispatcher.target = _controller.document;
		}

		public function resizeTo(width:int, height:int):void
		{
			if (_interface)
			{
				_interface.node.bounds.setTo(0, 0, width, height);
				_interface.node.commit();
			}

			if (_container)
			{
				_container.node.bounds.setTo(0, 0, width/zoom, height/zoom);
				_container.node.commit();
			}
		}

		private function onDocumentChanged(e:Event):void
		{
			refreshTemplates();
			refreshCurrentTemplate();
		}

		//
		// Refresh
		//
		private function refreshWindowTitle():void
		{
			var result:Array = [];

			if (_controller.document)
				result.push(_controller.document.project.nativePath);

			var profile:DeviceProfile = _controller.profile;
			if (profile != DeviceProfile.CUSTOM) result.push(_controller.profile.id);
			else result.push("[" + profile.width + "x" + profile.height + ", CSF=" + profile.csf + ", DPI=" + profile.dpi + "]")

			if (_controller.templateId)
				result.push(_controller.templateId);

			result.push(AppConstants.APP_NAME + " " + AppConstants.APP_VERSION);

			_controller.root.stage.nativeWindow.title = result.join(" - ");
		}

		private function refreshTemplates():void
		{
			// Refresh Menu
			_menu.removeItem("navigate");

			if (_controller.document && _controller.document.factory.templateIds.length > 0)
			{
				_menu.addItem("navigate", AppConstants.T_MENU_NAVIGATE);
				_menu.addItem("navigate/search", AppConstants.T_MENU_NAVIGATE_SEARCH);
				_menu.addItem("navigate/-");

				for each (var prototypeId:String in _controller.document.factory.templateIds)
				{
					_menu.addItem("navigate/" + prototypeId, null, new SelectCommand(_controller, prototypeId));
				}
			}
		}

		private function refreshCurrentTemplate():void
		{
			// Refresh current prototype
			var canShow:Boolean = true;
			canShow &&= _controller.templateId != null;
			canShow &&= _controller.document != null;
			canShow &&= _controller.document.factory.hasTemplate(_controller.templateId);

			_errorPage.visible = false;
			_container.removeChildren();
			_controller.document && _controller.document.messages.removeMessage(_templateProduceMessage);
			_templateProduceMessage = null;

			_template = canShow ? produce(_controller.templateId) : null;

			// Show state
			if (_controller.document && _controller.document.messages.numMessages != 0)
			{
				_errorPage.visible = true;
			}
			else if (_template != null)
			{
				_container.addChild(_template);
				stage && resizeTo(stage.stageWidth, stage.stageHeight);
			}
		}

		private function produce(templateId:String):DisplayObject
		{
			var result:DisplayObject = null;

			try
			{
				result = _controller.document.factory.produce(templateId);
			}
			catch (e:Error)
			{
				_templateProduceMessage = new DocumentMessage(DocumentMessage.PRODUCE_ERROR, [templateId, e.message]);
				_controller.document.messages.addMessage(_templateProduceMessage);
			}

			return result;
		}

		private function refreshRecent():void
		{
			// Refresh recent files
			_menu.removeItem("file/recent");
			var recent:Array = _controller.settings.getValueOrDefault(AppConstants.SETTING_RECENT_ARRAY, []);
			if (recent.length > 0)
			{
				_menu.addItem("file/recent",  AppConstants.T_MENU_FILE_RECENT, null, null, 1);

				for each (var path:String in recent)
				{
					var file:File = new File(path);
					if (file.exists)
					{
						_menu.addItem("file/recent/" + path, null, new OpenCommand(_controller, file));
					}
				}

				_menu.addItem("file/recent/-1");
				_menu.addItem("file/recent/clear", AppConstants.T_MENU_FILE_RECENT_CLEAR, new SettingCommand(_controller, AppConstants.SETTING_RECENT_ARRAY, []));
			}
		}

		//
		// Properties
		//
		public function get factory():TalonFactoryBase { return _factory; }

		public function get locked():Boolean { return _locked; }
		public function set locked(value:Boolean):void
		{
			if (_locked != value)
			{
				_locked = value;
				_interface.getChildByName("shade").visible = locked;
				_isolatorContainer.filter = _locked ? new BlurFilter(1, 1) : null;
				_isolatorContainer.touchable = !_locked;
			}
		}

		public function get zoom():Number { return _isolator.scaleX; }
		public function set zoom(value:Number):void
		{
			if (zoom != value)
			{
				_isolator.scaleX = _isolator.scaleY = value;
				resizeTo(stage.stageWidth, stage.stageHeight);
			}
		}

		public function get template():DisplayObject
		{
			return _template;
		}
	}
}