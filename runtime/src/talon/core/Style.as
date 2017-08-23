package talon.core
{
	import talon.utils.OrderedObject;

	public class Style
	{
		private var _name:String;
		private var _values:Object;
		
		public function Style(name:String)
		{
			_name = name;
			_values = new OrderedObject();
		}
		
		public function get name():String { return _name }
		public function get values():Object { return _values }
	}
}
