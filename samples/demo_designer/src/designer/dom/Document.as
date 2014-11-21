package designer.dom
{
	import designer.utils.TalonDesignerFactory;

	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.filesystem.File;

	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.textures.Texture;

	public class Document extends EventDispatcher
	{
		private var _files:Vector.<DocumentFile>;
		private var _factory:TalonDesignerFactory;

		public function Document():void
		{
			_files = new Vector.<DocumentFile>();
			_factory = new TalonDesignerFactory();
		}

		private function onFileChange(e:Event):void
		{
			var file:DocumentFile = DocumentFile(e.target);
			apply(file);
		}

		private function apply(file:DocumentFile, dispatch:Boolean = true):void
		{
			if (file.type == DocumentFileType.PROTOTYPE)
			{
				var xml:XML = new XML(file.data);
				var type:String = xml.@type;
				var config:XML = xml.*[0];
				_factory.addLibraryPrototype(type, config);
				dispatch && dispatchEventWith(Event.CHANGE);
			}
			else if (file.type == DocumentFileType.STYLE)
			{
				var text:String = file.data.toString();
				_factory.addLibraryStyleSheet(text);
				dispatch && dispatchEventWith(Event.CHANGE);
			}
			else if (file.type == DocumentFileType.IMAGE)
			{
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
				loader.loadBytes(file.data);

				function onComplete(e:*):void
				{
					var texture:Texture = Texture.fromBitmap(loader.content as Bitmap);
					var key:String = file.path.substring(file.path.lastIndexOf("\\") + 1, file.path.lastIndexOf("."));
					_factory.addLibraryResource(key, texture);
					dispatchEventWith(Event.CHANGE); // Всегда диспатчить
				}
			}
			else if (file.type == DocumentFileType.PROJECT)
			{
				var files:Array = file.data.toString().replace(/^\s*|\s*$/g, "").split("\n");

				for each (var filePath:String in files)
				{
					var projectFile:File = new File(file.resolve(filePath));
					var projectDocumentFile:DocumentFile = new DocumentFile(projectFile);
					addFile(projectDocumentFile, true);
				}

				dispatch && dispatchEventWith(Event.CHANGE);
			}
		}

		public function addFile(documentFile:DocumentFile, silent:Boolean = false):void
		{
			for each (var file:DocumentFile in _files)
				if (file.equals(documentFile))
					return;

			_files[_files.length] = documentFile;
			apply(documentFile, !silent);
			documentFile.addEventListener(Event.CHANGE, onFileChange);
		}

		public function get factory():TalonDesignerFactory
		{
			return _factory;
		}

		public function get files():Vector.<DocumentFile>
		{
			return _files.slice();
		}
	}
}