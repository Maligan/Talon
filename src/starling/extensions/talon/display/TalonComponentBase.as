package starling.extensions.talon.display
{
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import starling.extensions.talon.core.Box;

	public class TalonComponentBase extends Sprite implements TalonComponent
	{
		private var _background:DisplayObject;
		private var _box:Box;

		public function TalonComponentBase()
		{
			_box = new Box();
		}

		public function get box():Box
		{
			return _box;
		}
	}
}