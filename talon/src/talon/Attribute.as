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

		private static const _dInitial:Dictionary = new Dictionary();
		private static const _dInheritable:Dictionary = new Dictionary();
		private static const _dStyleable:Dictionary = new Dictionary();

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

		public static function registerAttributeDefaults(name:String, initial:String = null, inheritable:Boolean = false, styleable:Boolean = true):String
		{
			_dInitial[name] = initial;
			_dInheritable[name] = inheritable;
			_dStyleable[name] = styleable;
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
				registerQueryAlias("res", QueryUtil.queryResource);
				registerQueryAlias("brightness", QueryUtil.queryBrightnessFilter);
				registerQueryAlias("blur", QueryUtil.queryBlurFilter);
				registerQueryAlias("glow", QueryUtil.queryGlowFilter);
				registerQueryAlias("drop-shadow", QueryUtil.queryDropShadow);
			}
		}

		/** Add new attribute query. TODO: Move to other place... */
		public static function registerQueryAlias(aliasName:String, callback:Function):void
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
			_initial = _dInitial[name];
			_styleable = _dStyleable.hasOwnProperty(name) ? _dStyleable[name] : true;
			_inheritable = _dInheritable[name];
		}

		//
		// Base properties
		//
		/** The node that contains this attribute. */
		public function get node():Node { return _node; }

		/** Unique (in-node) attribute name. */
		public function get name():String { return _name; }

		/**
		 * talon.Attribute value (based on assigned, styled and initial values)
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
					_node.parent && node.parent.addEventListener(Event.CHANGE, onParentNodeAttributeChange);
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
			node.parent.addEventListener(Event.CHANGE, onParentNodeAttributeChange);
			validateInherit();
		}

		private function onRemovedFromParent(e:Event):void
		{
			node.parent.removeEventListener(Event.CHANGE, onParentNodeAttributeChange);
			validateInherit();
		}

		private function onParentNodeAttributeChange(e:Event):void
		{
			if (e.data == name) validateInherit();
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
						// Для того что бы в onAssignedChange не установилось значение _assigned
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
			}
			else
			{
				if (dispatcher == null) throw new ArgumentError("Invalid binding dispatcher");
				if (getter == null) throw new ArgumentError("Invalid binding getter");
				if (setter == null) throw new ArgumentError("Invalid binding setter");
			}
		}

		private function onAssignedChange(e:Event):void
		{
			if (_assignIgnore == false)
			{
				_assigned = _assignedValueGetter();
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

		/** talon.Attribute value from node style sheet. */
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
						// Для того что бы в onAssignedChange не установилось значение _assigned
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

		private function dispatchChange():void
		{
			_expanded = null;
			_expandedCached = false;
			_node.dispatchEventWith(Event.CHANGE, false, name);
		}
	}
}
