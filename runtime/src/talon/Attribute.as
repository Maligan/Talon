package talon
{
	import talon.enums.*;
	import talon.layout.Layout;
	import talon.utils.*;

	public final class Attribute
	{
        public static const INHERIT:String      = "inherit";
        public static const NONE:String         = "none";

        private static const AUTO:String         = "auto";
        private static const FALSE:String        = "false";
        private static const TRUE:String         = "true";
        private static const ZERO:String         = "0px";
        private static const ONE:String          = "1";
        private static const LEFT:String         = "left";
		private static const TOP:String          = "top";

		//
		// Standard Attribute list
		//
		public static const ID:String                              = registerAttribute("id",                  null,                     false,  false);
		public static const TYPE:String                            = registerAttribute("type",                null,                     false,  false);
		public static const CLASS:String                           = registerAttribute("class",               null,                     false,  false);
		public static const STATE:String                           = registerAttribute("state",               null,                     false,  false);

		public static const WIDTH:String                           = registerAttribute("width",               NONE);
		public static const MIN_WIDTH:String                       = registerAttribute("minWidth",            NONE);
		public static const MAX_WIDTH:String                       = registerAttribute("maxWidth",            NONE);

		public static const HEIGHT:String                          = registerAttribute("height",              NONE);
		public static const MIN_HEIGHT:String                      = registerAttribute("minHeight",           NONE);
		public static const MAX_HEIGHT:String                      = registerAttribute("maxHeight",           NONE);

		public static const MARGIN_TOP:String                      = registerAttribute("marginTop",           ZERO);
		public static const MARGIN_RIGHT:String                    = registerAttribute("marginRight",         ZERO);
		public static const MARGIN_BOTTOM:String                   = registerAttribute("marginBottom",        ZERO);
		public static const MARGIN_LEFT:String                     = registerAttribute("marginLeft",          ZERO);
		public static const MARGIN:String                          = registerComposite("margin",              [MARGIN_TOP, MARGIN_RIGHT, MARGIN_BOTTOM, MARGIN_LEFT]);

		public static const PADDING_TOP:String                     = registerAttribute("paddingTop",          ZERO);
		public static const PADDING_RIGHT:String                   = registerAttribute("paddingRight",        ZERO);
		public static const PADDING_BOTTOM:String                  = registerAttribute("paddingBottom",       ZERO);
		public static const PADDING_LEFT:String                    = registerAttribute("paddingLeft",         ZERO);
		public static const PADDING:String                         = registerComposite("padding",             [PADDING_TOP, PADDING_RIGHT, PADDING_BOTTOM, PADDING_LEFT]);

		public static const ANCHOR_TOP:String                      = registerAttribute("anchorTop",           NONE);
		public static const ANCHOR_RIGHT:String                    = registerAttribute("anchorRight",         NONE);
		public static const ANCHOR_BOTTOM:String                   = registerAttribute("anchorBottom",        NONE);
		public static const ANCHOR_LEFT:String                     = registerAttribute("anchorLeft",          NONE);
		public static const ANCHOR:String                          = registerComposite("anchor",              [ANCHOR_TOP, ANCHOR_RIGHT, ANCHOR_BOTTOM, ANCHOR_LEFT]);

		public static const BACKGROUND_FILL:String                 = registerAttribute("backgroundFill",                NONE);
		public static const BACKGROUND_STRETCH_GRID_TOP:String     = registerAttribute("backgroundStretchGridTop",      NONE);
		public static const BACKGROUND_STRETCH_GRID_RIGHT:String   = registerAttribute("backgroundStretchGridRight",    NONE);
		public static const BACKGROUND_STRETCH_GRID_BOTTOM:String  = registerAttribute("backgroundStretchGridBottom",   NONE);
		public static const BACKGROUND_STRETCH_GRID_LEFT:String    = registerAttribute("backgroundStretchGridLeft",     NONE);
		public static const BACKGROUND_STRETCH_GRID:String         = registerComposite("backgroundStretchGrid",         [BACKGROUND_STRETCH_GRID_TOP, BACKGROUND_STRETCH_GRID_RIGHT, BACKGROUND_STRETCH_GRID_BOTTOM, BACKGROUND_STRETCH_GRID_LEFT]);
		public static const BACKGROUND_ALPHA:String                = registerAttribute("backgroundAlpha",               ONE);
		public static const BACKGROUND_FILL_MODE_HORIZONTAL:String = registerAttribute("backgroundFillModeHorizontal",  FillMode.STRETCH);
		public static const BACKGROUND_FILL_MODE_VERTICAL:String   = registerAttribute("backgroundFillModeVertical",    FillMode.STRETCH);
		public static const BACKGROUND_FILL_MODE:String            = registerComposite("backgroundFillMode",            [BACKGROUND_FILL_MODE_HORIZONTAL, BACKGROUND_FILL_MODE_VERTICAL]);

		public static const FONT_COLOR:String                      = registerAttribute("fontColor",           INHERIT,                  true);
		public static const FONT_NAME:String                       = registerAttribute("fontName",            INHERIT,                  true);
		public static const FONT_SIZE:String                       = registerAttribute("fontSize",            INHERIT,                  true);
		public static const FONT_AUTO_SCALE:String                 = registerAttribute("fontAutoScale",       INHERIT,                  true);
		public static const FONT_SHARPNESS:String                  = registerAttribute("fontSharpness",       INHERIT,                  true);

		public static const TOUCH_MODE:String                      = registerAttribute("touchMode",           TouchMode.BRANCH);
		public static const TOUCH_EVENTS:String                    = registerAttribute("touchEvents",         FALSE);
		public static const CURSOR:String                          = registerAttribute("cursor",              AUTO);


		public static const ALPHA:String                           = registerAttribute("alpha",               ONE);
		public static const CLIPPING:String                        = registerAttribute("clipping",            FALSE);
		public static const BLEND_MODE:String                      = registerAttribute("blendMode",           AUTO);
		public static const FILTER:String                          = registerAttribute("filter",              NONE);
		public static const Z_INDEX:String                         = registerAttribute("zIndex",              ZERO);
		public static const VISIBLE:String                         = registerAttribute("visible",             TRUE);
		public static const LAYOUT:String                          = registerAttribute("layout",              Layout.FLOW);

		public static const X:String                               = registerAttribute("x",                   ZERO);
		public static const Y:String                               = registerAttribute("y",                   ZERO);
		public static const POSITION:String                        = registerComposite("position",            [X, Y]);

		public static const PIVOT_X:String                         = registerAttribute("pivotX",              ZERO);
		public static const PIVOT_Y:String                         = registerAttribute("pivotY",              ZERO);
		public static const PIVOT:String                           = registerComposite("pivot",               [PIVOT_X, PIVOT_Y]);

		public static const HALIGN:String                          = registerAttribute("halign",              LEFT);
		public static const VALIGN:String                          = registerAttribute("valign",              TOP);
		public static const ALIGN:String                           = registerComposite("align",               [HALIGN, VALIGN]);

		public static const ORIENTATION:String                     = registerAttribute("orientation",         Orientation.HORIZONTAL);
		public static const IHALIGN:String                         = registerAttribute("ihalign",             LEFT);
		public static const IVALIGN:String                         = registerAttribute("ivalign",             TOP);
		public static const GAP:String                             = registerAttribute("gap",                 ZERO);
		public static const INTERLINE:String                       = registerAttribute("interline",           ZERO);
		public static const WRAP:String                            = registerAttribute("wrap",                FALSE);
		public static const BREAK:String                           = registerAttribute("break",               BreakMode.AUTO);

		public static const TEXT:String                            = registerAttribute("text");
		public static const SRC:String                             = registerAttribute("src");

		//
		// Defaults
		//
		private static var _defInited:Object;
		private static var _defIsInheritable:Object;
		private static var _defIsStyleable:Object;
		private static var _defFormat:Object;

		private static var _inheritable:Vector.<String>;

		public static function registerAttribute(name:String, inited:String = null, isInheritable:Boolean = false, isStyleable:Boolean = true):String
		{
			_defInited ||= {};
			_defInited[name] = inited;

			_defIsInheritable ||= {};
			_defIsInheritable[name] = isInheritable;

			_defIsStyleable ||= {};
			_defIsStyleable[name] = isStyleable;

			if (isInheritable)
			{
				_inheritable ||= new <String>[];
				_inheritable[_inheritable.length] = name;
			}

			return name;
		}

		public static function registerComposite(name:String, attributes:Array):String
		{
			_defFormat ||= {};
			_defFormat[name] = attributes;

			return name;
		}

		/** @private */
		public static function getInheritableAttributeNames():Vector.<String>
		{
			return _inheritable || new Vector.<String>();
		}

		private static function buildSolver(attribute:Attribute):ISolver
		{
			var attributes:Array = _defFormat[attribute.name];
			if (attributes)
			{
				var format:String = attributes.length == 4 ? CompositeSolver.FORMAT_QUAD : CompositeSolver.FORMAT_PAIR;

				var solvers:Vector.<ISolver> = new <ISolver>[];
				for each (var attributeName:String in attributes)
				{
					var attribute:Attribute = attribute.node.getOrCreateAttribute(attributeName);
					solvers[solvers.length] = attribute._solver;
				}

				return new CompositeSolver(format, solvers);
			}
			else if (_defIsInheritable[attribute.name])
			{
				return new InheritableSolver(attribute);
			}


			return new SimpleSolver();
		}

		//
		// Attribute Implementation
		//
		private var _node:Node;
		private var _name:String;
		private var _change:Trigger;
		private var _solver:ISolver;

		private var _valueCache:*;
		private var _valueCacheIsResource:Boolean;
		private var _valueCached:Boolean;

		/** @private */
		public function Attribute(node:Node, name:String)
		{
			if (node == null) throw new ArgumentError("Parameter node must be non-null");
			if (name == null) throw new ArgumentError("Parameter name must be non-null");

			_node = node;
			_name = name;
			_change = new Trigger(this);
			_solver = buildSolver(this);
			_solver.change.addListener(dispatchChange);

			if (!isComposite) inited = _defInited[name];
		}

		//
		// Value
		//
		/** The node that contains this attribute. */
		public function get node():Node { return _node; }

		/** Unique (in-node) attribute name. */
		public function get name():String { return _name; }

		/** Default attribute value. */
		public function get inited():String { return _solver.getValue(0, name); }
		public function set inited(value:String):void { _solver.setValue(0, name, value); }

		/** Attribute value from node style sheet. */
		public function get styled():String { return _solver.getValue(1, name); }
		public function set styled(value:String):void { _solver.setValue(1, name, value); }

		/** Explicit setted attribute value via code or markup. */
		public function get setted():String { return _solver.getValue(2, name); }
		public function set setted(value:String):void { _solver.setValue(2, name, value); }

		/** Value calculated from (inited->styled->setted) & inherit parent attribute. */
		public function get value():String { return _solver.value; }

		/** NB! Optimized <code>value</code>property. Which can extract mapped resource. */
		public function get valueCache():*
		{
			if (_valueCached == false)
			{
				// By default is equal to value
				_valueCache = value;
				_valueCacheIsResource = false;
				_valueCached = true;

				if (name == "text")
				{
					trace()
				}

				// Extract resource value
                // FIXME: Stack overflow (loops)
				while (_valueCache is String)
				{
					var key:String = StringParseUtil.parseResource(_valueCache);
					if (key == null) break;

					_valueCacheIsResource = true;
					_valueCache = node.getResource(key);
				}
			}

			return _valueCache;
		}

		//
		// Props
		//
		/** Use styled property when calculating attribute value. */
		public function get isStyleable():Boolean { return _defIsStyleable[name]; }

		/** If attribute value == 'inherit' concrete value must be taken from parent node. */
		public function get isInheritable():Boolean { return _solver is InheritableSolver; }

		/** Attribute has composite format. */
		public function get isComposite():Boolean { return _solver is CompositeSolver; }

		/** Attribute 'value' is inherit from parent. */
		public function get isInherit():Boolean { return isInheritable && InheritableSolver(_solver).isInherit; }

		/** Attribute 'value' is mapped to resource. */
		public function get isResource():Boolean { valueCache; return _valueCacheIsResource; }

		//
		// Misc
		//
		/** @private */
		public function upstream(attribute:Attribute):void
		{
			_solver = attribute._solver;
			dispatchChange();
		}

		public function dispose():void
		{
			_valueCache = null;
			_valueCached = false;
			_change.removeListeners();
		}

		/** @private Value change trigger. */
		public function get change():Trigger
		{
			return _change;
		}

		internal function dispatchChange():void
		{
			_valueCache = null;
			_valueCached = false;
			change.dispatch();
		}
	}
}

