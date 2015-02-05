package designer.popups
{
	import designer.DesignerUI;

	import flash.utils.Dictionary;

	import starling.display.DisplayObjectContainer;
	import starling.extensions.talon.display.ITalonElement;
	import starling.extensions.talon.display.TalonFactory;
	import starling.extensions.talon.display.TalonSprite;

	public class Popup extends TalonSprite implements ITalonElement
	{
		private static var _ui:DesignerUI;
		private static var _layer:DisplayObjectContainer;
		private static var _queue:Vector.<Popup>;
		private static var _active:Vector.<Popup>;
		private static var _modal:Dictionary = new Dictionary(true);

		public static function initialize(ui:DesignerUI, layer:DisplayObjectContainer):void
		{
			if (_layer != null) throw new ArgumentError("Already initialized");

			_ui = ui;
			_layer = layer;
			_queue = new <Popup>[];
			_active = new <Popup>[];
		}

		public static function get isActive():Boolean
		{
			return _active.length > 0
				|| _queue.length > 0;
		}

		public function Popup():void
		{
			node.position.parse("50%");
			node.pivot.parse("50%");
		}

		public final function open(modal:Boolean = true):void
		{
			if (isActive) return;

			if (modal)
			{
				_active.push(this);
				_layer.addChild(this);
				_ui.locked = true;
				_modal[this] = true;
			}
			else if (_queue.length == 0)
			{
				_active.push(this);
				_layer.addChild(this);
			}
			else
			{
				_queue.push(this);
			}
		}

		public final function close():void
		{
			if (!isActive) return;

			_active.splice(_active.indexOf(this), 1);
			delete _modal[this];
			removeFromParent(true);

			if (_queue.length > 0)
			{
				var popup:Popup = _queue.shift();
				_layer.addChild(popup);
			}

			if (_queue.length == 0 && _active.length == 0)
			{
				_ui.locked = false;
			}
		}

		public final function get isActive():Boolean
		{
			return _active.indexOf(this) != -1;
		}

		public final function get factory():TalonFactory
		{
			return _ui.factory;
		}
	}
}
