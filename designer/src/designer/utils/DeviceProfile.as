package designer.utils
{
	import flash.utils.Dictionary;

	public class DeviceProfile
	{
		private static const _profiles:Dictionary = new Dictionary();

		public static function getById(id:String):DeviceProfile
		{
			return _profiles[id];
		}

		public var id:String;
		public var width:Number;
		public var height:Number;
		public var csf:Number;
		public var dpi:Number;

		public function DeviceProfile(id:String, width:Number, height:Number, csf:Number, dpi:Number)
		{
			_profiles[id] = this;

			this.id = id;
			this.width = width;
			this.height = height;
			this.csf = csf;
			this.dpi = dpi;
		}
	}
}