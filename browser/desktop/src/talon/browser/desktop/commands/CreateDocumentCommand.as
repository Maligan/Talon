package talon.browser.desktop.commands
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	import talon.browser.desktop.utils.DesktopDocumentProperty;
	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.commands.Command;

	public class CreateDocumentCommand extends Command
	{
		private var _project:File;
		private var _projectRoot:File;

		public function CreateDocumentCommand(platform:AppPlatform)
		{
			super(platform);
		}

		public override function execute():void
		{
			_project = null;
			_projectRoot = null;

			_projectRoot = new File();
			_projectRoot.addEventListener(Event.SELECT, onProjectRootSelect);
			_projectRoot.browseForDirectory(AppConstants.T_PROJECT_ROOT_TITLE);
		}

		private function onProjectRootSelect(e:Event):void
		{
			_project = _projectRoot.resolvePath("." + AppConstants.BROWSER_DOCUMENT_EXTENSION);

			writeFile(_project, DesktopDocumentProperty.SOURCE_PATH + "=." + "\n");
			writeFile(_project, DesktopDocumentProperty.EXPORT_IGNORE + "=" + _project.name);

			if (_project.exists)
			{
				var open:OpenDocumentCommand = new OpenDocumentCommand(platform, _project);
				open.execute();
			}
		}

		private function writeFile(file:File, value:String):void
		{
			var stream:FileStream = new FileStream();

			try
			{
				stream.open(file, FileMode.APPEND);
				stream.writeUTFBytes(value);
			}
			finally
			{
				stream.close();
			}
		}
	}
}