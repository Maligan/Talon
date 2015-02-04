package designer
{
	import designer.commands.CloseCommand;
	import designer.commands.ExportCommand;
	import designer.commands.OpenCommand;
	import designer.commands.SelectCommand;
	import designer.commands.StatsCommand;
	import designer.commands.ThemeCommand;
	import designer.popups.DebugPopup;
	import designer.popups.Popup;
	import designer.utils.NativeMenuAdapter;

	import flash.desktop.NativeApplication;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;

	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.talon.core.Attribute;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.display.ITalonElement;
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
			_isolator.scaleX = _isolator.scaleY = 1;
			_isolator.addChild(_container);
		}

		private function initializeNativeMenu():void
		{
			_menu = new NativeMenuAdapter();

			_menu.addItem("file",         DesignerConstants.T_MENU_FILE);
			_menu.addItem("file/open",    DesignerConstants.T_MENU_FILE_OPEN,     new OpenCommand(_controller),   "o");
			_menu.addItem("file/close",   DesignerConstants.T_MENU_FILE_CLOSE,    new CloseCommand(_controller),  "w");
			_menu.addItem("file/-");
			_menu.addItem("file/export",  DesignerConstants.T_MENU_FILE_EXPORT,   new ExportCommand(_controller), "s");

			_menu.addItem("view",                   DesignerConstants.T_MENU_VIEW);
			_menu.addItem("view/theme",             DesignerConstants.T_MENU_VIEW_BACKGROUND);
			_menu.addItem("view/theme/transparent", DesignerConstants.T_MENU_VIEW_BACKGROUND_CHESS, new ThemeCommand(_controller, "transparent"));
			_menu.addItem("view/theme/dark",        DesignerConstants.T_MENU_VIEW_BACKGROUND_GRAY,  new ThemeCommand(_controller, "dark"));
			_menu.addItem("view/theme/light",       DesignerConstants.T_MENU_VIEW_BACKGROUND_WHITE, new ThemeCommand(_controller, "light"));
			_menu.addItem("view/stats",             DesignerConstants.T_MENU_VIEW_STATS,            new StatsCommand());

			_menu.addItem("navigate",     DesignerConstants.T_MENU_NAVIGATE);


			NativeApplication.nativeApplication.activeWindow.menu = _menu.menu;
		}

		private function initializePopups():void
		{
			Popup.initialize(_popupContainer, _factory, onToggle);

			function onToggle():void
			{
				_isolatorContainer.filter = Popup.isActive ? new BlurFilter(5, 5) : null;
				_interface.getChildByName("shade").visible = Popup.isActive;
			}
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

			_isolatorContainer = _interface.getChildByName("container") as TalonSprite;
			_isolatorContainer.addChild(_isolator);
			_isolatorContainer.addEventListener(TouchEvent.TOUCH, function(e:TouchEvent):void{if (e.getTouch(_isolatorContainer, TouchPhase.ENDED)) { new DebugPopup().show(); resizeTo(stage.stageWidth, stage.stageHeight) } })

			initializeNativeMenu();
			initializePopups();

			stage && resizeTo(stage.stageWidth, stage.stageHeight);
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
				_container.node.bounds.setTo(0, 0, width, height);
				_container.node.commit();
			}
		}

		//
		// Properties
		//
		public function get isolatorContainer():TalonSprite
		{
			return _isolatorContainer;
		}
	}
}