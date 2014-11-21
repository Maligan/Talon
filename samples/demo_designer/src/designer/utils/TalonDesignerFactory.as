package designer.utils
{
	import starling.extensions.talon.utils.TalonFactory;

	/** Extended version of TalonFactory for designer purpose. */
	public class TalonDesignerFactory extends TalonFactory
	{
		public function hasPrototype(id:String):Boolean
		{
			return _prototypes[id] != null;
		}
	}
}
