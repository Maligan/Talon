package talon.browser.core.popups
{
	import starling.animation.Juggler;
	import starling.errors.AbstractMethodError;
	import starling.events.KeyboardEvent;
	import starling.extensions.TalonSprite;

	public class Popup extends TalonSprite
	{
		private var _manager:PopupManager;
		private var _data:Object;

		internal final function ctor(manager:PopupManager, data:Object = null):void
		{
			_manager = manager;
			_data = data;

			initialize();
		}

		protected function initialize():void
		{
			throw new AbstractMethodError();
		}
		
		public function notify():void
		{
			
		}

		protected final function get data():Object
		{
			return _data;
		}

		protected final function get juggler():Juggler
		{
			return _manager.juggler;
		}

		protected final function get manager():PopupManager
		{
			return _manager;
		}

		//
		// Code sugar
		//

		public final function close():void
		{
			manager.close(this);
			dispose();
		}

		protected final function addKeyboardListener(keyCode:int = -1, listener:Function = null, type:String = KeyboardEvent.KEY_DOWN):void
		{
			addEventListener(type, function(e:KeyboardEvent):void
			{
				if (keyCode == -1 || keyCode == e.keyCode)
				{
					listener.length
						? listener(e)
						: listener();

					e.stopImmediatePropagation();
				}
			});
		}
	}
}