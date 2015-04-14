package talon
{
	import flash.ui.MouseCursor;
	import flash.utils.Dictionary;

	import starling.events.Event;
	import starling.events.EventDispatcher;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	import talon.enums.Break;
	import talon.enums.FillMode;
	import talon.enums.Orientation;
	import talon.enums.Visibility;
	import talon.layout.Layout;
	import talon.types.Gauge;
	import talon.utils.QueryUtil;
	import talon.utils.StringUtil;

	public final class Attribute extends EventDispatcher
	{
		public static const TRANSPARENT:String = "transparent";
		public static const WHITE:String = "white";
		public static const FALSE:String = "false";
		public static const AUTO:String = Gauge.AUTO;
		public static const NONE:String = Gauge.NONE;
		public static const ZERO:String = "0px";
		public static const ONE:String = "1";
		public static const INHERIT:String = "inherit";

		//
		// Standard Attribute list
		//
		public static const ID:String = registerAttributeDefaults("id", null, false, false);
		public static const TYPE:String = registerAttributeDefaults("type", null, false, false);
		public static const CLASS:String = registerAttributeDefaults("class", null, false, false);
		public static const STATE:String = registerAttributeDefaults("state", null, false, false);

		public static const WIDTH:String = registerAttributeDefaults("width", AUTO);
		public static const MIN_WIDTH:String = registerAttributeDefaults("minWidth", NONE);
		public static const MAX_WIDTH:String = registerAttributeDefaults("maxWidth", NONE);

		public static const HEIGHT:String = registerAttributeDefaults("height", AUTO);
		public static const MIN_HEIGHT:String = registerAttributeDefaults("minHeight", NONE);
		public static const MAX_HEIGHT:String = registerAttributeDefaults("maxHeight", NONE);

		public static const MARGIN:String = registerAttributeDefaults("margin", ZERO);
		public static const MARGIN_TOP:String = registerAttributeDefaults("marginTop", ZERO);
		public static const MARGIN_RIGHT:String = registerAttributeDefaults("marginRight", ZERO);
		public static const MARGIN_BOTTOM:String = registerAttributeDefaults("marginBottom", ZERO);
		public static const MARGIN_LEFT:String = registerAttributeDefaults("marginLeft", ZERO);

		public static const PADDING:String = registerAttributeDefaults("padding", ZERO);
		public static const PADDING_TOP:String = registerAttributeDefaults("paddingTop", ZERO);
		public static const PADDING_RIGHT:String = registerAttributeDefaults("paddingRight", ZERO);
		public static const PADDING_BOTTOM:String = registerAttributeDefaults("paddingBottom", ZERO);
		public static const PADDING_LEFT:String = registerAttributeDefaults("paddingLeft", ZERO);

		public static const ANCHOR:String = registerAttributeDefaults("anchor", NONE);
		public static const ANCHOR_TOP:String = registerAttributeDefaults("anchorTop", NONE);
		public static const ANCHOR_RIGHT:String = registerAttributeDefaults("anchorRight", NONE);
		public static const ANCHOR_BOTTOM:String = registerAttributeDefaults("anchorBottom", NONE);
		public static const ANCHOR_LEFT:String = registerAttributeDefaults("anchorLeft", NONE);

		public static const BACKGROUND_IMAGE:String = registerAttributeDefaults("backgroundImage", NONE);
		public static const BACKGROUND_TINT:String = registerAttributeDefaults("backgroundTint", WHITE);
		public static const BACKGROUND_9SCALE:String = registerAttributeDefaults("background9Scale", NONE);
		public static const BACKGROUND_COLOR:String = registerAttributeDefaults("backgroundColor", TRANSPARENT);
		public static const BACKGROUND_FILL_MODE:String = registerAttributeDefaults("backgroundFillMode", FillMode.SCALE);

		public static const FONT_COLOR:String = registerAttributeDefaults("fontColor", INHERIT, true);
		public static const FONT_NAME:String = registerAttributeDefaults("fontName", INHERIT, true);
		public static const FONT_SIZE:String = registerAttributeDefaults("fontSize", INHERIT, true);

		public static const ALPHA:String = registerAttributeDefaults("alpha", ONE);
		public static const CLIPPING:String = registerAttributeDefaults("clipping", FALSE);
		public static const CURSOR:String = registerAttributeDefaults("cursor", MouseCursor.AUTO);
		public static const FILTER:String = registerAttributeDefaults("filter", NONE);

		public static const LAYOUT:String = registerAttributeDefaults("layout", Layout.FLOW);
		public static const VISIBILITY:String = registerAttributeDefaults("visibility", Visibility.VISIBLE);

		public static const POSITION:String = registerAttributeDefaults("position", ZERO);
		public static const X:String = registerAttributeDefaults("x", ZERO);
		public static const Y:String = registerAttributeDefaults("y", ZERO);

		public static const PIVOT:String = registerAttributeDefaults("pivot", ZERO);
		public static const PIVOT_X:String = registerAttributeDefaults("pivotX", ZERO);
		public static const PIVOT_Y:String = registerAttributeDefaults("pivotY", ZERO);

		public static const ORIGIN:String = registerAttributeDefaults("value", ZERO);
		public static const ORIGIN_X:String = registerAttributeDefaults("originX", ZERO);
		public static const ORIGIN_Y:String = registerAttributeDefaults("originY", ZERO);

		public static const ORIENTATION:String = registerAttributeDefaults("orientation", Orientation.HORIZONTAL);
		public static const HALIGN:String = registerAttributeDefaults("halign", HAlign.LEFT);
		public static const VALIGN:String = registerAttributeDefaults("valign", VAlign.TOP);
		public static const IHALIGN:String = registerAttributeDefaults("ihalign", HAlign.LEFT);
		public static const IVALIGN:String = registerAttributeDefaults("ivalign", VAlign.TOP);
		public static const GAP:String = registerAttributeDefaults("gap", ZERO);
		public static const INTERLINE:String = registerAttributeDefaults("interline", ZERO);
		public static const WRAP:String = registerAttributeDefaults("wrap", FALSE);
		public static const BREAK:String = registerAttributeDefaults("break", Break.AUTO);

		public static const TEXT:String = registerAttributeDefaults("text");

		//
		// Defaults
		//
		private static var _defaults:Dictionary;

		public static function registerAttributeDefaults(name:String, initial:String = null, inheritable:Boolean = false, styleable:Boolean = true):String
		{
			_defaults ||= new Dictionary();
			_defaults[name] = {};
			_defaults[name].initial = initial;
			_defaults[name].inheritable = inheritable;
			_defaults[name].styleable = styleable;

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

		private var _assignedValueGetter:Function;
		private var _assignedValueSetter:Function;
		private var _assignedDispatcher:EventDispatcher;
		private var _assignIgnore:Boolean;

		private var _styleable:Boolean;
		private var _styled:String;
		private var _initial:String;
		private var _assigned:String;
		private var _inheritable:Boolean;
		private var _inherit:String;

		private var _expanded:*;
		private var _expandedCached:Boolean;

		public function Attribute(node:Node, name:String)
		{
			initialize();

			if (node == null) throw new ArgumentError("Parameter node must be non-null");
			if (name == null) throw new ArgumentError("Parameter name must be non-null");

			_node = node;
			_name = name;
			_initial = null;
			_styleable = true;
			_inheritable = false;

			if (_defaults[name] != null)
			{
				_initial = _defaults[name].initial;
				_styleable = _defaults[name].styleable;
				// Getter for add listeners
				inheritable = _defaults[name].inheritable;
			}
		}

		//
		// Base properties
		//
		/** The node that contains this attribute. */
		public function get node():Node { return _node; }

		/** Unique (in-node) attribute name. */
		public function get name():String { return _name; }

		/**
		 * Attribute value (based on assigned, styled and initial values)
		 * NB! There are two optimized version of this property: origin & expanded, but remember this value is basis for them.
		 */
		public function get value():String { return assigned || (styleable?styled:null) || initial; }

		//
		// Optimization
		//
		/** NB! Optimized <code>value</code> property. Expand 'inherit' value if attribute is inheritable. */
		public function get origin():String { return isInherit ? inherit : value; }

		/** NB! Optimized <code>value</code>property. Expand 'inherit' value and call invokers (like 'url(...)', 'res(...)', 'blur(...)' etc.) for convert value to strongly typed object. */
		public function get expanded():*
		{
			if (_expandedCached == false)
			{
				// If attribute has no query - return origin value
				var queryInfo:Array = StringUtil.parseFunction(origin);
				if (queryInfo == null) return origin;

				// Obtain query method via queryInfo
				var queryMethodName:String = queryInfo.shift();
				var queryMethod:Function = _queries[queryMethodName];
				if (queryMethod == null) return origin;

				queryInfo.unshift(this);

				_expanded = queryMethod.apply(null, queryInfo);
				_expandedCached = true;
			}

			return _expanded;
		}

		//
		// Inherit
		//
		public function get inherit():String { return _inherit; }

		public function get inheritable():Boolean { return _inheritable; }
		public function set inheritable(value:Boolean):void
		{
			if (_inheritable != value)
			{
				_inheritable = value;

				if (_inheritable)
				{
					_node.addEventListener(Event.ADDED, onAddedToParent);
					_node.addEventListener(Event.REMOVED, onRemovedFromParent);
				}
				else
				{
					_node.removeEventListener(Event.ADDED, onAddedToParent);
					_node.removeEventListener(Event.REMOVED, onRemovedFromParent);
				}

				if (_inheritable)
					validateInherit();
				else if (origin == INHERIT)
					dispatchChange();
			}
		}

		private function onAddedToParent(e:Event):void
		{
			var target:Attribute = node.parent.getOrCreateAttribute(name);
			target.addEventListener(Event.CHANGE, validateInherit);
			validateInherit();
		}

		private function onRemovedFromParent(e:Event):void
		{
			var target:Attribute = node.parent.getOrCreateAttribute(name);
			target.removeEventListener(Event.CHANGE, validateInherit);
			validateInherit();
		}

		private function validateInherit():void
		{
			_inherit = node.parent ? node.parent.getOrCreateAttribute(name).origin : null;
			if (isInherit) dispatchChange();
		}

		//
		// Initial
		//
		public function get initial():String { return _initial }
		public function set initial(value:String):void
		{
			if (_initial != value)
			{
				_initial = value;

				if (_assigned == null && (!_styleable || _styled == null))
				{
					if (_assignedValueSetter != null)
					{
						_assignIgnore = true;
						_assignedValueSetter(this.origin);
						_assignIgnore = false;
					}

					dispatchChange();
				}
			}
		}

		//
		// Assign
		//
		public function get assigned():String { return _assigned; }
		public function set assigned(value:String):void
		{
			// XXX: Binding twoway/oneway
			if (_assignedValueSetter != null)
			{
				_assignedValueSetter(value);
			}
			else if (_assigned != value)
			{
				_assigned = value;
				// TODO: value can be not changed (_assigned == styled || initial)
				dispatchChange();
			}
		}

		/** @private Bind assigned value to same object. */
		public function bind(dispatcher:EventDispatcher, getter:Function, setter:Function):void
		{
			if (dispatcher && getter && setter)
			{
				_assignedValueGetter = getter;
				_assignedValueSetter = setter;
				_assignedDispatcher = dispatcher;
				_assignedDispatcher.addEventListener(Event.CHANGE, onAssignedChange);
				assigned = getter();
			}
			else
			{
				if (dispatcher == null) throw new ArgumentError("Invalid binding dispatcher");
				if (getter == null)     throw new ArgumentError("Invalid binding getter");
				if (setter == null)     throw new ArgumentError("Invalid binding setter");
			}
		}

		public function unbind():void
		{
			_assignedDispatcher.removeEventListener(Event.CHANGE, onAssignedChange);
			_assignedDispatcher = null;
			_assignedValueSetter = null;
			_assignedValueGetter = null;
		}

		private function onAssignedChange(e:Event):void
		{
			if (_assignIgnore) return;

			var value:String = _assignedValueGetter();

			if (_assigned != value)
			{
				_assigned = value;
				dispatchChange();
			}
		}

		//
		// Style
		//
		/** Need use styled property when calculating attribute value. */
		public function get styleable():Boolean { return _styleable; }
		public function set styleable(value:Boolean):void
		{
			if (_styleable != value)
			{
				_styleable = value;

				if (_assigned == null && _styled != null)
				{
					dispatchChange();
				}
			}
		}

		/** Attribute value from node style sheet. */
		public function get styled():String { return _styled }
		public function set styled(value:String):void
		{
			if (_styled != value)
			{
				_styled = value;

				if (_styleable && _assigned == null)
				{
					if (_assignedValueSetter != null)
					{
						_assignIgnore = true;
						_assignedValueSetter(this.origin);
						_assignIgnore = false;
					}

					dispatchChange();
				}
			}
		}

		//
		// Misc
		//
		/** Attribute value is mapped to resource. */
		public function get isResource():Boolean
		{
			var split:Array = StringUtil.parseFunction(origin);
			return split && split[0] == "res";
		}

		/** Attribute value is inherit from parent. */
		public function get isInherit():Boolean
		{
			return inheritable && value==INHERIT;
		}

		internal function dispatchChange():void
		{
			_expanded = null;
			_expandedCached = false;
			dispatchEventWith(Event.CHANGE);
		}
	}
}