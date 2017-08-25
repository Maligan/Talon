package talon.core
{
	import talon.utils.OrderedObject;

	/** Reflection from selector to values.*/
	public class Style
	{
		private var _selector:String;
		private var _values:Object;
		
		/** @private */
		public function Style(selector:String)
		{
			_selector = selector;
			_values = new OrderedObject();
		}
		
		/** Style CSS-like selector. */
		public function get selector():String { return _selector }

		/** Style key/value pairs. */
		public function get values():Object { return _values }
	}
}
