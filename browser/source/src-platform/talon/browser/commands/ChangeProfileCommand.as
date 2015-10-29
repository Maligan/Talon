package talon.browser.commands
{
	import talon.browser.AppPlatform;
	import talon.browser.popups.ProfilePopup;
	import talon.browser.utils.DeviceProfile;
	import talon.browser.utils.DeviceProfile;

	import starling.events.Event;

	public class ChangeProfileCommand extends Command
	{
		private var _profile:DeviceProfile;

		public function ChangeProfileCommand(platform:AppPlatform, profile:DeviceProfile)
		{
			super(platform);
			platform.profile.addEventListener(Event.CHANGE, onProfileChange);
			_profile = profile;
		}

		private function onProfileChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			platform.profile.copyFrom(_profile);
		}

		public override function get isActive():Boolean
		{
			return platform.profile.equals(_profile);
		}
	}
}