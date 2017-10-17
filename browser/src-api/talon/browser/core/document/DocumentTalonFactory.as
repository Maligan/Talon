package talon.browser.core.document
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	import starling.extensions.ITalonDisplayObject;
	import starling.extensions.TalonFactory;

	import talon.core.Node;
	import talon.core.Style;

	/** Extended version of TalonFactory for browser purpose. */
	public final class DocumentTalonFactory extends TalonFactory
	{
		private var _document:Document;
		private var _stylesCollection:StyleSheetCollection;
		private var _timer:Timer;
		private var _csf:Number;
		private var _dpi:Number;

		public function DocumentTalonFactory(document:Document):void
		{
			_resources = new ObjectWithAccessLogger();
			_document = document;
			_stylesCollection = new StyleSheetCollection();
			_timer = new Timer(1);
			_timer.addEventListener(TimerEvent.TIMER, onTimer);
		}
		
		public function getNodeMeta(node:Node):*
		{
			return {
				template: "Template",
				source: {
					file: "path/to/template.xml",
					line: "0",
					char: "0"
				}
			}
		}

		private function dispatchChange():void
		{
			if (_timer.running == false)
				_document.tasks.begin();

			_timer.reset();
			_timer.start();
		}

		private function onTimer(e:TimerEvent):void
		{
			_timer.reset();
			_document.tasks.end();
		}

		public override function build(source:Object, includeStyleSheet:Boolean = true, includeResources:Boolean = true):ITalonDisplayObject
		{
			resources.reset();
			_styles = _stylesCollection.getMergedStyleSheet();

			return super.build(source, includeStyleSheet, includeResources);
		}

		protected override function getNode(element:*):Node
		{
			var node:Node = super.getNode(element);

			if (node)
			{
				if (csf == csf) node.metrics.ppdp = csf;
				if (dpi == dpi) node.metrics.ppmm = dpi / 25.4;
			}

			return node;
		}

		public function get csf():Number { return _csf; }
		public function set csf(value:Number):void
		{
			if (_csf != value)
			{
				_csf = value;
				dispatchChange();
			}
		}

		public function get dpi():Number { return _dpi; }
		public function set dpi(value:Number):void
		{
			if (_dpi != value)
			{
				_dpi = value;
				dispatchChange();
			}
		}

		//
		// Templates
		//
		public function hasTemplate(id:String):Boolean
		{
			return _parser.templates[id] != null;
		}

		public override function addTemplate(xml:XML):void
		{
			super.addTemplate(xml);
			dispatchChange();
		}


		public function removeTemplate(id:String):void
		{
			var template:XML = _parser.templates[id];
			if (template == null)
				return;

			var tag:String = _parser.getUseTag(id);

			// Remove using
			_parser.setUse(id, null);
			_parser.setUse(null, tag);
			// Remove xml
			delete _parser.templates[id];

			dispatchChange();
		}

		public function get templateIds():Vector.<String>
		{
			var result:Vector.<String> = new Vector.<String>();
			for (var id:String in _parser.templates) result[result.length] = id;
			return result.sort(byName);
		}

		private function byName(string1:String, string2:String):int
		{
			if (string1 > string2) return +1;
			if (string1 < string2) return -1;
			return 0;
		}

		//
		// Resources
		//
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
			for (var resourceId:String in _resources.inner) result[result.length] = resourceId;
			return result.sort(byName);
		}

		public function getResourceMissed():Vector.<String> { return resources.getMissed(); }
		public function getResourceConflict():Vector.<String> { return resources.getConflicts(); }
		
		public function appendResources(object:Object):void
		{
			for (var key:String in object)
			{
				if (key == "0")
					trace("sdf")
			}
			
			resources.append(object);
			dispatchChange();
		}
		
		public function removeResources(object:Object):void
		{
			resources.remove(object);
			dispatchChange();			
		}
		
		private function get resources():ObjectWithAccessLogger
		{
			return ObjectWithAccessLogger(_resources);
		}

		//
		// Styles
		//
		public override function addStyle(styles:Vector.<Style>):void
		{
			throw new Error("Use addStyleSheetWithId");
		}

		public function addStyleSheetWithId(key:String, css:String):void
		{
			_stylesCollection.insert(key, css);
			dispatchChange();
		}

		public function removeStyleSheetWithId(key:String):void
		{
			_stylesCollection.remove(key);
			dispatchChange();
		}

		override public function buildCache():Object
		{
			_styles = _stylesCollection.getMergedStyleSheet();
			return super.buildCache();
		}
	}
}

