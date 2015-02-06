package browser.utils
{
	import flash.utils.Dictionary;

	public class DeviceProfile
	{
		public static const CUSTOM:DeviceProfile            = new DeviceProfile();

		public static const IPHONE:DeviceProfile            = new DeviceProfile("iPhone",           320,  480,  1, 163);
		public static const IPHONE_RETINA:DeviceProfile     = new DeviceProfile("iPhoneRetina",     640,  960,  2, 326);
		public static const IPHONE_5:DeviceProfile          = new DeviceProfile("iPhone5",          640,  1136, 2, 326);
		public static const IPHONE_6:DeviceProfile          = new DeviceProfile("iPhone6",          750,  1334, 2, 326);
		public static const IPHONE_6_PLUS:DeviceProfile     = new DeviceProfile("iPhone6Plus",      1080, 1920, 2, 401);
		public static const IPAD:DeviceProfile              = new DeviceProfile("iPad",             1024, 768,  1, 132);
		public static const IPAD_RETINA:DeviceProfile       = new DeviceProfile("iPadRetina",       2048, 1536, 2, 264);
		public static const IPAD_MINI_RETINA:DeviceProfile  = new DeviceProfile("iPadMiniRetina",   2048, 1536, 2, 326);

		private static var _profiles:Array;
		private static var _profilesById:Dictionary;

		public static function getById(id:String):DeviceProfile
		{
			return _profilesById[id];
		}

		public static function getProfiles():Vector.<DeviceProfile>
		{
			return Vector.<DeviceProfile>(_profiles);
		}

		public var id:String;
		public var width:Number;
		public var height:Number;
		public var csf:Number;
		public var dpi:Number;

		public function DeviceProfile(id:String = null, width:Number = NaN, height:Number = NaN, csf:Number = NaN, dpi:Number = NaN)
		{
			if (id != null)
			{
				_profilesById ||= new Dictionary();
				_profilesById[id] = this;
				_profiles ||= new Array();
				_profiles.push(this);
			}

			this.id = id;
			this.width = width;
			this.height = height;
			this.csf = csf;
			this.dpi = dpi;
		}
	}
}