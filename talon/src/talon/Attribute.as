package talon
{
	import flash.events.Event;
	import flash.utils.Dictionary;

	import talon.layout.Layout;
	import talon.enums.*;
	import talon.utils.*;

	public final class Attribute
	{
		public static const TRANSPARENT:String = "transparent";
		public static const WHITE:String = "white";
		public static const FALSE:String = "false";
		public static const AUTO:String = Gauge.AUTO;
		public static const NONE:String = Gauge.NONE;
		public static const ZERO:String = "0px";
		public static const ONE:String = "1";
		public static const INHERIT:String = "inherit";
		public static const LEFT:String = "left";
		public static const TOP:String = "top";

		//
		// Standard Attribute list
		//
		public static const ID:String                   = registerAttributeDefaults("id",                  null,                     false,  false);
		public static const TYPE:String                 = registerAttributeDefaults("type",                null,                     false,  false);
		public static const CLASS:String                = registerAttributeDefaults("class",               null,                     false,  false);
		public static const STATE:String                = registerAttributeDefaults("state",               null,                     false,  false);

		public static const WIDTH:String                = registerAttributeDefaults("width",               AUTO);
		public static const MIN_WIDTH:String            = registerAttributeDefaults("minWidth",            NONE);
		public static const MAX_WIDTH:String            = registerAttributeDefaults("maxWidth",            NONE);

		public static const HEIGHT:String               = registerAttributeDefaults("height",              AUTO);
		public static const MIN_HEIGHT:String           = registerAttributeDefaults("minHeight",           NONE);
		public static const MAX_HEIGHT:String           = registerAttributeDefaults("maxHeight",           NONE);

		public static const MARGIN:String               = registerAttributeDefaults("margin",              ZERO);
		public static const MARGIN_TOP:String           = registerAttributeDefaults("marginTop",           ZERO);
		public static const MARGIN_RIGHT:String         = registerAttributeDefaults("marginRight",         ZERO);
		public static const MARGIN_BOTTOM:String        = registerAttributeDefaults("marginBottom",        ZERO);
		public static const MARGIN_LEFT:String          = registerAttributeDefaults("marginLeft",          ZERO);

		public static const PADDING:String              = registerAttributeDefaults("padding",             ZERO);
		public static const PADDING_TOP:String          = registerAttributeDefaults("paddingTop",          ZERO);
		public static const PADDING_RIGHT:String        = registerAttributeDefaults("paddingRight",        ZERO);
		public static const PADDING_BOTTOM:String       = registerAttributeDefaults("paddingBottom",       ZERO);
		public static const PADDING_LEFT:String         = registerAttributeDefaults("paddingLeft",         ZERO);

		public static const ANCHOR:String               = registerAttributeDefaults("anchor",              NONE);
		public static const ANCHOR_TOP:String           = registerAttributeDefaults("anchorTop",           NONE);
		public static const ANCHOR_RIGHT:String         = registerAttributeDefaults("anchorRight",         NONE);
		public static const ANCHOR_BOTTOM:String        = registerAttributeDefaults("anchorBottom",        NONE);
		public static const ANCHOR_LEFT:String          = registerAttributeDefaults("anchorLeft",          NONE);

		public static const BACKGROUND_IMAGE:String     = registerAttributeDefaults("backgroundImage",     NONE);
		public static const BACKGROUND_TINT:String      = registerAttributeDefaults("backgroundTint",      WHITE);
		public static const BACKGROUND_9SCALE:String    = registerAttributeDefaults("background9Scale",    NONE);
		public static const BACKGROUND_COLOR:String     = registerAttributeDefaults("backgroundColor",     TRANSPARENT);
		public static const BACKGROUND_FILL_MODE:String = registerAttributeDefaults("backgroundFillMode",  FillMode.SCALE);

		public static const FONT_COLOR:String           = registerAttributeDefaults("fontColor",           INHERIT,                  true);
		public static const FONT_NAME:String            = registerAttributeDefaults("fontName",            INHERIT,                  true);
		public static const FONT_SIZE:String            = registerAttributeDefaults("fontSize",            INHERIT,                  true);

		public static const ALPHA:String                = registerAttributeDefaults("alpha",               ONE);
		public static const CLIPPING:String             = registerAttributeDefaults("clipping",            FALSE);
		public static const CURSOR:String               = registerAttributeDefaults("cursor",              AUTO);
		public static const FILTER:String               = registerAttributeDefaults("filter",              NONE);
		public static const Z_INDEX:String              = registerAttributeDefaults("zIndex",              ZERO);

		public static const LAYOUT:String               = registerAttributeDefaults("layout",              Layout.FLOW);
		public static const VISIBILITY:String           = registerAttributeDefaults("visibility",          Visibility.VISIBLE);

		public static const POSITION:String             = registerAttributeDefaults("position",            ZERO);
		public static const X:String                    = registerAttributeDefaults("x",                   ZERO);
		public static const Y:String                    = registerAttributeDefaults("y",                   ZERO);

		public static const PIVOT:String                = registerAttributeDefaults("pivot",               ZERO);
		public static const PIVOT_X:String              = registerAttributeDefaults("pivotX",              ZERO);
		public static const PIVOT_Y:String              = registerAttributeDefaults("pivotY",              ZERO);

		public static const ORIGIN:String               = registerAttributeDefaults("value",               ZERO);
		public static const ORIGIN_X:String             = registerAttributeDefaults("originX",             ZERO);
		public static const ORIGIN_Y:String             = registerAttributeDefaults("originY",             ZERO);

		public static const ORIENTATION:String          = registerAttributeDefaults("orientation",         Orientation.HORIZONTAL);
		public static const HALIGN:String               = registerAttributeDefaults("halign",              LEFT);
		public static const VALIGN:String               = registerAttributeDefaults("valign",              TOP);
		public static const IHALIGN:String              = registerAttributeDefaults("ihalign",             LEFT);
		public static const IVALIGN:String              = registerAttributeDefaults("ivalign",             TOP);
		public static const GAP:String                  = registerAttributeDefaults("gap",                 ZERO);
		public static const INTERLINE:String            = registerAttributeDefaults("interline",           ZERO);
		public static const WRAP:String                 = registerAttributeDefaults("wrap",                FALSE);
		public static const BREAK:String                = registerAttributeDefaults("break",               Break.AUTO);

		public static const TEXT:String                 = registerAttributeDefaults("text");

		//
		// Defaults
		//
		private static var _defaults:Dictionary;

		public static function registerAttributeDefaults(name:String, inited:String = null, isInheritable:Boolean = false, isStyleable:Boolean = true):String
		{
			_defaults ||= new Dictionary();
			_defaults[name] = {};
			_defaults[name].inited = inited;
			_defaults[name].isInheritable = isInheritable;
			_defaults[name].isStyleable = isStyleable;

			return name;
		}

		//
		// Queries
		//
		private static var _queries:Dictionary;

		private static function initialize():void
		{
			if (_queries == null)
			{
				_queries = new Dictionary();
				registerQueryAlias_internal("res", QueryUtil.queryResource);
				registerQueryAlias_internal("brightness", QueryUtil.queryBrightnessFilter);
				registerQueryAlias_internal("blur", QueryUtil.queryBlurFilter);
				registerQueryAlias_internal("glow", QueryUtil.queryGlowFilter);
				registerQueryAlias_internal("drop-shadow", QueryUtil.queryDropShadow);
			}
		}

		[Deprecated(message="Inflexible API, removal candidate")]
		/** Add new attribute query. */
		public static function registerQueryAlias(aliasName:String, callback:Function):void
		{
			registerQueryAlias_internal(aliasName, callback);
		}

		private static function registerQueryAlias_internal(aliasName:String, callback:Function):void
		{
			if (_queries == null) initialize();
			_queries[aliasName] = callback;
		}

		//
		// Attribute Implementation
		//
		private var _node:Node;
		private var _name:String;
		private var _change:Trigger;
		private var _bindings:Vector.<Binding>;

		private var _inited:SimpleValue;
		private var _styled:SimpleValue;
		private var _setted:SimpleValue;
		private var _basic:ComplexValue;
		private var _value:InheritValue;

		private var _valueCache:*;
		private var _valueCached:Boolean;

		public function Attribute(node:Node, name:String)
		{
			initialize();

			if (node == null) throw new ArgumentError("Parameter node must be non-null");
			if (name == null) throw new ArgumentError("Parameter name must be non-null");

			_node = node;
			_name = name;
			_change = new Trigger(this);

			_inited = new SimpleValue();
			_styled = new SimpleValue();
			_setted = new SimpleValue();
			_basic = new ComplexValue(_inited, _styled, _setted);
			_value = new InheritValue(_basic);
			_value.change.addListener(dispatchChange);

			if (_defaults[name] != null)
			{
				inited = _defaults[name].inited;
				isStyleable = _defaults[name].isStyleable;
				isInheritable = _defaults[name].isInheritable;
			}
			else
			{
				isStyleable = true;
				isInheritable = false;
			}
		}

		//
		// Value
		//
		/** The node that contains this attribute. */
		public function get node():Node { return _node; }

		/** Unique (in-node) attribute name. */
		public function get name():String { return _name; }

		/** Default attribute value. */
		public function get inited():String { return _inited.string; }
		public function set inited(value:String):void { _inited.string = value; }

		/** Attribute value from node style sheet. */
		public function get styled():String { return _styled.string }
		public function set styled(value:String):void { _styled.string = value; }

		/** Explicit setted attribute value via code or markup. */
		public function get setted():String { return _setted.string; }
		public function set setted(value:String):void { _setted.string = value; }

		/** Value calculated from inited->styled->setted. */
		public function get basic():String { return _basic.string; }
		/** Value calculated from basic & inherit parent attribute. */
		public function get value():String { return _value.string; }

		/** NB! Optimized <code>value</code>property. Witch call invokers (like 'url(...)', 'res(...)', 'blur(...)' etc.) for convert value to strongly typed object. */
		public function get valueCache():*
		{
			if (_valueCached == false)
			{
				// If attribute has no query - return origin value
				var queryInfo:Array = StringUtil.parseFunction(value);
				if (queryInfo == null) return value;

				// Obtain query method via queryInfo
				var queryMethodName:String = queryInfo.shift();
				var queryMethod:Function = _queries[queryMethodName];
				if (queryMethod == null) return value;

				queryInfo.unshift(this);

				_valueCache = queryMethod.apply(null, queryInfo);
				_valueCached = true;
			}

			return _valueCache;
		}

		//
		// Props
		//
		/** Need use styled property when calculating attribute value. */
		public function get isStyleable():Boolean { return _styled.enable; }
		public function set isStyleable(value:Boolean):void { _styled.enable = value; }

		public function get isInheritable():Boolean { return _value.isInheritable; }
		public function set isInheritable(value:Boolean):void
		{
			if (_value.isInheritable != value)
			{
				_value.isInheritable = value;

				if (value)
				{
					node.addListener(Event.ADDED,       onNodeAddedToParent);
					node.addListener(Event.REMOVED,     onNodeRemovedFromParent);
					if (node.parent) onNodeAddedToParent();
				}
				else
				{
					node.removeListener(Event.ADDED,    onNodeAddedToParent);
					node.removeListener(Event.REMOVED,  onNodeRemovedFromParent);
					onNodeRemovedFromParent();
				}
			}
		}

		private function onNodeAddedToParent():void
		{
			_value.parent = node.parent.getOrCreateAttribute(name)._value;
		}

		private function onNodeRemovedFromParent():void
		{
			_value.parent = null;
		}

		/** Attribute value is inherit from parent. */
		public function get isInherit():Boolean { return _value.isInherit; }

		/** Attribute value is mapped to resource. */
		public function get isResource():Boolean
		{
			var split:Array = StringUtil.parseFunction(value);
			return split && split[0] == "res";
		}

		//
		// Misc
		//
		/** @private */
		public function addBinding(trigger:Trigger, getter:Function, setter:Function):void
		{
			_bindings ||= new <Binding>[];
			_bindings[_bindings.length] = new Binding(trigger, getter, null, setter, null);
		}

		public function setSetted(value:String):void { setted = value; }
		public function getValue():String { return value; }

		internal function dispatchChange():void
		{
			_valueCache = null;
			_valueCached = false;
			change.dispatch();
		}

		/** @private Value change trigger. */
		public function get change():Trigger { return _change; }
	}
}

