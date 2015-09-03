package browser.utils
{
	import flash.utils.Dictionary;

	import starling.events.Event;

	import starling.events.EventDispatcher;

	public class DeviceProfile extends EventDispatcher
	{
		public static const IPHONE:DeviceProfile = registerDeviceProfile("iPhone", 320, 480, 1, 163);
		public static const IPHONE_RETINA:DeviceProfile = registerDeviceProfile("iPhone (Retina)", 640, 960, 2, 326);
		public static const IPHONE_5:DeviceProfile = registerDeviceProfile("iPhone 5", 640, 1136, 2, 326);
		public static const IPHONE_6:DeviceProfile = registerDeviceProfile("iPhone 6", 750, 1334, 2, 326);
		public static const IPHONE_6_PLUS:DeviceProfile = registerDeviceProfile("iPhone 6+", 1080, 1920, 2, 401);
		public static const IPAD:DeviceProfile = registerDeviceProfile("iPad", 1024, 768, 1, 132);
		public static const IPAD_RETINA:DeviceProfile = registerDeviceProfile("iPad (Retina)", 2048, 1536, 2, 264);
		public static const IPAD_MINI_RETINA:DeviceProfile = registerDeviceProfile("iPad Mini", 2048, 1536, 2, 326);

		private static var _profiles:Array;
		private static var _profilesById:Dictionary;

		public static function registerDeviceProfile(id:String, width:Number, height:Number, csf:Number, dpi:Number):DeviceProfile
		{
			var profile:DeviceProfile = new DeviceProfile(width, height, csf, dpi);
			profile._id = id;

			_profilesById ||= new Dictionary();
			_profilesById[id] = profile;
			_profiles ||= new Array();
			_profiles.push(profile);

			return profile;
		}

		public static function getEqual(profile:DeviceProfile):DeviceProfile
		{
			for each (var candidate:DeviceProfile in _profilesById)
				if (profile.equals(candidate))
					return candidate;

			return null;
		}

		public static function getById(id:String):DeviceProfile
		{
			return _profilesById[id];
		}

		public static function getProfiles():Vector.<DeviceProfile>
		{
			return Vector.<DeviceProfile>(_profiles);
		}

		private var _id:String;
		private var _width:Number;
		private var _height:Number;
		private var _csf:Number;
		private var _dpi:Number;

		private var _suppress:Boolean;
		private var _suppressedEvent:Boolean;

		public function DeviceProfile(width:Number, height:Number, csf:Number, dpi:Number)
		{
			_width = width;
			_height = height;
			_csf = csf;
			_dpi = dpi;
		}

		//
		// Comparing
		//
		public function copyFrom(profile:DeviceProfile):void
		{
			_suppressedEvent = false;
			_suppress = true;

			if (width > height)
			{
				width = Math.max(profile.width, profile.height);
				height = Math.min(profile.width, profile.height);
			}
			else
			{
				width = Math.min(profile.width, profile.height);
				height = Math.max(profile.width, profile.height);
			}

			csf = profile.csf;
			dpi = profile.dpi;

			_suppress = false;
			_suppressedEvent && dispatchEventWith(Event.CHANGE);
		}

		public function equals(profile:DeviceProfile):Boolean
		{
			var bySize:Boolean = false;
			bySize ||= _width == profile._width && _height == profile._height;
			bySize ||= _width == profile._height && _height == profile._width;
			var byCSF:Boolean = _csf == profile._csf;
			var byDPI:Boolean = _dpi == profile._dpi;

			return bySize && byCSF && byDPI;
		}

		//
		// Properties
		//
		public function get id():String { return _id; }

		public function get width():Number { return _width }
		public function set width(value:Number):void
		{
		    if (_width != value)
		    {
		        _width = value;
			    dispatchChange();
		    }
		}

		public function get height():Number { return _height }
		public function set height(value:Number):void
		{
		    if (_height != value)
		    {
		        _height = value;
			    dispatchChange();
		    }
		}

		public function get csf():Number { return _csf }
		public function set csf(value:Number):void
		{
		    if (_csf != value)
		    {
		        _csf = value;
			    dispatchChange();
		    }
		}

		public function get dpi():Number { return _dpi }
		public function set dpi(value:Number):void
		{
		    if (_dpi != value)
		    {
		        _dpi = value;
			    dispatchChange();
		    }
		}

		private function dispatchChange():void
		{
			if (_suppress)
			{
				_suppressedEvent = true;
			}
			else
			{
				dispatchEventWith(Event.CHANGE);
			}
		}
	}
}