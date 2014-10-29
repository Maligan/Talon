package starling.extension.talon.layout
{
	import starling.extension.talon.core.Box;
	import starling.extension.talon.core.Layout;

	public class DefaultLayout implements Layout
	{
		private var _target:Box;

		public function DefaultLayout(target:Box)
		{
			_target = target;
		}

		public function measureWidth(ppp:Number, em:Number):int
		{
			return _target.width.toPixels(ppp, em, 0, 0);
		}

		public function measureHeight(ppp:Number, em:Number):int
		{
			return _target.height.toPixels(ppp, em, 0, 0);
		}

		public function arrange(ppp:Number, em:Number, width:int, height:int):void
		{

		}
	}
}