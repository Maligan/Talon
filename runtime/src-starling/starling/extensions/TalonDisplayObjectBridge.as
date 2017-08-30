package starling.extensions
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.Dictionary;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Mesh;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.filters.FragmentFilter;
	import starling.rendering.Painter;
	import starling.styles.MeshStyle;
	import starling.text.TextField;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.MatrixUtil;

	import talon.core.Attribute;
	import talon.core.Node;
	import talon.enums.State;
	import talon.enums.TouchMode;
	import talon.utils.Gauge;
	import talon.utils.ParseUtil;

	/** @private Provide method for synchronize starling display tree and talon tree. */
	public class TalonDisplayObjectBridge
	{
		private const sMatrix:Matrix = new Matrix();
		private const sPoint:Point = new Point();

		private var _target:DisplayObject;
		private var _node:Node;
		private var _background:FillModeMesh;
		private var _transform:Matrix;
		private var _transformChanged:Boolean;
		private var _listeners:Dictionary;

		public function TalonDisplayObjectBridge(target:DisplayObject, node:Node):void
		{
			Parsers.registerParsers();
			
			_target = target;
			_target.setRequiresRedraw();
			_listeners = new Dictionary();

			_transform = new Matrix();

			_node = node;
			_node.addListener(Event.RESIZE, onNodeResize);
			_node.addListener(Event.CHANGE, onNodeChange);
			_node.addListener(Event.UPDATE, _target.setRequiresRedraw);

			_background = new FillModeMesh();
			_background.pixelSnapping = true;
			_background.addEventListener(Event.CHANGE, _target.setRequiresRedraw);

			// Background
			setAttributeChangeListener(Attribute.FILL,           			onFillChange);
			setAttributeChangeListener(Attribute.FILL_MODE,      			onFillModeChange);
			setAttributeChangeListener(Attribute.FILL_STRETCH_GRID,   		onFillStretchGridChange);
			setAttributeChangeListener(Attribute.FILL_ALPHA,          		onFillAlphaChange);
			setAttributeChangeListener(Attribute.FILL_SCALE,          		onFillScaleChange);
			setAttributeChangeListener(Attribute.FILL_BLEND_MODE,			onFillBlendModeChange);
			setAttributeChangeListener(Attribute.FILL_ALIGN,				onFillAlignChange);
			setAttributeChangeListener(Attribute.FILL_TINT,					onFillChange);

			// Common options
			setAttributeChangeListener(Attribute.ID,                        onIDChange);
			setAttributeChangeListener(Attribute.VISIBLE,                   onVisibleChange);
			setAttributeChangeListener(Attribute.FILTER,                    onFilterChange);
			setAttributeChangeListener(Attribute.ALPHA,                     onAlphaChange);
			setAttributeChangeListener(Attribute.BLEND_MODE,                onBlendModeChange);
			setAttributeChangeListener(Attribute.TRANSFORM,					onTransformChange);
			setAttributeChangeListener(Attribute.MESH_STYLE,				onMeshStyleChange);
			setAttributeChangeListener(Attribute.PIVOT,                     onPivotChange);

			// Interactive
			setAttributeChangeListener(Attribute.TOUCH_MODE,                onTouchModeChange);
			setAttributeChangeListener(Attribute.TOUCH_EVENTS,              onTouchEventsChange);
			setAttributeChangeListener(Attribute.CURSOR,                    onCursorChange);
		}

		public function setAttributeChangeListener(attribute:String, listener:Function, immediate:Boolean = false):void
		{
			_listeners[attribute] = listener;
			if (immediate) listener();
		}

		private function onNodeChange(attribute:Attribute):void
		{
			var listener:Function = _listeners[attribute.name];
			if (listener)
				listener();
		}

		private function onNodeResize():void
		{
			_background.width = _node.bounds.width;
			_background.height = _node.bounds.height;
		}
		
		//
		// Validation
		//
		// Validation subsystem based on render methods/rules/context etc.
		// thus why I do not include invalidation/validation in Talon core
		//

		public function validate():void
		{
			if (_node.parent == null)
			{
				// TODO: Respect percentages & min/max size

				// isNaN() check for element bounds
				// This may be if current element is topmost in talon hierarchy
				// and there is no user setup for its sizes
				
				if (_node.bounds.width != _node.bounds.width)
					_node.bounds.width = _node.width.toPixels(_node.metrics, 0);

				if (_node.bounds.height != _node.bounds.height)
					_node.bounds.height = _node.height.toPixels(_node.metrics, 0);
			}

			_node.validate();
		}

		// Listeners: Background

		private function onFillChange():void
		{
			var value:* = _node.getAttributeCache(Attribute.FILL);
			if (value is Texture)
			{
				_background.texture = value;
				_background.color = ParseUtil.parseColor(_node.getAttributeCache(Attribute.FILL_TINT));
				_background.transparent = false;
			}
			else
			{
				_background.texture = null;
				_background.color = ParseUtil.parseColor(value, Color.WHITE);
				_background.transparent = value == Attribute.NONE;
			}
		}

		private function onFillModeChange():void
		{
			_background.horizontalFillMode = _node.getAttributeCache(Attribute.FILL_MODE_HORIZONTAL);
			_background.verticalFillMode = _node.getAttributeCache(Attribute.FILL_MODE_VERTICAL);
		}

		private function onFillAlphaChange():void
		{
			_background.alpha = parseFloat(_node.getAttributeCache(Attribute.FILL_ALPHA));
		}

		private function onFillScaleChange():void
		{
			_background.horizontalScale = parseFloat(_node.getAttributeCache(Attribute.FILL_SCALE_HORIZONTAL));
			_background.verticalScale = parseFloat(_node.getAttributeCache(Attribute.FILL_SCALE_VERTICAL));
		}

		private function onFillBlendModeChange():void
		{
			_background.blendMode = _node.getAttributeCache(Attribute.FILL_BLEND_MODE);
		}

		private function onFillAlignChange():void
		{
			_background.horizontalAlign = _node.getAttributeCache(Attribute.FILL_ALIGN_HORIZONTAL);
			_background.verticalAlign = _node.getAttributeCache(Attribute.FILL_ALIGN_VERTICAAL);
		}
		
		private function onFillStretchGridChange():void
		{
			var textureWidth:int = _background.texture ? _background.texture.width : 0;
			var textureHeight:int = _background.texture ? _background.texture.height : 0;

			_background.setStretchOffsets
			(
				Gauge.toPixels(_node.getAttributeCache(Attribute.FILL_STRETCH_GRID_TOP), _node.metrics, textureHeight),
				Gauge.toPixels(_node.getAttributeCache(Attribute.FILL_STRETCH_GRID_RIGHT), _node.metrics, textureWidth),
				Gauge.toPixels(_node.getAttributeCache(Attribute.FILL_STRETCH_GRID_BOTTOM), _node.metrics, textureHeight),
				Gauge.toPixels(_node.getAttributeCache(Attribute.FILL_STRETCH_GRID_LEFT), _node.metrics, textureWidth)
			);
		}

		// Listeners: Common

		private function onIDChange():void
		{
			_target.name = _node.getAttributeCache(Attribute.ID);
		}

		private function onVisibleChange():void
		{
			_target.visible = ParseUtil.parseBoolean(_node.getAttributeCache(Attribute.VISIBLE));
		}

		private function onAlphaChange():void
		{
			_target.alpha = parseFloat(_node.getAttributeCache(Attribute.ALPHA));
		}

		private function onBlendModeChange():void
		{
			_target.blendMode = _node.getAttributeCache(Attribute.BLEND_MODE);
		}

		private function onFilterChange():void
		{
			_target.filter = ParseUtil.parseClass(FragmentFilter,
				_node.getAttributeCache(Attribute.FILTER),
				_node,
				_target.filter
			);
		}

		private function onMeshStyleChange():void
		{
			if (_target is Mesh || _target is TextField)
			{
				_target["style"] = ParseUtil.parseClass(MeshStyle,
					_node.getAttributeCache(Attribute.MESH_STYLE),
					_node,
					_target["style"]
				);
			}
		}

		private function onTransformChange():void
		{
			_transform = ParseUtil.parseClass(Matrix, _node.getAttributeCache(Attribute.TRANSFORM), _node, _transform);
			_transformChanged = true;
			_target.setRequiresRedraw();
		}

		private function onPivotChange():void
		{
			_transformChanged = true;
		}

		// Listeners: Interaction

		private function onCursorChange():void
		{
			var cursor:String = _node.getAttributeCache(Attribute.CURSOR);
			if (cursor == MouseCursor.AUTO) _target.removeEventListener(TouchEvent.TOUCH, onTouch_Cursor);
			else _target.addEventListener(TouchEvent.TOUCH, onTouch_Cursor);
		}

		private function onTouchModeChange():void
		{
			var mode:String = _node.getAttributeCache(Attribute.TOUCH_MODE);

			_target.touchable = mode != TouchMode.NONE;

			var targetAsContainer:DisplayObjectContainer = _target as DisplayObjectContainer;
			if (targetAsContainer)
				targetAsContainer.touchGroup = mode != TouchMode.BRANCH;
		}

		private function onTouchEventsChange():void
		{
			var touchEventsValue:String = _node.getAttributeCache(Attribute.TOUCH_EVENTS);
			var touchEvents:Boolean = ParseUtil.parseBoolean(touchEventsValue);

			if (touchEvents) _target.addEventListener(TouchEvent.TOUCH, onTouch_States);
			else _target.removeEventListener(TouchEvent.TOUCH, onTouch_States);
		}

		private function onTouch_Cursor(e:TouchEvent):void
		{
			Mouse.cursor = e.interactsWith(_target)
				? _node.getAttributeCache(Attribute.CURSOR)
				: MouseCursor.AUTO;
		}

		private function onTouch_States(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(_target);

			if (touch == null || touch.phase == TouchPhase.ENDED)
			{
				_node.states.set(State.HOVER, false);
				_node.states.set(State.ACTIVE, false);
			}
			else if (touch.phase == TouchPhase.HOVER)
			{
				_node.states.set(State.HOVER, true);
			}
			else if (touch.phase == TouchPhase.BEGAN)
			{
				_node.states.set(State.ACTIVE, true);
			}
			else if (touch.phase == TouchPhase.MOVED)
			{
				var isWithinBounds:Boolean = _target.getBounds(_target.stage).contains(touch.globalX, touch.globalY);

				if (_node.states.has(State.ACTIVE) && !isWithinBounds)
				{
					_node.states.set(State.HOVER, false);
					_node.states.set(State.ACTIVE, false);
				}
				else if (!_node.states.has(State.ACTIVE) && isWithinBounds)
				{
					_node.states.set(State.HOVER, true);
					_node.states.set(State.ACTIVE, true);
				}
			}
		}

		// Public methods which must be used in target DisplayObject

		public function renderCustom(render:Function, painter:Painter):void
		{
			validate();
			
			pushTransform(painter);
			renderBackground(painter);
			render(painter);
			popTransform(painter);
		}

		private function renderBackground(painter:Painter):void
		{
			if (hasOpaqueBackground)
			{
				painter.pushState();
				painter.setStateTo(_background.transformationMatrix, _background.alpha, _background.blendMode);
				_background.render(painter);
				painter.popState();
			}
		}

		private function pushTransform(painter:Painter):void
		{
			if (hasTransform)
			{
				if (_transformChanged)
				{
					_transformChanged = false;

					if (_target.pivotX != 0.0 || _target.pivotY != 0.0)
					{
						_transform.tx += _target.pivotX - _transform.a*_target.pivotX - _transform.c*_target.pivotY;
						_transform.ty += _target.pivotY - _transform.b*_target.pivotX - _transform.d*_target.pivotY;
					}
				}

				painter.pushState();
				painter.state.transformModelviewMatrix(_transform);
			}
		}

		private function popTransform(painter:Painter):void
		{
			if (hasTransform)
				painter.popState();
		}

		public function getBoundsCustom(getBounds:Function, targetSpace:DisplayObject, resultRect:Rectangle):Rectangle
		{
			if (resultRect == null) resultRect = new Rectangle();
			else resultRect.setEmpty();

			if (getBounds != null)
				resultRect = getBounds(targetSpace, resultRect);

			var isEmpty:Boolean = resultRect.isEmpty();

			// Expand resultRect with background bounds
			_target.getTransformationMatrix(targetSpace, sMatrix);

			var topLeft:Point = MatrixUtil.transformCoords(sMatrix, 0, 0, sPoint);
			if (isEmpty || resultRect.left>topLeft.x) resultRect.left = topLeft.x;
			if (isEmpty || resultRect.top>topLeft.y) resultRect.top = topLeft.y;

			var bottomRight:Point = MatrixUtil.transformCoords(sMatrix, _node.bounds.width, _node.bounds.height, sPoint);
			if (isEmpty || resultRect.right<bottomRight.x) resultRect.right = bottomRight.x;
			if (isEmpty || resultRect.bottom<bottomRight.y) resultRect.bottom = bottomRight.y;

			return resultRect;
		}

		public function dispose():void
		{
			_node.dispose();
			_background.dispose();
		}

		// Flags

		public function get hasOpaqueBackground():Boolean
		{
			return _background.texture || !_background.transparent;
		}

		public function get hasTransform():Boolean
		{
			return _transform.a != 1.0
				|| _transform.b != 0.0
				|| _transform.c != 0.0
				|| _transform.d != 1.0
				|| _transform.tx != 0.0
				|| _transform.ty != 0.0;
		}
	}
}

