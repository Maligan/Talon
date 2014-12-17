package designer.dom.files
{
	import designer.dom.Document;
	import flash.utils.Dictionary;
	import starling.events.Event;

	public class DocumentFileReferenceCollection
	{
		private var _document:Document;

		private var _files:Dictionary;
		private var _types:Dictionary;
		private var _controllers:Dictionary;

		public function DocumentFileReferenceCollection(document:Document)
		{
			_document = document;
			_files = new Dictionary();
			_types = new Dictionary();
			_controllers = new Dictionary();
		}

		public function registerDocumentFileType(typeName:String, typeClass:Class):void
		{
			_types[typeName] = typeClass;
		}

		public function addFiles(files:Vector.<DocumentFileReference>):void
		{
			for each (var file:DocumentFileReference in files)
			{
				addFile(file);
			}
		}

		public function addFile(file:DocumentFileReference):void
		{
			if (_files[file.url] == null)
			{
				var type:Class = _types[file.type];
				if (type != null)
				{
					var controller:DocumentFileController = new type();
					controller.initialize(_document, file);
					_controllers[file.url] = controller;
				}
			}
		}

		public function removeFile(file:DocumentFileReference):void
		{
			if (_files[file.url] != null)
			{
				// Reference may be different
				file = _files[file.url];
				file.removeEventListener(Event.CHANGE, onFileChange);
				delete _files[file.url];
				delete _controllers[file.url];
			}
		}

		private function onFileChange(e:Event):void
		{
			var file:DocumentFileReference = DocumentFileReference(e.target);
			if (!file.exits) removeFile(file);
		}

		public function toArray():Vector.<DocumentFileReference>
		{
			var result:Vector.<DocumentFileReference> = new Vector.<DocumentFileReference>();
			for each (var file:DocumentFileReference in _files) result[result.length] = file;
			return result;
		}
	}
}
