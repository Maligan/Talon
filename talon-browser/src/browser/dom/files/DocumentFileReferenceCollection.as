package browser.dom.files
{
	import browser.dom.Document;

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

		public function registerFileControllerByType(typeName:String, typeClass:Class):void
		{
			_types[typeName] = typeClass;
		}

		public function addFile(file:DocumentFileReference):void
		{
			if (_files[file.url] != null) return;

			var type:Class = _types[file.type];
			if (type)
			{
				var controller:DocumentFileController = new type();
				controller.initialize(file);
				_controllers[file.url] = controller;
				_files[file.url] = file;
			}
		}

		public function removeFile(file:DocumentFileReference):void
		{
			// Reference may be different
			file = _files[file.url];

			if (file)
			{
				file.removeEventListener(Event.CHANGE, onFileChange);
				delete _files[file.url];

				var controller:DocumentFileController = _controllers[file.url];
				controller.dispose();
				delete _controllers[file.url];
			}
		}

		private function onFileChange(e:Event):void
		{
			var file:DocumentFileReference = DocumentFileReference(e.target);
			if (file.exits === false) removeFile(file);
		}

		public function toArray():Vector.<DocumentFileReference>
		{
			var result:Vector.<DocumentFileReference> = new Vector.<DocumentFileReference>();
			for each (var file:DocumentFileReference in _files) result[result.length] = file;
			return result;
		}
	}
}