import flash.geom.Matrix;

import starling.filters.BlurFilter;
import starling.filters.ColorMatrixFilter;
import starling.filters.FilterChain;
import starling.filters.FragmentFilter;
import starling.styles.DistanceFieldStyle;
import starling.styles.MeshStyle;
import starling.utils.MatrixUtil;

import talon.core.Attribute;
import talon.core.Node;
import talon.utils.ParseUtil;

class Parsers
{
	private static var _init:Boolean = false;
	
	public static function registerParsers():void
	{
		if (_init == false)
		{
			_init = true;
			ParseUtil.registerClassParser(Matrix, Parsers.parseMatrix);
			ParseUtil.registerClassParser(FragmentFilter, Parsers.parseFragmentFilter);
			ParseUtil.registerClassParser(MeshStyle, Parsers.parseMeshStyle);
		}
	}
	
	private static function parseMatrix(value:String, node:Node, out:Matrix):Matrix
	{
		out ||= new Matrix();
		out.identity();
	
		var funcs:Array = value.split(/\s+(?=scale|rotate|skew|translate|matrix)/g);
		for each (var func:String in funcs)
		{
			var split:Array = ParseUtil.parseFunction(func);
			if (split == null || split.length < 2) continue;
	
			var name:String = split[0];
			var float1:Number = parseFloat(split[1]);
			var angle1:Number = ParseUtil.parseAngle(split[1], 0);
	
			if (name == "scale") out.scale(float1, float1);
			else if (name == "scaleX") out.scale(float1, 1);
			else if (name == "scaleY") out.scale(1, float1);
			else if (name == "rotate") out.rotate(angle1);
			else if (name == "translate") out.translate(float1, float1);
			else if (name == "translateX") out.translate(float1, 0);
			else if (name == "translateY") out.translate(0, float1);
			else if (name == "skewX") MatrixUtil.skew(out, angle1, 0);
			else if (name == "skewY") MatrixUtil.skew(out, 0, angle1);
			else if (name == "matrix")
			{
				if (split.length < 7) continue;
				split.shift();
				out.setTo.apply(null, split);
			}
		}
	
		return out;
	}

