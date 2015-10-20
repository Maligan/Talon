package talon.browser.document.files
{
	import flash.utils.Dictionary;

	import starling.events.Event;

	import talon.browser.document.Document;
	import talon.browser.plugins.tools.types.Asset;

	public class DocumentFileReferenceCollection
	{
		private var _document:Document;
		private var _mappings:Dictionary;
		private var _checkers:Vector.<Function>;

		private var _references:Dictionary;
		private var _controllers:Dictionary;

		public function DocumentFileReferenceCollection(document:Document)
		{
			_document = document;
			_mappings = new Dictionary();
			_checkers = new <Function>[];

			_references = new Dictionary();
			_controllers = new Dictionary();
		}

		public function registerController(checker:Function, typeClass:Class):void
		{
			_checkers[_checkers.length] = checker;
			_mappings[checker] = typeClass;
		}

		public function addReference(reference:DocumentFileReference):void
		{
			if (reference.exists === false) return;
			if (hasURL(reference.url) === true) return;

			// Initialize reference
			reference.addEventListener(Event.CHANGE, onFileChange);
			_references[reference.url] = reference;

			// Create controller
			attachController(reference);
		}

		public function removeReference(reference:DocumentFileReference):void
		{
			if (hasURL(reference.url) == false) return;

			// Detach controller
			detachController(reference);

			// Dispose reference
			reference = _references[reference.url];
			reference.removeEventListener(Event.CHANGE, onFileChange);
			delete _references[reference.url];
		}

		private function onFileChange(e:Event):void
		{
			var reference:DocumentFileReference = DocumentFileReference(e.target);

			if (reference.exists === false)
			{
				removeReference(reference);
			}
			else
			{
				detachController(reference);
				attachController(reference);
			}
		}

		//
		// Misc
		//
		public function hasURL(url:String):Boolean
		{
			return _references[url] != null;
		}

		public function getController(url:String):IDocumentFileController
		{
			return _controllers[url];
		}

		public function toArray():Vector.<DocumentFileReference>
		{
			var result:Vector.<DocumentFileReference> = new Vector.<DocumentFileReference>();
			for each (var reference:DocumentFileReference in _references) result[result.length] = reference;
			return result;
		}

		public function dispose():void
		{
			var references:Vector.<DocumentFileReference> = toArray();

			while (references.length)
				removeReference(references.pop());
		}

		//
		// Attach/Detach
		//
		/** Add controller to reference. */
		private function attachController(reference:DocumentFileReference):void
		{
			var controllerClass:Class = Asset;

			// Define controller class
			for each (var checker:Function in _checkers)
			{
				if (checker(reference) === true)
				{
					controllerClass = _mappings[checker];
					break;
				}
			}

			var controller:IDocumentFileController = new controllerClass();
			controller.attach(reference);

			_controllers[reference.url] = controller;
		}

		/** Remove controller from reference. */
		private function detachController(reference:DocumentFileReference):void
		{
			reference = _references[reference.url];

			var controller:IDocumentFileController = _controllers[reference.url];
			controller.detach();

			delete _controllers[reference.url];
		}
	}
}