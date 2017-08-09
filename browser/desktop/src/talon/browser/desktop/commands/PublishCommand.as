package talon.browser.desktop.commands
{
	import deng.fzip.FZip;

	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	import mx.core.FontAsset;

	import starling.events.Event;
	import starling.textures.TextureAtlas;

	import talon.browser.desktop.filetypes.CSSAsset;
	import talon.browser.desktop.filetypes.DirectoryAsset;
	import talon.browser.desktop.filetypes.PropertiesAsset;
	import talon.browser.desktop.filetypes.TextureAsset;
	import talon.browser.desktop.filetypes.XMLAtlasAsset;
	import talon.browser.desktop.filetypes.XMLLibraryAsset;
	import talon.browser.desktop.filetypes.XMLTemplateAsset;
	import talon.browser.desktop.plugins.PluginConsole;
	import talon.browser.desktop.plugins.PluginDesktopUI;
	import talon.browser.desktop.utils.DesktopDocumentProperty;
	import talon.browser.desktop.utils.DesktopFileReference;
	import talon.browser.desktop.utils.TexturePacker;
	import talon.browser.platform.AppConstants;
	import talon.browser.platform.AppPlatform;
	import talon.browser.platform.AppPlatformEvent;
	import talon.browser.platform.document.Document;
	import talon.browser.platform.document.files.DummyFileController;
	import talon.browser.platform.document.files.IFileController;
	import talon.browser.platform.document.files.IFileReference;
	import talon.browser.platform.utils.Command;
	import talon.browser.platform.utils.Glob;

	public class PublishCommand extends Command
	{
		private var _target:File;
		private var _ui:PluginDesktopUI;

		public function PublishCommand(platform:AppPlatform, target:File = null)
		{
			super(platform);
			platform.addEventListener(AppPlatformEvent.DOCUMENT_CHANGE, onDocumentChange);
			_target = target;
			_ui = platform.plugins.getPlugin(PluginDesktopUI) as PluginDesktopUI;
		}

		private function onDocumentChange(e:Event):void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public override function execute():void
		{
			if (_target != null)
			{
				writeDocument(_target);
			}
			else
			{
				var targetPath:String = getDocumentExportPath(platform.document);
				var target:File = new File(targetPath);
				target.addEventListener(Event.SELECT, onExportFileSelect);
				target.browseForSave(AppConstants.T_EXPORT_TITLE);
			}
		}

		private function onExportFileSelect(e:*):void
		{
			var file:File = File(e.target);
			writeDocument(file);
		}

		private function writeDocument(target:File):void
		{
			var files:Object = {};

			// Add cache JSON
			var cache:Object = getCache();
			var cacheJSON:String = JSON.stringify(cache);
			var cacheBytes:ByteArray = new ByteArray();
			cacheBytes.writeUTFBytes(cacheJSON);
			files[AppConstants.BROWSER_DEFAULT_CACHE_FILENAME] = cacheBytes;
			
			// Add rest files
			for each (var file:IFileReference in platform.document.files.toArray())
			{
				var addToOutput:Boolean = !isIgnored(file) && !isCached(file) && !isPacked(file);
				if (addToOutput)
					files[getExportPath(file)] = file.data;
			}
			
			var packerExec:String = platform.settings.getValueOrDefault(AppConstants.SETTING_TEXTURE_PACKER_BIN);
			if (packerExec)
			{
				_ui.locked = _ui.spinner = true;

				var packer:TexturePacker = new TexturePacker(new File(packerExec), new File(platform.document.properties.getValueOrDefault(DesktopDocumentProperty.PROJECT_DIR)), getTemp(), "sprites_{n}.xml");
				packer.exec(getImages(), platform.document.properties.getValueOrDefault(DesktopDocumentProperty.EXPORT_TPS_ARGS, String, "--multipack --format sparrow --trim-mode None")).then(function (sheets:Vector.<File>):void {
					for each (var sheet:File in sheets)
						files["sprites/" + sheet.name] = readBytes(sheet);

					writeZip(target, files);
					_ui.locked = _ui.spinner = false;
				}, function (e:Error):void {
					trace(e);
					_ui.locked = _ui.spinner = false;
					PluginConsole(platform.plugins.getPlugin(PluginConsole)).console.println(e);
				})
			}
			else
			{
				writeZip(target, files);
				_ui.locked = _ui.spinner = false;
			}
			
		}
		
		private function writeZip(file:File, content:Object):void
		{
			// Create zip
			var zip:FZip = new FZip();
			for (var filePath:String in content)
				zip.addFile(filePath, content[filePath]);
			
			// Save file
			var fileStream:FileStream = new FileStream();
			try
			{
				fileStream.open(file, FileMode.WRITE);

				if (zip.getFileCount() != 0)
					zip.serialize(fileStream);
			}
			finally
			{
				fileStream.close();
			}
		}

		public override function get isExecutable():Boolean
		{
			return platform.document != null;
		}

		//
		// Export documents properties
		//
		private function getDocumentExportPath(document:Document):String
		{
			var sourcePath:File = getSourcePath(document);
			if (sourcePath)
			{
				var exportPath:String = document.properties.getValueOrDefault(DesktopDocumentProperty.EXPORT_PATH, String);
				if (exportPath)
					return sourcePath.resolvePath(exportPath).nativePath;
				else
					return sourcePath.parent.resolvePath(sourcePath.name + "." + AppConstants.BROWSER_PUBLISH_EXTENSION).nativePath;
			}

			return document.properties.getValueOrDefault(DesktopDocumentProperty.PROJECT_NAME, String)
				+ "."
				+ AppConstants.BROWSER_PUBLISH_EXTENSION;
		}

		private function getSourcePath(document:Document):File
		{
			if (document == null) return null;

			var fileReferences:Vector.<IFileReference> = document.files.toArray();
			var fileReference:DesktopFileReference = fileReferences.shift() as DesktopFileReference;

			return fileReference ? fileReference.root : null;
		}

		private function getCache():Object
		{
			var files:Vector.<IFileReference> = platform.document.files.toArray();
			var stash:Vector.<IFileReference> = new <IFileReference>[];

			for each (var file:IFileReference in files)
				if (isIgnored(file) && isCached(file))
					platform.document.files.removeReference(stash[stash.length] = file);

			var cache:Object = platform.document.factory.buildCache();

			while (stash.length > 0)
				platform.document.files.addReference(stash.pop());

			return cache;
		}

		/** File is ignored for export. */
		public function isIgnored(file:IFileReference):Boolean
		{
			var fileController:IFileController = platform.document.files.getController(file.path);
			if (fileController is DirectoryAsset) return true;
			if (fileController is DummyFileController) return true;
			
			var patternsString:String = platform.document.properties.getValueOrDefault(DesktopDocumentProperty.EXPORT_PATTERN, String);
			if (patternsString == null) return false;
			
			return !Glob.matchPattern(file.path, patternsString);
		}

		/** File is merged into cache. */
		public function isCached(file:IFileReference):Boolean
		{
			var controller:IFileController = platform.document.files.getController(file.path);
			
			if (controller is PropertiesAsset)	return true;
			if (controller is CSSAsset)			return true;
			if (controller is XMLLibraryAsset)	return true;
			if (controller is XMLTemplateAsset)	return true;
			
			return false;
		}
		
		public function isPacked(file:IFileReference):Boolean
		{
			var controller:IFileController = platform.document.files.getController(file.path);

			if (controller is TextureAsset)
				return Glob.matchPattern(file.path, platform.document.properties.getValueOrDefault(DesktopDocumentProperty.EXPORT_TPS_PATTERN, String, ""))
					&& platform.settings.getValueOrDefault(AppConstants.SETTING_TEXTURE_PACKER_BIN) != null;
			
			return false;
		}
		
		
		
		public function getExportPath(file:IFileReference):String
		{
			var ref:DesktopFileReference = file as DesktopFileReference;
			if (ref == null) throw new Error(); // FIXME
			
			var controller:IFileController = platform.document.files.getController(ref.path);
			if (controller is TextureAsset) return "sprites/" + ref.name;
			if (controller is TextureAtlas) return "sprites/" + ref.name;
			if (controller is FontAsset) return "fonts/" + ref.name;
			
			if (controller is XMLAtlasAsset) return ref.name;
			
			return file.path;
		}
		
		
		// TODO
		
		public function getImages():Vector.<File>
		{
			var result:Vector.<File> = new <File>[];
			
			for each (var reference:IFileReference in platform.document.files.toArray())
			{
				var desktop:DesktopFileReference = reference as DesktopFileReference;
				var controller:IFileController = platform.document.files.getController(reference.path);
				if (controller is TextureAsset && isPacked(reference)) result.push(desktop.target);
			}
			
			return result;
		}
		
		public function getTemp():File
		{
			var packerTempPath:String = platform.document.properties.getValueOrDefault(DesktopDocumentProperty.EXPORT_TPS_TEMP);
			if (packerTempPath == null)
			{
				packerTempPath = File.createTempDirectory().nativePath;
				platform.document.properties.setValue(DesktopDocumentProperty.EXPORT_TPS_TEMP, packerTempPath);
			}
			
			return new File(packerTempPath);
		}

		private function readBytes(file:File):ByteArray
		{
			var result:ByteArray = new ByteArray();
			var stream:FileStream = new FileStream();

			try
			{
				stream.open(file, FileMode.READ);
				stream.readBytes(result, 0, stream.bytesAvailable);
			}
			finally
			{
				stream.close();
				return result;
			}
		}
	}
}