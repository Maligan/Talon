package talon.browser.popups
{
	import starling.animation.Tween;

	import starling.core.Starling;

	import starling.display.DisplayObjectContainer;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.events.KeyboardEvent;

	import talon.browser.AppPlatform;

	import talon.browser.AppPlatform;

	import talon.starling.TalonFactoryStarling;

	public class PopupManager extends EventDispatcher
	{
		private var _platform:AppPlatform;
		private var _popups:Vector.<Popup>;
		private var _host:DisplayObjectContainer;

		private var _notifyTween:Tween;

		public function PopupManager(platform:AppPlatform)
		{
			_popups = new <Popup>[];
			_platform = platform;
		}

		public function notify():void
		{
			if (_notifyTween && _notifyTween.isComplete == false) return;

			var topmost:Popup = _popups.length ? _popups[0] : null;
			if (topmost)
			{
				if (_notifyTween == null)
					_notifyTween = new Tween(topmost, 1);

				_notifyTween.reset(topmost, 0.2);
				_notifyTween.onUpdate = notifyUpdate;
				_notifyTween.onUpdateArgs = [topmost, topmost.x];

				Starling.juggler.add(_notifyTween);
			}
		}

		private function notifyUpdate(popup:Popup, base:Number):void
		{
			var x:Number = _notifyTween.progress;
			var y:Number = Math.sin(3 * x * Math.PI) / Math.pow(Math.E, x);

			popup.x = base + y * 10;
		}

		public function open(popup:Popup, data:Object = null):void
		{
			if (_host == null)
			{
				trace("[PopupManager]", "Popups host container is null");
				return;
			}

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
			return _platform.factory;
		}

		public function get hasOpenedPopup():Boolean
		{
			return _popups.length > 0;
		}

		public function get host():DisplayObjectContainer { return _host; }
		public function set host(value:DisplayObjectContainer):void
		{
			_host = value;

			// Redispatch keyboard events to topmost popup
			_host.stage.addEventListener(KeyboardEvent.KEY_DOWN, dispatchEventToTopmostPopup);
			_host.stage.addEventListener(KeyboardEvent.KEY_UP, dispatchEventToTopmostPopup);
		}

		private function dispatchEventToTopmostPopup(e:Event):void
		{
			var topmost:Popup = _popups.length ? _popups[_popups.length-1] : null;
			if (topmost)
				topmost.dispatchEvent(e);
		}
	}
}