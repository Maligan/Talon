package talon.browser.platform.document
{
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	import starling.extensions.ITalonElement;
	import starling.extensions.TalonFactory;

	import talon.Node;
	import talon.utils.StyleSheet;

	/** Extended version of TalonFactory for browser purpose. */
	public final class DocumentTalonFactory extends TalonFactory
	{
		private var _document:Document;
		private var _styles:StyleSheetCollection;
		private var _timer:Timer;
		private var _csf:Number;
		private var _dpi:Number;

		public function DocumentTalonFactory(document:Document):void
		{
			_resources = new ObjectWithAccessLogger();
			_document = document;
			_styles = new StyleSheetCollection();
			_timer = new Timer(1);
			_timer.addEventListener(TimerEvent.TIMER, onTimer);
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

		public override function build(source:Object, includeStyleSheet:Boolean = true, includeResources:Boolean = true):ITalonElement
		{
			resources.reset();
			_style = _styles.getMergedStyleSheet();

			return super.build(source, includeStyleSheet, includeResources);
		}

		protected override function getNode(element:*):Node
		{
			var node:Node = super.getNode(element);

			if (node)
			{
				if (csf == csf) node.ppdp = csf;
				if (dpi == dpi) node.ppmm = dpi / 25.4;
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

			var tag:String = _parser.getUsingTag(id);

			// Remove using
			_parser.setUsing(id, null);
			_parser.setUsing(null, tag);
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

		public function get missedResourceIds():Vector.<String>
		{
			return resources.getMissed();
		}

		public function removeResource(id:String):void
		{
			delete _resources[id];
			dispatchChange();
		}

		public override function addResource(id:String, resource:*):void
		{
			super.addResource(id, resource);
			dispatchChange();
		}

		private function get resources():ObjectWithAccessLogger
		{
			return ObjectWithAccessLogger(_resources);
		}

		//
		// Styles
		//
		public override function addStyle(style:StyleSheet):void
		{
			throw new Error("Use addStyleSheetWithId");
		}

		public function addStyleSheetWithId(key:String, css:String):void
		{
			_styles.insert(key, css);
			dispatchChange();
		}

		public function removeStyleSheetWithId(key:String):void
		{
			_styles.remove(key);
			dispatchChange();
		}
	}
}

import flash.utils.Dictionary;
import flash.utils.flash_proxy;

import talon.utils.OrderedObject;
import talon.utils.StyleSheet;

use namespace flash_proxy;

class ObjectWithAccessLogger extends OrderedObject
{
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
			if (_touches[key] === _touchId && this[key] === undefined)
				result.push(key);

		return result;
	}
	
	// Proxy

	flash_proxy override function getProperty(name:*):*
	{
		_touches[name] = _touchId;
		return super.flash_proxy::getProperty(name);
	}
}

class StyleSheetCollection
{
	private var _cache:StyleSheet;
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

	public function getMergedStyleSheet():StyleSheet
	{
		if (_cache == null)
		{
			_cache = new StyleSheet();

			for each (var key:String in _keys)
			{
				var source:String = _sources[key];
				_cache.parse(source);
			}
		}

		return _cache;
	}
}