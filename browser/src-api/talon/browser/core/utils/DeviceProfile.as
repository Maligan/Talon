package talon.browser.core.utils
{
	import flash.utils.Dictionary;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;

	import starling.events.Event;
	import starling.events.EventDispatcher;

	public class DeviceProfile extends EventDispatcher implements IExternalizable
	{
		public static const MIN_SIZE:int = 32;

//		public static const IPHONE:DeviceProfile = registerDeviceProfile("iPhone", 320, 480, 163, 1);
//		public static const IPHONE_RETINA:DeviceProfile = registerDeviceProfile("iPhone (Retina)", 640, 960, 326, 2);
//		public static const IPHONE_5:DeviceProfile = registerDeviceProfile("iPhone 5", 640, 1136, 326, 2);
//		public static const IPHONE_6:DeviceProfile = registerDeviceProfile("iPhone 6", 750, 1334, 326, 2);
//		public static const IPHONE_6_PLUS:DeviceProfile = registerDeviceProfile("iPhone 6+", 1080, 1920, 401, 2);
//		public static const IPAD:DeviceProfile = registerDeviceProfile("iPad", 1024, 768, 132, 1);
//		public static const IPAD_RETINA:DeviceProfile = registerDeviceProfile("iPad (Retina)", 2048, 1536, 264, 2);
//		public static const IPAD_MINI_RETINA:DeviceProfile = registerDeviceProfile("iPad Mini", 2048, 1536, 326, 2);
//		public static const XIAOMI_REDMI_NOTE_3:DeviceProfile = registerDeviceProfile("Xiaomi Redmi Note 3", 1080, 1920, 401, 2.5);

		private static var _profiles:Array = [];
		private static var _profilesById:Dictionary = new Dictionary();

		public static function registerDeviceProfile(id:String, width:Number, height:Number, dpi:Number, csf:Number):DeviceProfile
		{
			var profile:DeviceProfile = new DeviceProfile(width, height, csf, dpi);
			profile._id = id;

			_profilesById[id] = profile;
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

		public function DeviceProfile(width:Number = NaN, height:Number = NaN, csf:Number = NaN, dpi:Number = NaN)
		{
			setSize(width, height);
			this.csf = csf;
			this.dpi = dpi;
		}

		//
		// Comparing
		//
		public function setSize(width:Number, height:Number):void
		{
			if (_width != width || _height != height)
			{
				_width = Math.max(MIN_SIZE, width);
				_height = Math.max(MIN_SIZE, height);
				dispatchChange();
			}
		}

		public function copyFrom(profile:DeviceProfile, preserveOrientation:Boolean = true):void
		{
			_suppressedEvent = false;
			_suppress = true;

			var needSmartSize:Boolean = preserveOrientation && width==width && height==height;
			if (needSmartSize)
			{
				if (width > height) setSize(Math.max(profile.width, profile.height), Math.min(profile.width, profile.height));
				else                setSize(Math.min(profile.width, profile.height), Math.max(profile.width, profile.height));
			}
			else
			{
				setSize(profile.width, profile.height);
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
		public function get height():Number { return _height }

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

		//
		// IExternalizable
		//
		public function writeExternal(output:IDataOutput):void
		{
			output.writeFloat(_width);
			output.writeFloat(_height);
			output.writeFloat(_csf);
			output.writeFloat(_dpi);
		}

		public function readExternal(input:IDataInput):void
		{
			_width = input.readFloat();
			_height = input.readFloat();
			_csf = input.readFloat();
			_dpi= input.readFloat();
		}
	}
}