import talon.Attribute;
import talon.utils.Trigger;

interface IValue
{
	function get change():Trigger;
	function get string():String;
}

/** Simple string value. */
class SimpleValue implements IValue
{
	private var _string:String;
	private var _enable:Boolean = true;
	private var _change:Trigger = new Trigger(this);

	public function get change():Trigger { return _change; }

	public function get enable():Boolean { return _enable; }
	public function set enable(value:Boolean):void
	{
		if (_enable != value)
		{
			_enable = value;
			if (_string) _change.dispatch();
		}
	}

	public function get string():String { return _enable ? _string : null; }
	public function set string(value:String):void
	{
		if (_string != value)
		{
			_string = value;
			if (_enable) _change.dispatch();
		}
	}
}

/** Value calculated via others based on priority. */
class ComplexValue implements IValue
{
	private var _change:Trigger;
	private var _values:Vector.<IValue>;

	public function ComplexValue(...values):void
	{
		_change = new Trigger(this);
		_values = Vector.<IValue>(values);

		for each (var value:IValue in values)
			value.change.addListener(onValueChange);
	}

	public function onValueChange(value:IValue):void
	{
		if (current == value)
			change.dispatch();
	}

	public function get change():Trigger { return _change; }
	public function get string():String { return current.string; }
	public function get current():IValue
	{
		for (var i:int = _values.length - 1; i >= 0; i--)
		{
			var value:IValue = _values[i];
			if (value.string) return value;
		}

		return _values[0];
	}
}

