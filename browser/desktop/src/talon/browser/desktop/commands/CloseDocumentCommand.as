package talon.browser.desktop.commands
{
	import starling.events.Event;

	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;
	import talon.browser.platform.commands.Command;

	public class CloseDocumentCommand extends Command
	{
		public function CloseDocumentCommand(platform:AppPlatform):void
		{
			super(platform);
			platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);
		}

		private function onDocumentChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			platform.document = null;
		}

		public override function get isExecutable():Boolean
		{
			return platform.document != null;
		}
	}
}