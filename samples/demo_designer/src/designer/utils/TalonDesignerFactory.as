package designer.utils
{
	import designer.dom.files.DocumentFileReference;
	import designer.dom.files.DocumentFileType;

	import flash.utils.Dictionary;

	import starling.display.DisplayObject;
	import starling.events.Event;

	import starling.extensions.talon.core.StyleSheet;
	import starling.extensions.talon.display.TalonFactory;

	/** Extended version of TalonFactory for designer purpose. */
	public final class TalonDesignerFactory extends TalonFactory
	{
		private var _styles:Dictionary;
		private var _styleInvalidated:Boolean;

		public function hasPrototype(id:String):Boolean
		{
			return _prototypes[id] != null;
		}

		public function removePrototype(id:String):void
		{
			delete _prototypes[id];
		}

		public function get prototypeIds():Vector.<String>
		{
			var result:Vector.<String> = new Vector.<String>();
			for (var id:String in _prototypes) result[result.length] = id;
			return result.sort(byName);
		}

		private function byName(string1:String, string2:String):int
		{
			if (string1 > string2) return +1;
			if (string1 < string2) return -1;
			return 0;
		}

		public function getResourceId(url:String):String
		{
			return getName(url);
		}

		private final function getName(path:String):String
		{
			var regexp:RegExp = /([^\?\/\\]+?)(?:\.([\w\-]+))?(?:\?.*)?$/;
			var matches:Array = regexp.exec(path);
			if (matches && matches.length > 0)
			{
				return matches[1];
			}
			else
			{
				return null;
			}
		}

		public function getResource(id:String):*
		{
			return _resources[id];
		}

		public function get resourceIds():Vector.<String>
		{
			var result:Vector.<String> = new Vector.<String>();
			for (var resourceId:String in _resources) result[result.length] = resourceId;
			return result.sort(byName);
		}

		public function removeResource(id:String):void
		{
			delete _resources[id];
		}






		public override function build(id:String, includeStyleSheet:Boolean = true, includeResources:Boolean = true):DisplayObject
		{
			if (_styleInvalidated)
			{
				validateStyle();
			}

			return super.build(id, includeStyleSheet, includeResources);
		}

		public function addStyleSheetWithId(id:String, css:String):void
		{
			_styles[id] = css;
			_styleInvalidated = true;
		}

		public function removeStyleSheetWithId(id:String):void
		{
			var hasStyle:Boolean = _styles[id] != null;
			if (hasStyle)
			{
				delete _styles[id];
				_styleInvalidated = true;
			}
		}

		private function validateStyle():void
		{
			_styleInvalidated = false;
			_style = new StyleSheet();
			for each (var css:String in _styles) _style.parse(css);
		}
	}
}
