package starling.extensions.talon.core
{
	import flash.utils.Dictionary;

	public class ResourceBundle
	{
		private var _resources:Dictionary;

		public function ResourceBundle()
		{
			_resources = new Dictionary();
		}

		public function setResource(key:String, value:*):void
		{
			_resources[key] = value;
		}

		public function getResource(key:String):*
		{
			return _resources[key]
		}
	}
}