import flash.events.Event;
import talon.Attribute;
import talon.utils.Trigger;

interface ISolver
{
	function getValue(priority:int, key:String):String;
	function setValue(priority:int, key:String, value:String):void;
	function get change():Trigger;
	function get value():String;
}

class SimpleSolver implements ISolver
{
	private var _change:Trigger;
	private var _hashes:Vector.<Object>;
	private var _orders:Object;

	public function SimpleSolver():void
	{
		_change = new Trigger(this);
		_hashes = new Vector.<Object>();
		_orders = new Object();
	}

	public function getValue(priority:int, key:String):String
	{
		return (priority < _hashes.length) ? _hashes[priority][key] : null;
	}

	public function setValue(priority:int, key:String, string:String):void
	{
		var prev:String = value;

		if (_hashes.length < priority + 1)
			_hashes.length = priority + 1;

		var hash:Object = _hashes[priority] || (_hashes[priority] = {});
		var order:Vector.<String> = _orders[hash] || (_orders[hash] = new Vector.<String>());

		// Mark as last changed key
		var indexOf:int = order.indexOf(key);
		if (indexOf != -1) order.removeAt(indexOf);
		order[order.length] = key;

		// Set new value
		hash[key] = string;

		// Dispatch change
		if (prev != value) _change.dispatch();
	}

