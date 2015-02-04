package designer
{
	import designer.commands.CloseCommand;
	import designer.commands.ExportCommand;
	import designer.commands.OpenCommand;
	import designer.commands.SelectCommand;
	import designer.menu.NativeMenuAdapter;

	import flash.desktop.NativeApplication;
	import flash.utils.ByteArray;

	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.display.ITalonElement;
	import starling.extensions.talon.display.TalonFactory;
	import starling.extensions.talon.display.TalonSprite;

	public class DesignerInterface extends Sprite
	{
		[Embed(source="/../assets/interface.zip", mimeType="application/octet-stream")]
		private static const INTERFACE:Class;

		private var _factory:TalonFactory;
		private var _interface:TalonSprite;
		private var _layer:Sprite;
		private var _container:TalonSprite;
		private var _controller:DesignerController;

		private var _menu:NativeMenuAdapter;
		private var _prototype:DisplayObject;

		public function DesignerInterface(controller:DesignerController)
		{
			_controller = controller;

			_factory = new TalonFactory();
			_factory.addEventListener(Event.COMPLETE, onFactoryComplete);
			_factory.addArchiveAsync(new INTERFACE() as ByteArray);

			_layer = new Sprite();
			_layer.scaleX = _layer.scaleY = 1;
			initializeNativeMenu();
		}

		private function initializeNativeMenu():void
		{
			_menu = new NativeMenuAdapter();

			_menu.addItem("file",         DesignerConstants.T_MENU_FILE);
			_menu.addItem("file/open",    DesignerConstants.T_MENU_FILE_OPEN,     new OpenCommand(_controller),   "o");
			_menu.addItem("file/close",   DesignerConstants.T_MENU_FILE_CLOSE,    new CloseCommand(_controller),  "w");
			_menu.addItem("file/-");
			_menu.addItem("file/export",  DesignerConstants.T_MENU_FILE_EXPORT,   new ExportCommand(_controller), "s");

			_menu.addItem("navigate",     DesignerConstants.T_MENU_NAVIGATE);

			NativeApplication.nativeApplication.activeWindow.menu = _menu.menu;
		}

		//
		// Logic
		//
		private function onFactoryComplete(e:Event):void
		{
			_interface = _factory.build("interface") as TalonSprite;
			_container = _interface.getChildByName("container") as TalonSprite;
			_container.addChild(_layer);
			stage && resizeTo(stage.stageWidth, stage.stageHeight);

			addChild(_interface);
		}
		public function showPrototype(prototypeId:String):void
		{
			_prototype = _controller.document.factory.build(prototypeId);
			_layer.removeChildren();
			_layer.addChild(_prototype);
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

			_layer.removeChildren();

			if (canShow)
			{
				_prototype = _controller.document.factory.build(_controller.prototypeId);
				_layer.addChild(_prototype);
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

			if (_prototype is ITalonElement)
			{
				var node:Node = ITalonElement(_prototype).node;
				node.bounds.setTo(0, 0, _container.node.bounds.width/_layer.scaleX, _container.node.bounds.height/_layer.scaleY);
				node.commit();
			}
		}
	}
}