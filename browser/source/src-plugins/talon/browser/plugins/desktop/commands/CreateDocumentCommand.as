package talon.browser.plugins.desktop.commands
{
	import talon.browser.commands.*;
	import talon.browser.AppPlatform;
	import talon.browser.AppConstants;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

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

			_project = new File("/" + AppConstants.T_PROJECT_FILE_DEFAULT_NAME + "." + AppConstants.BROWSER_DOCUMENT_EXTENSION);
			_project.addEventListener(Event.SELECT, onProjectFileSelect);
			_project.browseForSave(AppConstants.T_PROJECT_FILE_TITLE);
		}

		private function onProjectFileSelect(e:Event):void
		{
			_projectRoot = new File();
			_projectRoot.addEventListener(Event.SELECT, onProjectRootSelect);
			_projectRoot.browseForDirectory(AppConstants.T_PROJECT_ROOT_TITLE);
		}

		private function onProjectRootSelect(e:Event):void
		{
			var path:String = _project.parent.getRelativePath(_projectRoot, true);
			var pathProperty:String = AppConstants.PROPERTY_SOURCE_PATH + "=" + path;
			writeFile(_project, pathProperty);

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
				stream.open(file, FileMode.WRITE);
				stream.writeUTFBytes(value);
			}
			finally
			{
				stream.close();
			}
		}
	}
}