	public function get change():Trigger
	{
		return _change;
	}

	public function get value():String
	{
		for (var i:int = _hashes.length-1; i >= 0; i--)
		{
			var hash:Object = _hashes[i];
			if (hash == null) continue;
			var order:Object = _orders[hash];

			var j:int = order.length;
			while (--j >= 0)
			{
				var last:String = order[j];
				var lastValue:String = hash[last];
				if (lastValue) return lastValue;
			}
		}

		return null;
	}
}

class InheritableSolver extends SimpleSolver
{
	private var _attribute:Attribute;
	private var _parent:Attribute;

	public function InheritableSolver(attribute:Attribute)
	{
		_attribute = attribute;
		_attribute.node.addTriggerListener(Event.ADDED, onAdded);
		_attribute.node.addTriggerListener(Event.REMOVED, onRemoved);
	}

	private function onAdded():void
	{
		_parent = _attribute.node.parent.getOrCreateAttribute(_attribute.name);
		_parent.change.addListener(onParentChange);
		if (super.value == Attribute.INHERIT) change.dispatch();
	}

	private function onRemoved():void
	{
		_parent.change.removeListener(onParentChange);
		_parent = null;
		if (super.value == Attribute.INHERIT) change.dispatch();
	}

	private function onParentChange():void
	{
		if (isInherit) change.dispatch();
	}