	private static function parseFragmentFilter(value:String, node:Node, out:FragmentFilter):FragmentFilter
	{
		// TODO: Extract from outChain blur/colormatrix
		var outChain:FilterChain = out as FilterChain;
		var outBlur:BlurFilter = out as BlurFilter;
		if (outBlur) outBlur.blurX = outBlur.blurY = 0;
		var outColorMatrix:ColorMatrixFilter = out as ColorMatrixFilter;
		if (outColorMatrix) outColorMatrix.reset();
	
		var filters:Array = value.split(/\s+(?=none|blur|saturate|brightness|contrast|hue|tint)/g);
		if (filters.length == 1 && filters[0] == "none")
		{
			out && out.dispose();
			out = null;
		}
	
		for each (var filter:String in filters)
		{
			var args:Array = ParseUtil.parseFunction(filter);
			if (args == null || args.length == 0) continue;
	
			var float1:Number = parseFloat(args[1]) || 0;
			var angle1:Number = ParseUtil.parseAngle(args[1], 0);
			var color1:uint = ParseUtil.parseColor(args[1]);
	
			switch (args[0])
			{
				case "saturate":
				case "brightness":
				case "contrast":
				case "hue":
				case "tint":
					outColorMatrix ||= new ColorMatrixFilter();
					/**/ if (args[0] == "saturate")   outColorMatrix.adjustSaturation(float1);
					else if (args[0] == "brightness") outColorMatrix.adjustBrightness(float1);
					else if (args[0] == "contrast")   outColorMatrix.adjustContrast(float1);
					else if (args[0] == "hue")        outColorMatrix.adjustHue(angle1);
					else if (args[0] == "tint")       outColorMatrix.tint(color1, ParseUtil.parseNumber(args[2], 1));
					break;
	
				case "blur":
					outBlur ||= new BlurFilter();
					outBlur.blurX = float1;
					outBlur.blurY = ParseUtil.parseNumber(args[2], float1);
					break;
			}
		}
	
		if (outColorMatrix && outBlur)
		{
			out = outChain = new FilterChain();
			outChain.addFilter(outColorMatrix);
			outChain.addFilter(outBlur);
		}
		else if (outColorMatrix)
			out = outColorMatrix;
		else if (outBlur)
			out = outBlur;
	
		return out;
	}

