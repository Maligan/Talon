package talon.browser.ui.popups
{
	import flash.events.Event;

	import starling.animation.Transitions;
	import starling.animation.Tween;

	import starling.core.Starling;

	import starling.display.DisplayObjectContainer;
	import starling.events.EventDispatcher;

	import talon.starling.TalonFactoryStarling;

	public class PopupManager extends EventDispatcher
	{
		private var _popups:Vector.<Popup>;
		private var _host:DisplayObjectContainer;
		private var _factory:TalonFactoryStarling;

		private var _notifying:Boolean;
		private var _notifyProperties:Object;

		public function initialize(host:DisplayObjectContainer, factory:TalonFactoryStarling):void
		{
			_popups = new <Popup>[];
			_host = host;
			_factory = factory;
		}

		public function notify():void
		{
			if (_notifying) return;

			var topmost:Popup = _popups.length ? _popups[0] : null;
			if (topmost)
			{
				_notifying = true;

				if (_notifyProperties == null)
				{
					_notifyProperties = {
						scaleX: 1.1,
						scaleY: 1.1,
						repeatCount: 2,
						reverse: true,
						transition: Transitions.EASE_IN,
						onComplete: notifyComplete
					}
				}

				Starling.juggler.tween(topmost, 0.1, _notifyProperties) as Tween;
			}
		}

		private function notifyComplete():void
		{
			_notifying = false;
		}

		public function open(popup:Popup, data:Object = null):void
		{
			if (_popups.indexOf(popup) == -1 && !hasOpenedPopup)
			{
				_popups.push(popup);
				_host.addChild(popup);

				try
				{
					popup.ctor(this, data);
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