	public override function get value():String
	{
		return isInherit ? _parent.value : super.value;
	}

	public function get isInherit():Boolean
	{
		return _parent && super.value == Attribute.INHERIT;
	}
}

/** Solver for composite attributes (e.g. padding, margin, align etc.) */
class CompositeSolver extends SimpleSolver
{
	private var _solvers:Vector.<ISolver>;
	private var _formats:Array;
	private var _isSuppressed:Boolean;
	private var _hasSuppressedChange:Boolean;

	public function CompositeSolver(format:String, solvers:Vector.<ISolver>)
	{
		_solvers = solvers;
		_formats = prepare(format, solvers);

		for each (var solver:ISolver in solvers)
			solver.change.addListener(onSolverChange);
	}

	private function onSolverChange():void
	{
		if (!_isSuppressed)
			change.dispatch();
		else
			_hasSuppressedChange = true;
	}

	private function suppress(value:Boolean):void
	{
		var needChange:Boolean = !value && _hasSuppressedChange;

		_isSuppressed = value;
		_hasSuppressedChange = false;

		if (needChange) change.dispatch();
	}

	public override function setValue(priority:int, key:String, string:String):void
	{
		// Set value for getValue call work correctly (and attribute styled/setted were real)
		super.setValue(priority, key, string);

		// Forward value to sub solvers
		suppress(true);
		compositeSetValues(_formats, string, priority, key);
		suppress(false);
	}

	public override function get value():String
	{
		return compositeGetValue(_formats);
	}

	//
	// Static
	//
	public static const FORMAT_QUAD:String = "{0, 1, 2, 3} | {0, 2} {1, 3} | {0} {1, 3} {2} | {0} {1} {2} {3}";
	public static const FORMAT_PAIR:String = "{0, 1} | {0} {1}";

	/** Convert to more comfortable structure. */
	private static function prepare(format:String, solvers:Vector.<ISolver>):Array
	{
		var result:Array = [];

		var alternates:Array = format.split(/\s*\|\s*/);
		for (var a:int = 0; a < alternates.length; a++)
		{
			var groups:Array = alternates[a].split(/\}\s*\{/);
			for (var g:int = 0; g < groups.length; g++)
			{
				var items:Array = groups[g].replace(/[{}]/g, "").split(/\s*,\s*/);
				for (var i:int = 0; i < items.length; i++)
				{
					result[a] ||= [];
					result[a][g] ||= [];
					result[a][g][i] = solvers[parseInt(items[i])];
				}
			}
		}

		return result;
	}

	private static function compositeGetValue(formats:Array):String
	{
		// Search matched pattern
		enumeration:
			for each (var format:Array in formats)
			{
				for each (var group:Array in format)
					for (var i:int = 0; i < group.length; i++)
						if (group[i].value != group[0].value)
							continue enumeration;

				break;
			}

		// Build string
		var builder:Array = [];
		for each (group in format) builder[builder.length] = ISolver(group[0]).value;
		return builder.join(' ');
	}

	private static function compositeSetValues(formats:Array, value:String, priority:int, key:String):void
	{
		var split:Array = value ? value.split(' ') : [''];
		if (split.length > formats.length)
			split.length = formats.length;

		var format:Array = formats[split.length - 1];

		for (var i:int = 0; i < format.length; i++)
			for each (var solver:ISolver in format[i])
				solver.setValue(priority, key, value ? split[i] : null);
	}
}
