package browser.dom
{
	import flash.utils.Dictionary;

	import starling.display.DisplayObject;
	import talon.StyleSheet;
	import talon.utils.TalonFactory;

	/** Extended version of TalonFactory for browser purpose. */
	public final class DocumentTalonFactory extends TalonFactory
	{
		private var _document:Document;
		private var _styles:Dictionary;
		private var _styleInvalidated:Boolean;

		public function DocumentTalonFactory(document:Document):void
		{
			_resources = new ObjectWithAccessLogger();
			_document = document;
		}


		public function hasPrototype(id:String):Boolean
		{
			return _templates[id] != null;
		}

		public function removePrototype(id:String):void
		{
			delete _templates[id];
		}

		public function get prototypeIds():Vector.<String>
		{
			var result:Vector.<String> = new Vector.<String>();
			for (var id:String in _templates) result[result.length] = id;
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

		public function get missedResourceIds():Vector.<String>
		{
			return ObjectWithAccessLogger(_resources).missed;
		}

		public function removeResource(id:String):void
		{
			delete _resources[id];
		}

		public function make(id:String):DisplayObject
		{
			refreshStyle();
			resources.reset();
			return super.build(id);
		}

		private function get resources():ObjectWithAccessLogger
		{
			return ObjectWithAccessLogger(_resources);
		}


		public override function build(id:String, includeStyleSheet:Boolean = true, includeResources:Boolean = true):DisplayObject
		{
			return super.build(id);
			throw new Error("Use make() method");
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

		private function refreshStyle():void
		{
			_styleInvalidated = false;
			_style = new StyleSheet();
			for each (var css:String in _styles) _style.parse(css);
		}
	}
}

import flash.utils.Proxy;
import flash.utils.flash_proxy;

use namespace flash_proxy;

class ObjectWithAccessLogger extends Proxy
{
	private var _innerObject:Object;
	private var _used:Object;

	public function ObjectWithAccessLogger():void
	{
		_innerObject = new Object();
		_used = new Object();
	}

	public function reset():void
	{
		_used = new Object();
	}

	public function get used():Vector.<String>
	{
		var result:Vector.<String> = new <String>[];
		for each (var property:String in _used) result[result.length] = property;
		return result;
	}

	public function get unused():Vector.<String>
	{
		var result:Vector.<String> = new <String>[];

		for (var property:String in _innerObject)
			if (_used.hasOwnProperty(property) == false)
				result[result.length] = property;

		return result;
	}

	public function get missed():Vector.<String>
	{
		return used.filter(notExists);
	}

	private function notExists(property:String, index:int, vector:Vector.<String>):Boolean
	{
		return _innerObject.hasOwnProperty(property) == false;
	}

	flash_proxy override function getProperty(name:*):* { return hasProperty(name) ? _innerObject[name] : null; }
	flash_proxy override function setProperty(name:*, value:*):void { _innerObject[name] = value; }
	flash_proxy override function hasProperty(name:*):Boolean { _used[name] = name; return _innerObject.hasOwnProperty(name); }
	flash_proxy override function deleteProperty(name:*):Boolean { return (delete _innerObject[name]); }
}