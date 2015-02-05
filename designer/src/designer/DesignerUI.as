package designer
{
	import designer.commands.CloseCommand;
	import designer.commands.ExportCommand;
	import designer.commands.OpenCommand;
	import designer.commands.SelectCommand;
	import designer.commands.SettingCommand;
	import designer.commands.ZoomCommand;
	import designer.popups.DebugPopup;
	import designer.popups.Popup;
	import designer.utils.NativeMenuAdapter;

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
	import starling.filters.BlurFilter;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	public class DesignerUI extends Sprite
	{
		[Embed(source="/../assets/interface.zip", mimeType="application/octet-stream")]
		private static const INTERFACE:Class;

		private var _controller:DesignerController;

		private var _factory:TalonFactory;
		private var _interface:TalonSprite;
		private var _popupContainer:TalonSprite;
		private var _isolatorContainer:TalonSprite;
		private var _isolator:Sprite;
		private var _container:TalonSprite;

		private var _menu:NativeMenuAdapter;
		private var _prototype:DisplayObject;
		private var _locked:Boolean;

		public function DesignerUI(controller:DesignerController)
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

			_menu.addItem("file",         DesignerConstants.T_MENU_FILE);
			_menu.addItem("file/open",    DesignerConstants.T_MENU_FILE_OPEN,     new OpenCommand(_controller),   "o");
			_menu.addItem("file/close",   DesignerConstants.T_MENU_FILE_CLOSE,    new CloseCommand(_controller),  "w");
			_menu.addItem("file/-1");
			_menu.addItem("file/export",  DesignerConstants.T_MENU_FILE_EXPORT,   new ExportCommand(_controller), "s");

			_menu.addItem("view",                   DesignerConstants.T_MENU_VIEW);
			_menu.addItem("view/theme",             DesignerConstants.T_MENU_VIEW_BACKGROUND);
			_menu.addItem("view/theme/transparent", DesignerConstants.T_MENU_VIEW_BACKGROUND_CHESS, new SettingCommand(_controller, DesignerConstants.SETTING_BACKGROUND, DesignerConstants.SETTING_BACKGROUND_CHESS));
			_menu.addItem("view/theme/dark",        DesignerConstants.T_MENU_VIEW_BACKGROUND_DARK,  new SettingCommand(_controller, DesignerConstants.SETTING_BACKGROUND, DesignerConstants.SETTING_BACKGROUND_DARK));
			_menu.addItem("view/theme/light",       DesignerConstants.T_MENU_VIEW_BACKGROUND_LIGHT, new SettingCommand(_controller, DesignerConstants.SETTING_BACKGROUND, DesignerConstants.SETTING_BACKGROUND_LIGHT));
			_menu.addItem("view/stats",             DesignerConstants.T_MENU_VIEW_STATS,            new SettingCommand(_controller, DesignerConstants.SETTING_STATS, "1", "0"));
			_menu.addItem("view/-1");
			_menu.addItem("view/zoomIn",            DesignerConstants.T_MENU_VIEW_ZOOM_IN,          new ZoomCommand(_controller, +25),   "+");
			_menu.addItem("view/zoomOut",           DesignerConstants.T_MENU_VIEW_ZOOM_OUT,         new ZoomCommand(_controller, -25),   "-");
			_menu.addItem("view/-2");
			_menu.addItem("view/Device Orientation");
			_menu.addItem("view/Device Orientation/Portrait");
			_menu.addItem("view/Device Orientation/Landscape");
			_menu.addItem("view/Device Profile/Custom");
			_menu.addItem("view/Device Profile/-1");
			_menu.addItem("view/Device Profile/iPhone 4");
			_menu.addItem("view/Device Profile/iPhone 4s (Retina)");
			_menu.addItem("view/Device Profile/iPhone 5");
			_menu.addItem("view/Device Profile/iPhone 6");
			_menu.addItem("view/Device Profile/iPhone 6 Plus");
			_menu.addItem("view/Device Profile/iPad");
			_menu.addItem("view/Device Profile/iPad Air (Retina)");
			_menu.addItem("view/Device Profile/-2");
			_menu.addItem("view/Device Profile/Droid");
			_menu.addItem("view/Device Profile/Nexus One");
			_menu.addItem("view/Device Profile/Samsung Galaxy S");
			_menu.addItem("view/Device Profile/Samsung Galaxy Tab");
			_menu.addItem("view/Device Profile/-4");
			_menu.addItem("view/Device Profile/QVGA");
			_menu.addItem("view/Device Profile/VGA");
			_menu.addItem("view/Device Profile/FWQBGA");
			_menu.addItem("view/Device Profile/HVGA");
			_menu.addItem("view/Device Profile/-5");
			_menu.addItem("view/Device Profile/1080p");
			_menu.addItem("view/Device Profile/720p");
			_menu.addItem("view/Device Profile/480p");


			_menu.addItem("navigate",               DesignerConstants.T_MENU_NAVIGATE);


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
			_popupContainer.node.setAttribute(Attribute.LAYOUT, Layout.ABSOLUTE);
//			_popupContainer.node.setAttribute(Attribute.VALIGN, VAlign.CENTER);
//			_popupContainer.node.setAttribute(Attribute.HALIGN, HAlign.CENTER);

			_controller.settings.addSettingListener(DesignerConstants.SETTING_BACKGROUND, onBackgroundChange);
			_controller.settings.addSettingListener(DesignerConstants.SETTING_STATS, onStatsChange);
			_controller.settings.addSettingListener(DesignerConstants.SETTING_ZOOM, onZoomChange);

			_isolatorContainer = _interface.getChildByName("container") as TalonSprite;
			_isolatorContainer.addChild(_isolator);
			_isolatorContainer.addEventListener(TouchEvent.TOUCH, function(e:TouchEvent):void{if (e.getTouch(_isolatorContainer, TouchPhase.ENDED)) {

				return;
				var popup:Popup = new DebugPopup();
				popup.open();
				resizeTo(stage.stageWidth, stage.stageHeight);


			} });

			Popup.initialize(this, _popupContainer);

			stage && resizeTo(stage.stageWidth, stage.stageHeight);
		}

		private function onBackgroundChange(e:Event):void
		{
			_isolatorContainer.node.classes = new <String>[_controller.settings.getValueOrDefault(DesignerConstants.SETTING_BACKGROUND, DesignerConstants.SETTING_BACKGROUND_CHESS)];
		}

		private function onStatsChange(e:Event):void
		{
			Starling.current.showStats = parseInt(_controller.settings.getValueOrDefault(DesignerConstants.SETTING_STATS)) > 0;
		}

		private function onZoomChange(e:Event):void
		{
			zoom = _controller.settings.getValueOrDefault(DesignerConstants.SETTING_ZOOM, 100) / 100;
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