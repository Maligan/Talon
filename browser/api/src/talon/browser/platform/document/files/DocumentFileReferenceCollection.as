package talon.browser.platform.document.files
{
	import flash.events.Event;
	import flash.utils.Dictionary;

	import talon.browser.platform.document.Document;

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

		public function addReference(reference:IFileReference):void
		{
			if (reference.data === null) return;
			if (hasURL(reference.path) === true) return;

			// Initialize reference
			reference.addEventListener(Event.CHANGE, onReferenceChange);
			_references[reference.path] = reference;

			// Create controller
			attachController(reference);
		}

		public function removeReference(reference:IFileReference):void
		{
			if (hasURL(reference.path) == false) return;

			// Detach controller
			detachController(reference);

			// Dispose reference
			reference = _references[reference.path];
			reference.removeEventListener(Event.CHANGE, onReferenceChange);
			delete _references[reference.path];
		}

		private function onReferenceChange(e:Event):void
		{
			var reference:IFileReference = IFileReference(e.target);

			if (reference.data === null)
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

		public function getController(url:String):IFileController
		{
			return _controllers[url];
		}

		public function toArray():Vector.<IFileReference>
		{
			var result:Vector.<IFileReference> = new Vector.<IFileReference>();
			for each (var reference:IFileReference in _references) result[result.length] = reference;
			return result;
		}

		public function dispose():void
		{
			var references:Vector.<IFileReference> = toArray();

			while (references.length)
				removeReference(references.pop());
		}

		//
		// Attach/Detach
		//
		/** Add controller to reference. */
		private function attachController(reference:IFileReference):void
		{
			var controllerClass:Class = DummyFileController;

			// Define controller class
			for each (var checker:Function in _checkers)
			{
				if (checker(reference) === true)
				{
					controllerClass = _mappings[checker];
					break;
				}
			}

			var controller:IFileController = new controllerClass();
			controller.attach(_document, reference);

			_controllers[reference.path] = controller;
		}

		/** Remove controller from reference. */
		private function detachController(reference:IFileReference):void
		{
			reference = _references[reference.path];

			var controller:IFileController = _controllers[reference.path];
			controller.detach();

			delete _controllers[reference.path];
		}
	}
}

import talon.browser.platform.document.Document;
import talon.browser.platform.document.files.IFileController;
import talon.browser.platform.document.files.IFileReference;

class DummyFileController implements IFileController
{
	public function attach(document:Document, reference:IFileReference):void { }
	public function detach():void { }
}
