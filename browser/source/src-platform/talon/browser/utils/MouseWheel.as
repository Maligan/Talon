package talon.browser.utils
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import starling.core.Starling;

	import starling.display.DisplayObject;
	import starling.display.Stage;
	import starling.events.Event;
	import starling.events.EventDispatcher;

	[Event(name="triggered", type="starling.events.Event")]
	public class MouseWheel extends EventDispatcher
	{
		private var _target:DisplayObject;
		private var _starling:Starling;

		public function MouseWheel(target:DisplayObject, starling:Starling)
		{
			_target = target;
			_starling = starling;
			_starling.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}

		private function onMouseWheel(e:MouseEvent):void
		{
			var globalNativePoint:Point = new Point(e.localX, e.localY);
			var globalStarlingPoint:Point = transformViewportToStage(globalNativePoint);
			var hitTestTarget:DisplayObject = _starling.stage.hitTest(globalStarlingPoint);

			var isWheeled:Boolean = false;

			while (!isWheeled && hitTestTarget != null)
			{
				isWheeled = hitTestTarget == target;
				hitTestTarget = hitTestTarget.parent;
			}

			if (isWheeled)
			{
				dispatchEventWith(Event.TRIGGERED,false, e.delta);
			}
		}

		public function transformViewportToStage(point:Point):Point
		{
			const viewport:Rectangle = _starling.viewPort;
			const stage:Stage = _starling.stage;

			if (viewport.x != 0 || viewport.y != 0 || stage.stageWidth != viewport.width || stage.stageHeight != viewport.height)
			{
				point = point.clone();
				point.x = stage.stageWidth * (point.x - viewport.x) / viewport.width;
				point.y = stage.stageHeight * (point.y - viewport.y) / viewport.height;
			}

			return point;
		}

		public function get target():DisplayObject
		{
			return _target;
		}

		public function dispose():void
		{
			removeEventListeners();
			_target = null;
			_starling.nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			_starling = null;
		}
	}
}