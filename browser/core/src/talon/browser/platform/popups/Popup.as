package talon.browser.platform.popups
{
	import starling.animation.Juggler;
	import starling.errors.AbstractMethodError;
	import starling.events.KeyboardEvent;
	import starling.extensions.TalonQuery;
	import starling.extensions.TalonSpriteElement;

	import talon.Attribute;

	public class Popup extends TalonSpriteElement
	{
		private var _manager:PopupManager;
		private var _data:Object;
		private var _query:TalonQuery;
		private var _juggler:Juggler;

		internal final function ctor(manager:PopupManager, data:Object = null):void
		{
			node.setAttribute(Attribute.POSITION, "50%");

			_query = new TalonQuery(this);
			_manager = manager;
			_data = data;

			initialize();
		}

		protected function initialize():void
		{
			throw new AbstractMethodError();
		}

		protected final function get data():Object
		{
			return _data;
		}

		protected final function get juggler():Juggler
		{
			return _juggler;
		}

		protected final function get manager():PopupManager
		{
			return _manager;
		}

		//
		// Code sugar
		//
		protected final function query(selector:String):TalonQuery
		{
			return _query.reset(this).select(selector);
		}

		protected final function close():void
		{
			manager.close(this);
			dispose();
		}

		protected final function addKeyboardListener(keyCode:int = -1, listener:Function = null, type:String = KeyboardEvent.KEY_DOWN):void
		{
			addEventListener(type, function(e:KeyboardEvent):void
			{
				if (keyCode == -1 || keyCode == e.keyCode)
					listener.length
						? listener(e)
						: listener();
			});
		}
	}
}