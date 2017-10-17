package talon.browser.desktop.commands
{
	import starling.events.Event;

	import talon.browser.core.App;
	import talon.browser.core.utils.Command;
	import talon.browser.core.utils.DeviceProfile;

	public class ChangeProfileCommand extends Command
	{
		private var _profile:DeviceProfile;

		public function ChangeProfileCommand(platform:App, profile:DeviceProfile)
		{
			super(platform);
			platform.profile.addEventListener(Event.CHANGE, onProfileChange);
			_profile = profile;
		}

		private function onProfileChange(e:Event):void
		{
			dispatchEventChange();
		}

		override public function execute():void
		{
			platform.profile.copyFrom(_profile);
		}

		public override function get isActive():Boolean
		{
			return platform.profile.equals(_profile);
		}
	}
}