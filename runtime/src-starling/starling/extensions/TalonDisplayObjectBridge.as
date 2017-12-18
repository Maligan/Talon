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
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.filters.FragmentFilter;
	import starling.rendering.Painter;
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

		public function TalonDisplayObjectBridge(target:DisplayObject):void
		{
			Parsers.registerParsers();
			
			_target = target;
			_target.setRequiresRedraw();
			_listeners = new Dictionary();
			_transform = new Matrix();

			_node = new Node();
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
			
			_target.pivotX = _node.pivotX.toPixels(_node.bounds.width);
			_target.pivotY = _node.pivotY.toPixels(_node.bounds.height);

			_target.x = _node.bounds.x + _target.pivotX;
			_target.y = _node.bounds.y + _target.pivotY;
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
			_background.horizontalFillMode = _node.getAttributeCache(Attribute.FILL_MODE_X);
			_background.verticalFillMode = _node.getAttributeCache(Attribute.FILL_MODE_Y);
		}

		private function onFillAlphaChange():void
		{
			_background.alpha = parseFloat(_node.getAttributeCache(Attribute.FILL_ALPHA));
		}

		private function onFillScaleChange():void
		{
			_background.horizontalScale = parseFloat(_node.getAttributeCache(Attribute.FILL_SCALE_X));
			_background.verticalScale = parseFloat(_node.getAttributeCache(Attribute.FILL_SCALE_Y));
		}

		private function onFillBlendModeChange():void
		{
			_background.blendMode = _node.getAttributeCache(Attribute.FILL_BLEND_MODE);
		}

		private function onFillAlignChange():void
		{
			_background.horizontalAlign = _node.getAttributeCache(Attribute.FILL_ALIGN_X);
			_background.verticalAlign = _node.getAttributeCache(Attribute.FILL_ALIGN_Y);
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
			var cursor:String = e.interactsWith(_target)
				? _node.getAttributeCache(Attribute.CURSOR)
				: MouseCursor.AUTO;

			try { Mouse.cursor = cursor }
			catch (e:Error) { trace("[Talon]", "Invalid cursor value:", cursor) }
		}

		private function onTouch_States(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(_target);

			if (touch == null || touch.phase == TouchPhase.ENDED)
			{
				_node.states.put(State.HOVER, false);
				_node.states.put(State.ACTIVE, false);
			}
			else if (touch.phase == TouchPhase.HOVER)
			{
				_node.states.put(State.HOVER, true);
			}
			else if (touch.phase == TouchPhase.BEGAN)
			{
				_node.states.put(State.ACTIVE, true);
			}
			else if (touch.phase == TouchPhase.MOVED)
			{
				var isWithinBounds:Boolean = _target.getBounds(_target.stage).contains(touch.globalX, touch.globalY);

				if (_node.states.has(State.ACTIVE) && !isWithinBounds)
				{
					_node.states.put(State.HOVER, false);
					_node.states.put(State.ACTIVE, false);
				}
				else if (!_node.states.has(State.ACTIVE) && isWithinBounds)
				{
					_node.states.put(State.HOVER, true);
					_node.states.put(State.ACTIVE, true);
				}
			}
		}

		// Public methods which must be used in target DisplayObject
		
		public function renderCustom(render:Function, painter:Painter):void
		{
			validate(false);
			
			pushTransform(painter);
			renderBackground(painter);
			render(painter);
			popTransform(painter);
		}

		private function validate(bubble:Boolean):void
		{
			if (bubble == false && !_node.invalidated) return;
			
			var node:Node;
			
			// Phase 1: Style validation() - may invoke layout invalidation
			node = bubble ? getTopmostInvalidatedAncestor() : null;
			if (node)
				node.validate(false);
			
			// Phase 2: Layout validation()
			node = bubble ? getTopmostInvalidatedAncestor() : (_node.invalidated ? _node : null);
			if (node)
			{
				// In case target doesn't has parent talon display object
				if (node.parent == null)
				{
					// TODO: Respect percentages & min/max size
					// 		 Support stageWidth/stageHeight

					if (node.bounds.width == -1)
						node.bounds.width = node.width.toPixels();

					if (node.bounds.height == -1)
						node.bounds.height = node.height.toPixels();
				}
				
				node.validate(true);
			}
		}
		
		private function getTopmostInvalidatedAncestor():Node
		{
			var base:Node = _node;
			var last:Node = _node.invalidated ? _node : null;

			while (base = base.parent)
				if (base.invalidated)
					last = base;
			
			return last;
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

		public function getBoundsCustom(getBounds:Function, targetSpace:DisplayObject, out:Rectangle):Rectangle
		{
			// Starling call getBounds for invisible DisplayObject
			// But Talon invisible objects are not processed
			if (_target.visible == false)
			{
				out ||= new Rectangle();
				_target.getTransformationMatrix(targetSpace, sMatrix);
				MatrixUtil.transformCoords(sMatrix, 0, 0, sPoint);
				out.setTo(sPoint.x, sPoint.y, 0, 0);
				return out;
			}
			
			validate(true);
			
			if (out == null) out = new Rectangle();
			else out.setEmpty();

			if (getBounds != null)
				out = getBounds(targetSpace, out);

			var isEmpty:Boolean = out.isEmpty();

			// Expand resultRect with background bounds
			_target.getTransformationMatrix(targetSpace, sMatrix);

			var topLeft:Point = MatrixUtil.transformCoords(sMatrix, 0, 0, sPoint);
			if (isEmpty || out.left>topLeft.x) out.left = topLeft.x;
			if (isEmpty || out.top>topLeft.y) out.top = topLeft.y;

			var bottomRight:Point = MatrixUtil.transformCoords(sMatrix, _background.width, _background.height, sPoint);
			if (isEmpty || out.right<bottomRight.x) out.right = bottomRight.x;
			if (isEmpty || out.bottom<bottomRight.y) out.bottom = bottomRight.y;
			
			return out;
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
		
		// Props
		
		public function get node():Node 
		{
			return _node;
		}
	}
}

import flash.geom.Matrix;

import starling.filters.BlurFilter;
import starling.filters.ColorMatrixFilter;
import starling.filters.FilterChain;
import starling.filters.FragmentFilter;
import starling.utils.MatrixUtil;

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
			var float1_0:Number = ParseUtil.parseNumber(split[1], 0);
			var float1_1:Number = ParseUtil.parseNumber(split[1], 1);
			var angle1:Number = ParseUtil.parseAngle(split[1], 0);
	
			if (name == "scale") out.scale(float1_1, ParseUtil.parseNumber(split[2], float1_1));
			else if (name == "scaleX") out.scale(float1_1, 1);
			else if (name == "scaleY") out.scale(1, float1_1);
			else if (name == "rotate") out.rotate(angle1);
			else if (name == "translate") out.translate(float1_0, ParseUtil.parseNumber(split[2], float1_0));
			else if (name == "translateX") out.translate(float1_0, 0);
			else if (name == "translateY") out.translate(0, float1_0);
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
}