import flash.utils.Dictionary;
import flash.utils.Proxy;
import flash.utils.flash_proxy;

import talon.core.Style;
import talon.utils.ParseUtil;

use namespace flash_proxy;

class ObjectWithAccessLogger extends Proxy
{
	private var _names:Vector.<String> = new <String>[];
	private var _overrides:Vector.<String> = new <String>[];
	private var _stack:Vector.<Object> = new <Object>[];
	private var _touches:Object = {};
	private var _touchId:int = 1;
	
	public function reset():void { _touchId++ }
	
	public function getUsed():Vector.<String>
	{
		var result:Vector.<String> = new <String>[];
		
		for (var key:String in this)
			if (_touches[key] === _touchId)
				result.push(key);
		
		return result;
	}

	public function getMissed():Vector.<String>
	{
		var result:Vector.<String> = new <String>[];

		for (var key:String in _touches)
			if (_touches[key] === _touchId && this[key] == null)
				result.push(key);

		return result;
	}
	
	public function getConflicts():Vector.<String>
	{
		return _overrides;
	}
	
	// Stack
	
	public function append(object:Object):void
	{
		if (_stack.indexOf(object) == -1)
			_stack.push(object);

		refreshNames();
	}
	
	public function remove(object:Object):void
	{
		var indexOf:int = _stack.indexOf(object);
		if (indexOf != -1)
			_stack.removeAt(indexOf);

		refreshNames();
	}
	
	private function refreshNames():void
	{
		_names.length = 0;
		_overrides.length = 0;
		
		var exist:Object = {};
		for each (var object:Object in _stack)
		{
			for (var key:String in object)
			{
				if (exist[key] != true)
				{
					exist[key]  = true;
					_names.push(key);
				}
				else
				{
					_overrides.push(key);
				}
			}
		}
	}
	
	// Proxy

	flash_proxy override function getProperty(name:*):*
	{
		_touches[name] = _touchId;

		for (var i:int = _stack.length-1; i >= 0; i--)
			if (_stack[i].hasOwnProperty(name))
				return _stack[i][name];
		
		return null;
	}

	flash_proxy override function setProperty(name:*, value:*):void
	{
		throw new Error("Use append()");
	}

	flash_proxy override function hasProperty(name:*):Boolean { return getProperty(name) !== undefined; }
	flash_proxy override function nextName(index:int):String { return String(_names[index - 1]); }
	flash_proxy override function nextNameIndex(index:int):int { return (index < _names.length) ? (index + 1) : 0; }
	flash_proxy override function nextValue(index:int):* { return getProperty(_names[index-1]); }
}

class StyleSheetCollection
{
	private var _cache:Vector.<Style>;
	private var _sources:Dictionary = new Dictionary();
	private var _keys:Vector.<String> = new <String>[];

	public function insert(key:String, css:String):void
	{
		if (_sources[key] == null) _keys.push(key);
		_sources[key] = css;
		_cache = null;
	}

	public function remove(key:String):void
	{
		if (key in _sources)
		{
			_keys.splice(_keys.indexOf(key), 1);
			delete _sources[key];
			_cache = null;
		}
	}

	public function getMergedStyleSheet():Vector.<Style>
	{
		if (_cache == null)
		{
			_cache = new Vector.<Style>;

			for each (var key:String in _keys)
			{
				var source:String = _sources[key];
				_cache = _cache.concat(ParseUtil.parseCSS(source));
			}
		}

		return _cache;
	}
}