package talon.browser.popups
{
	import starling.errors.AbstractMethodError;
	import starling.events.KeyboardEvent;

	import talon.starling.TalonSprite;
	import talon.utils.ITalonElement;

	public class Popup extends TalonSprite implements ITalonElement
	{
		private var _manager:PopupManager;
		private var _data:Object;

		internal final function ctor(manager:PopupManager, data:Object = null):void
		{
			node.position.parse("50%");
			node.pivot.parse("50%");

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

		protected final function get manager():PopupManager
		{
			return _manager;
		}

		//
		// Code sugar
		//
		protected final function close():void
		{
			manager.close(this);
		}

		protected final function addKeyboardListener(keyCode:int, listener:Function, type:String = KeyboardEvent.KEY_DOWN):void
		{
			addEventListener(type, function(e:KeyboardEvent):void
			{
				if (e.keyCode == keyCode)
					listener.length
						? listener(e)
						: listener();
			});
		}
	}
}