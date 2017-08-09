package talon.browser.desktop.commands
{
	import starling.events.Event;

	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.utils.Command;
	import talon.browser.platform.utils.DeviceProfile;

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