/** Value witch can be inherit from other. */
class InheritValue implements IValue
{
	private var _isInheritable:Boolean;
	private var _change:Trigger;
	private var _parent:IValue;
	private var _basic:IValue;

	public function InheritValue(basic:IValue)
	{
		_change = new Trigger(this);
		_basic = basic;
		_basic.change.addListener(onBasicChange);
	}

	public function get isInherit():Boolean { return _isInheritable && _parent && _basic.string == Attribute.INHERIT; }

	public function get isInheritable():Boolean { return _isInheritable }
	public function set isInheritable(value:Boolean):void
	{
		if (_isInheritable != value)
		{
			var before:String = string;
			_isInheritable = value;
			if (before != string) _change.dispatch();
		}
	}

	public function get change():Trigger { return _change; }
	public function get string():String { return isInherit ? parent.string : _basic.string; }

	public function get parent():IValue { return _parent; }
	public function set parent(value:IValue):void
	{
		_parent && _parent.change.removeListener(onParentChange);
		_parent = value;
		_parent && _parent.change.addListener(onParentChange);
		if (_isInheritable && _basic.string == Attribute.INHERIT) _change.dispatch();
	}

	private function onBasicChange():void { if (!isInherit || _basic.string == Attribute.INHERIT) _change.dispatch(); }
	private function onParentChange():void { if (isInherit) _change.dispatch(); }
}