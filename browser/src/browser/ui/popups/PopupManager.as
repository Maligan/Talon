package browser.ui.popups
{
	import flash.events.Event;

	import starling.display.DisplayObjectContainer;
	import starling.events.EventDispatcher;

	import talon.starling.TalonFactoryStarling;

	public class PopupManager extends EventDispatcher
	{
		private var _popups:Vector.<Popup>;
		private var _host:DisplayObjectContainer;
		private var _factory:TalonFactoryStarling;

		public function initialize(host:DisplayObjectContainer, factory:TalonFactoryStarling):void
		{
			_popups = new <Popup>[];
			_host = host;
			_factory = factory;
		}

		public function open(popup:Popup):void
		{
			if (_popups.indexOf(popup) == -1)
			{
				_popups.push(popup);
				_host.addChild(popup);

				try
				{
					popup.initialize(this);
				}
				catch (e:Error)
				{
					trace("[PopupManager]", "Error while initialize popup:\n" + e.getStackTrace());
					close(popup);
				}

				dispatchEventWith(Event.CHANGE);
			}
		}

		public function close(popup:Popup):void
		{
			var indexOf:int = _popups.indexOf(popup);
			if (indexOf != -1)
			{
				_popups.splice(indexOf, 1);
				_host.removeChild(popup);
				dispatchEventWith(Event.CHANGE);
			}
		}

		public function get factory():TalonFactoryStarling
		{
			return _factory;
		}

		public function get hasOpenedPopup():Boolean
		{
			return _popups.length > 0;
		}
	}
}