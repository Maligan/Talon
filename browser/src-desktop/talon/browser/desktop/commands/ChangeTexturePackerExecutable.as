package talon.browser.desktop.commands
{
	import flash.events.Event;
	import flash.filesystem.File;

	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.utils.Command;

	public class ChangeTexturePackerExecutable extends Command
	{
		public function ChangeTexturePackerExecutable(platform:AppPlatform)
		{
			super(platform);

			platform.settings.addPropertyListener(AppConstants.SETTING_TEXTURE_PACKER_BIN, onTexturePackerBinChange)
		}

		private function onTexturePackerBinChange():void
		{
			dispatchEventChange();
		}

		public override function get isActive():Boolean
		{
			return platform.settings.getValue(AppConstants.SETTING_TEXTURE_PACKER_BIN);
		}

		override public function execute():void
		{
			if (isActive) platform.settings.setValue(AppConstants.SETTING_TEXTURE_PACKER_BIN, null);
			else
			{
				var file:File = new File();
				file.browseForOpen(AppConstants.T_SELECT_TEXTURE_PACKER);
				file.addEventListener(Event.SELECT, function (e:Event):void
				{
					file.removeEventListener(Event.SELECT, arguments.callee);
					platform.settings.setValue(AppConstants.SETTING_TEXTURE_PACKER_BIN, file.nativePath);
				});
			}
		}
	}
}
