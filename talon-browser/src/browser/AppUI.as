package browser
{
	import browser.commands.CloseCommand;
	import browser.commands.ExportCommand;
	import browser.commands.OpenCommand;
	import browser.commands.OrientationCommand;
	import browser.commands.ProfileCommand;
	import browser.commands.SelectCommand;
	import browser.commands.SettingCommand;
	import browser.commands.ZoomCommand;
	import browser.popups.ProfilePopup;
	import browser.popups.Popup;
	import browser.utils.Constants;
	import browser.utils.DeviceProfile;
	import browser.utils.NativeMenuAdapter;

	import flash.desktop.NativeApplication;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowRenderMode;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;

	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.talon.core.Attribute;
	import starling.extensions.talon.display.TalonFactory;
	import starling.extensions.talon.display.TalonSprite;
	import starling.extensions.talon.layout.Layout;
	import starling.extensions.talon.utils.Orientation;
	import starling.filters.BlurFilter;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	public class AppUI extends Sprite
	{
		[Embed(source="/../assets/interface.zip", mimeType="application/octet-stream")]
		private static const INTERFACE:Class;

		private var _controller:AppController;

		private var _factory:TalonFactory;
		private var _interface:TalonSprite;
		private var _popupContainer:TalonSprite;
		private var _isolatorContainer:TalonSprite;
		private var _isolator:Sprite;
		private var _container:TalonSprite;

		private var _menu:NativeMenuAdapter;
		private var _prototype:DisplayObject;
		private var _locked:Boolean;

		public function AppUI(controller:AppController)
		{
			_controller = controller;

			_factory = new TalonFactory();
			_factory.addEventListener(Event.COMPLETE, onFactoryComplete);
			_factory.addArchiveAsync(new INTERFACE() as ByteArray);

			_container = new TalonSprite();
			_container.node.setAttribute(Attribute.LAYOUT, Layout.FLOW);
			_container.node.setAttribute(Attribute.VALIGN, VAlign.CENTER);
			_container.node.setAttribute(Attribute.HALIGN, HAlign.CENTER);

			_isolator = new Sprite();
			_isolator.addChild(_container);

			setTimeout(initializeNativeMenu, 1);
		}

		private function initializeNativeMenu():void
		{
			_menu = new NativeMenuAdapter();

			_menu.addItem("file",         Constants.T_MENU_FILE);
			_menu.addItem("file/open",    Constants.T_MENU_FILE_OPEN,     new OpenCommand(_controller),   "o");
			_menu.addItem("file/close",   Constants.T_MENU_FILE_CLOSE,    new CloseCommand(_controller),  "w");
			_menu.addItem("file/-1");
			_menu.addItem("file/export",  Constants.T_MENU_FILE_EXPORT,   new ExportCommand(_controller), "s");

			_menu.addItem("view",                       Constants.T_MENU_VIEW);
			_menu.addItem("view/theme",                 Constants.T_MENU_VIEW_BACKGROUND);
			_menu.addItem("view/theme/transparent",     Constants.T_MENU_VIEW_BACKGROUND_CHESS, new SettingCommand(_controller, Constants.SETTING_BACKGROUND, Constants.SETTING_BACKGROUND_CHESS));
			_menu.addItem("view/theme/dark",            Constants.T_MENU_VIEW_BACKGROUND_DARK,  new SettingCommand(_controller, Constants.SETTING_BACKGROUND, Constants.SETTING_BACKGROUND_DARK));
			_menu.addItem("view/theme/light",           Constants.T_MENU_VIEW_BACKGROUND_LIGHT, new SettingCommand(_controller, Constants.SETTING_BACKGROUND, Constants.SETTING_BACKGROUND_LIGHT));
			_menu.addItem("view/stats",                 Constants.T_MENU_VIEW_STATS,            new SettingCommand(_controller, Constants.SETTING_STATS, true, false));
			_menu.addItem("view/resize",                Constants.T_MENU_VIEW_LOCK_RESIZE,      new SettingCommand(_controller, Constants.SETTING_LOCK_RESIZE, true, false));
			_menu.addItem("view/-1");
			_menu.addItem("view/zoomIn",                Constants.T_MENU_VIEW_ZOOM_IN,          new ZoomCommand(_controller, +25),   "+");
			_menu.addItem("view/zoomOut",               Constants.T_MENU_VIEW_ZOOM_OUT,         new ZoomCommand(_controller, -25),   "-");
			_menu.addItem("view/-2");
			_menu.addItem("view/orientation",           Constants.T_MENU_VIEW_ORIENTATION);
			_menu.addItem("view/orientation/Portrait",  Constants.T_MENU_VIEW_ORIENTATION_PORTRAIT,     new OrientationCommand(_controller, Orientation.VERTICAL));
			_menu.addItem("view/orientation/Landscape", Constants.T_MENU_VIEW_ORIENTATION_LANDSCAPE,    new OrientationCommand(_controller, Orientation.HORIZONTAL));

			_menu.addItem("view/profile",               Constants.T_MENU_VIEW_PROFILE);
			_menu.addItem("view/profile/custom",        Constants.T_MENU_VIEW_PROFILE_CUSTOM, new ProfileCommand(_controller, DeviceProfile.CUSTOM));
			_menu.addItem("view/profile/-1");
			for each (var profile:DeviceProfile in DeviceProfile.getProfiles())
				_menu.addItem("view/profile/" + profile.id, null, new ProfileCommand(_controller, profile));

			_menu.addItem("navigate",               Constants.T_MENU_NAVIGATE);


			NativeApplication.nativeApplication.activeWindow.menu = _menu.menu;
		}

		//
		// Logic
		//
		private function onFactoryComplete(e:Event):void
		{
			_interface = _factory.build("interface") as TalonSprite;
			addChild(_interface);

			_interface.getChildByName("shade").visible = false;

			_popupContainer = _interface.getChildByName("popups") as TalonSprite;
			_isolatorContainer = _interface.getChildByName("container") as TalonSprite;
			_isolatorContainer.addChild(_isolator);
			Popup.initialize(this, _popupContainer);


			_controller.settings.addSettingListener(Constants.SETTING_BACKGROUND, onBackgroundChange); onBackgroundChange(null);
			_controller.settings.addSettingListener(Constants.SETTING_STATS, onStatsChange); onStatsChange(null);
			_controller.settings.addSettingListener(Constants.SETTING_ZOOM, onZoomChange); onZoomChange(null);

			stage && resizeTo(stage.stageWidth, stage.stageHeight);
		}

		private function onBackgroundChange(e:Event):void
		{
			_isolatorContainer.node.classes = new <String>[_controller.settings.getValueOrDefault(Constants.SETTING_BACKGROUND, Constants.SETTING_BACKGROUND_CHESS)];
		}

		private function onStatsChange(e:Event):void
		{
			Starling.current.showStats = _controller.settings.getValueOrDefault(Constants.SETTING_STATS, false);
		}

		private function onZoomChange(e:Event):void
		{
			zoom = _controller.settings.getValueOrDefault(Constants.SETTING_ZOOM, 100) / 100;
		}

		public function refresh():void
		{
			// Refresh Menu
			_menu.removeItemChildren("navigate");

			if (_controller.document != null)
			{
				for each (var prototypeId:String in _controller.document.factory.prototypeIds)
				{
					_menu.addItem("navigate/" + prototypeId, null, new SelectCommand(_controller, prototypeId));
				}
			}

			// Refresh current prototype
			var canShow:Boolean = true;
			canShow &&= _controller.prototypeId != null;
			canShow &&= _controller.document != null;
			canShow &&= _controller.document.factory.hasPrototype(_controller.prototypeId);

			_container.removeChildren();

			if (canShow)
			{
				_prototype = _controller.document.factory.build(_controller.prototypeId);
				_container.addChild(_prototype);

				stage && resizeTo(stage.stageWidth, stage.stageHeight);
			}
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


		public function get factory():TalonFactory { return _factory; }

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
	}
}