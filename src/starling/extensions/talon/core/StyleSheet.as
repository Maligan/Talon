package starling.extensions.talon.core
{
	public class StyleSheet
	{
		private var _node:Node;

		public function StyleSheet(node:Node)
		{
			_node = node;
		}

		public function getStyle(property:String):String
		{
			return null;
		}

		public function hasStyle(property:String):Boolean
		{
			return false;
		}
	}
}