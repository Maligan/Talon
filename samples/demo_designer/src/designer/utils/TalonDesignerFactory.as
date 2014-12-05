package designer.utils
{
	import starling.extensions.talon.core.StyleSheet;
	import starling.extensions.talon.display.TalonFactory;

	/** Extended version of TalonFactory for designer purpose. */
	public class TalonDesignerFactory extends TalonFactory
	{
		public function hasPrototype(id:String):Boolean
		{
			return _prototypes[id] != null;
		}

		public function clearStyle():void
		{
			_style = new StyleSheet();
		}
	}
}
