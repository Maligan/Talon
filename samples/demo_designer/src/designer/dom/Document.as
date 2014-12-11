package designer.dom
{
	import designer.dom.files.DocumentFileReference;
	import designer.dom.files.DocumentFileReferenceList;
	import designer.dom.files.DocumentFileType;
	import designer.utils.TalonDesignerFactory;
	import designer.utils.findFiles;

	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.filesystem.File;
	import flash.utils.ByteArray;

	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.textures.AtfData;
	import starling.textures.Texture;

	[Event(name="change", type="starling.events.Event")]
	public class Document extends EventDispatcher
	{
		private var _files:DocumentFileReferenceList;
		private var _factory:TalonDesignerFactory;
		private var _source:File;
		private var _properties:Object;
		private var _tracker:TaskTracker;

		public function Document(properties:Object):void
		{
			_tracker = new TaskTracker(onTaskEnd);
			_properties = properties;
			_factory = new TalonDesignerFactory();
			_files = new DocumentFileReferenceList();
			_files.registerDocumentFileType(DocumentFileType.DIRECTORY, null, asDirectory);
			_files.registerDocumentFileType(DocumentFileType.IMAGE, asImage, asImage, asImageRemoved);
			_files.registerDocumentFileType(DocumentFileType.PROTOTYPE, asPrototype);
			_files.registerDocumentFileType(DocumentFileType.STYLE, asStyle, asStyle);
		}

		//
		// File types
		//
		private function asDirectory(reference:DocumentFileReference):void
		{
			var files:Vector.<File> = findFiles(reference.file, false, false);
			var references:Vector.<DocumentFileReference> = new Vector.<DocumentFileReference>();
			for each (var file:File in files) references[references.length] = new DocumentFileReference(file);
			addFiles(references);
		}

		private function asImage(reference:DocumentFileReference):void
		{
			var bytes:ByteArray = reference.read();

			if (AtfData.isAtfData(bytes))
			{
				_factory.addResource(_factory.getResourceId(reference.url), Texture.fromAtfData(bytes));
			}
			else
			{
				_tracker.beginTask();

				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onComplete);
				loader.loadBytes(reference.read());

				function onComplete(e:*):void
				{
					_factory.addResource(_factory.getResourceId(reference.url), Texture.fromBitmap(loader.content as Bitmap));
					_tracker.endTask();
				}
			}
		}

		private function asImageRemoved(reference:DocumentFileReference):void
		{
			_tracker.beginTask();
			_factory.removeResource(_factory.getResourceId(reference.url));
			_tracker.endTask();
		}

		private function asPrototype(reference:DocumentFileReference):void
		{
			var xml:XML = new XML(reference.read());
			var type:String = xml.@type;
			var config:XML = xml.*[0];
			_factory.addPrototype(type, config);
		}

		private function asStyle(reference:DocumentFileReference):void
		{
			_factory.addStyleSheet(reference.read().toString());
		}







		private function onTaskEnd():void
		{
			dispatchEventWith(Event.CHANGE);
		}

		public function addFiles(links:Vector.<DocumentFileReference>):void
		{
			_tracker.beginTask();
			for each (var link:DocumentFileReference in links) addFile(link);
			_tracker.endTask();
		}

		public function addFile(file:DocumentFileReference):void
		{
			_tracker.beginTask();
			_files.addFile(file);
			_tracker.endTask();
		}

		public function get factory():TalonDesignerFactory
		{
			return _factory;
		}

		public function get files():Vector.<DocumentFileReference>
		{
			return _files.toArray();
		}

		public function get exportFileName():String
		{
			return _properties[DesignerConstants.PROPERTY_EXPORT_PATH];
		}

		/** Get in export document file name. */
		public function getExportFileName(documentFile:DocumentFileReference):String
		{
			return _source.getRelativePath(documentFile.file);
		}

		public function setSourcePath(file:File):void
		{
			_source = file;
		}
	}
}

class TaskTracker
{
	private var _taskCount:int = 0;
	private var _complete:Function;

	public function TaskTracker(complete:Function)
	{
		_complete = complete;
	}

	public function beginTask():void
	{
		_taskCount++;
	}

	public function endTask():void
	{
		_taskCount--;
		_taskCount == 0 && _complete();
	}
}
