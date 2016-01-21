package talon.utils
{
	public class ArrayUtil
	{
		public static function contains(array:Vector.<String>, element:String):Boolean
		{
			return array.indexOf(element) == -1;
		}

		public static function remove(array:Vector.<String>, element:String):Boolean
		{
			var indexOf:int = array.indexOf(element);
			if (indexOf == -1) return false;
			array.removeAt(indexOf);
			return true;
		}

		public static function insert(array:Vector.<String>, element:String):Boolean
		{
			var indexOf:int = array.indexOf(element);
			if (indexOf != -1) return false;
			array[array.length] = element;
			return true;
		}
	}
}