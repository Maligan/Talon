package talon.browser.commands
{
	import talon.browser.AppPlatform;

	import starling.events.Event;

	public class CloseDocumentCommand extends Command
	{
		public function CloseDocumentCommand(platform:AppPlatform):void
		{
			super(platform);
			platform.addEventListener(AppPlatform.EVENT_DOCUMENT_CHANGE, onDocumentChange);
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