	private static function parseMeshStyle(value:String, node:Node, out:MeshStyle):MeshStyle
	{
		var split:Array = ParseUtil.parseFunction(value);
		if (split == null || split[0] == Attribute.NONE)
			return null;
	
		var dfs:DistanceFieldStyle = out as DistanceFieldStyle;
		if (dfs == null)
			dfs = new DistanceFieldStyle();
	
		dfs.softness  = ParseUtil.parseNumber(split[1], 0.125);
		dfs.threshold = ParseUtil.parseNumber(split[2], 0.5);
	
		switch (split[0])
		{
			case "dfs":
				dfs.setupBasic();
				break;
			case "dfs-glow":
				dfs.setupGlow(
					ParseUtil.parseNumber(split[3], 0.2),
					ParseUtil.parseColor(split[4], 0x0),
					ParseUtil.parseNumber(split[5], 0.5)
				);
				break;
			case "dfs-shadow":
				dfs.setupDropShadow(
					ParseUtil.parseNumber(split[3], 0.2),
					ParseUtil.parseNumber(split[4], 2),
					ParseUtil.parseNumber(split[5], 2),
					ParseUtil.parseColor(split[6], 0x0),
					ParseUtil.parseNumber(split[7], 0.5)
				);
				break;
			case "dfs-outline":
				dfs.setupOutline(
					ParseUtil.parseNumber(split[3], 0.25),
					ParseUtil.parseColor(split[4], 0x0),
					ParseUtil.parseNumber(split[5], 1)
				);
				break;
			default:
				return null;
		}
	
		return dfs;
	}
}