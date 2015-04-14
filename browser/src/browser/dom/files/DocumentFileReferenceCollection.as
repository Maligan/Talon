package browser.dom.files
{
	import browser.dom.Document;
	import browser.dom.assets.Asset;
	import flash.utils.Dictionary;
	import starling.events.Event;

	public class DocumentFileReferenceCollection
	{
		private var _document:Document;
		private var _mappings:Dictionary;

		private var _references:Dictionary;
		private var _controllers:Dictionary;

		public function DocumentFileReferenceCollection(document:Document)
		{
			_document = document;
			_mappings = new Dictionary();

			_references = new Dictionary();
			_controllers = new Dictionary();
		}

		public function registerControllerForType(typeName:String, typeClass:Class):void
		{
			_mappings[typeName] = typeClass;
		}

		public function addReference(reference:DocumentFileReference):void
		{
			if (reference.exists === false) return;
			if (hasURL(reference.url) === true) return;

			// Initialize reference
			reference.addEventListener(Event.CHANGE, onFileChange);

			// Create controller
			var controllerClass:Class = _mappings[reference.type] || Asset;
			var controller:DocumentFileController = new controllerClass();
			controller.initialize(reference);

			// Register
			_references[reference.url] = reference;
			_controllers[reference.url] = controller;
		}

		public function removeReference(reference:DocumentFileReference):void
		{
			if (hasURL(reference.url) == false) return;

			// Dispose reference
			reference = _references[reference.url];
			reference.removeEventListener(Event.CHANGE, onFileChange);

			// Dispose controller
			var controller:DocumentFileController = _controllers[reference.url];
			controller.dispose();

			// Unregister
			delete _references[reference.url];
			delete _controllers[reference.url];
		}

		public function hasURL(url:String):Boolean
		{
			return _references[url] != null;
		}

		private function onFileChange(e:Event):void
		{
			var reference:DocumentFileReference = DocumentFileReference(e.target);
			if (reference.exists === false) removeReference(reference);
		}

		public function toArray():Vector.<DocumentFileReference>
		{
			var result:Vector.<DocumentFileReference> = new Vector.<DocumentFileReference>();
			for each (var reference:DocumentFileReference in _references) result[result.length] = reference;
			return result;
		}
	}
}