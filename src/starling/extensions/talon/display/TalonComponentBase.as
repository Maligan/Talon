package starling.extensions.talon.display
{
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.talon.core.Box;

	public class TalonComponentBase extends Sprite implements TalonComponent
	{
		private var _background:Quad;
		private var _box:Box;

		public function TalonComponentBase()
		{
			_box = new Box();
			_box.addEventListener(Event.CHANGE, onBoxChange);
			_box.addEventListener(Event.RESIZE, onBoxResize);

			_background = new Quad(100, 100, 0);
			addChild(_background);
		}

		private function onBoxChange(e:Event):void
		{
			_background.x = box.attributes.x;
			_background.y = box.attributes.y;
			_background.width = box.width.toPixels(0, 0, 0, 0);
			_background.height = box.height.toPixels(0, 0, 0, 0);
		}

		private function onBoxResize(e:Event):void
		{
			_background.x = box.layout.bounds.x;
			_background.y = box.layout.bounds.y;
			_background.width = box.layout.bounds.width;
			_background.height = box.layout.bounds.height;
		}

		public function get box():Box
		{
			return _box;
		}
	}
}