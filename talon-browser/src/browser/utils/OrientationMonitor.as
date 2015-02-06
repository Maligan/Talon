package browser.utils
{
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;

	public class OrientationMonitor extends EventDispatcher
	{
		/** Display device is landscape oriented by default. */
		private var _stage:Stage;
		private var _prevLandscape:Boolean;

		public function OrientationMonitor(stage:Stage)
		{
			_stage = stage;
			_stage.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, int.MAX_VALUE);
			_prevLandscape = isLandscape;
		}

		private function onEnterFrame(e:Event):void
		{
			if (_prevLandscape != isLandscape)
			{
				_prevLandscape = isLandscape;
				dispatchEvent(new Event(Event.CHANGE));
			}
		}

		//
		// Properties
		//
		public function get isPortrait():Boolean
		{
			return stageHeight > stageWidth;
		}

		public function get isLandscape():Boolean
		{
			return  stageWidth > stageHeight;
		}

		public function get stageWidth():int
		{
			return _stage.stageWidth;
		}

		public function get stageHeight():int
		{
			return _stage.stageHeight;
		}
	}
}