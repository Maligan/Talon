package designer.popups
{
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	import starling.events.Event;

	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.display.ITalonElement;
	import starling.extensions.talon.display.TalonFactory;
	import starling.extensions.talon.display.TalonSprite;

	public class Popup extends TalonSprite implements ITalonElement
	{
		private static var _layer:DisplayObjectContainer;
		private static var _factory:TalonFactory;
		private static var _queue:Vector.<Popup>;
		private static var _active:Vector.<Popup>;
		private static var _onActiveChange:Function;

		public static function initialize(layer:DisplayObjectContainer, factory:TalonFactory, onActiveChange:Function = null):void
		{
			if (_layer != null) throw new ArgumentError("Already initialized");

			_layer = layer;
			_factory = factory;
			_onActiveChange = onActiveChange;
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

		public final function show(modal:Boolean = true):void
		{
			if (isActive) return;

			if (_queue.length == 0)
			{
				_active.push(this);
				_layer.addChild(this);
				_onActiveChange && _onActiveChange();
			}
			else if (modal)
			{
				_active.push(this);
				_layer.addChild(this);
			}
			else
			{
				_queue.push(this);
			}
		}

		public final function hide():void
		{
			if (!isActive) return;

			_active.splice(_active.indexOf(this), 1);
			removeFromParent(true);

			if (_queue.length > 0)
			{
				var popup:Popup = _queue.shift();
				_layer.addChild(popup);
			}

			if (_queue.length == 0 && _active.length == 0)
			{
				_onActiveChange && _onActiveChange();
			}
		}

		public final function get isActive():Boolean
		{
			return _active.indexOf(this) != -1;
		}

		public final function get factory():TalonFactory
		{
			return _factory;
		}
	}
}
