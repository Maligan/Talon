package starling.extensions
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Mesh;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.filters.FragmentFilter;
	import starling.rendering.Painter;
	import starling.styles.MeshStyle;
	import starling.textures.Texture;
	import starling.utils.Color;
	import starling.utils.MatrixUtil;

	import talon.Attribute;
	import talon.Node;
	import talon.enums.TouchMode;
	import talon.utils.Gauge;
	import talon.utils.ParseUtil;

	/** Provide method for synchronize starling display tree and talon tree. */
	public class TalonDisplayObjectBridge
	{
		ParseUtil.addParser(Matrix, function(value:String, node:Node, out:Matrix):Matrix
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

				/**/ if (name == "scale") out.scale(float1, float1);
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
		});

		private const sMatrix:Matrix = new Matrix();
		private const sPoint:Point = new Point();

		private var _target:DisplayObject;
		private var _node:Node;
		private var _background:FillModeMesh;
		private var _transform:Matrix;
		private var _transformChanged:Boolean;

		public function TalonDisplayObjectBridge(target:DisplayObject, node:Node):void
		{
			_target = target;
			_target.addEventListener(EnterFrameEvent.ENTER_FRAME, validate);

			_transform = new Matrix();

			_node = node;
			_node.addTriggerListener(Event.RESIZE, onNodeResize);

			_background = new FillModeMesh();
			_background.pixelSnapping = true;
			_background.addEventListener(Event.CHANGE, _target.setRequiresRedraw);

			// Background
			addAttributeChangeListener(Attribute.FILL,           			onFillChange);
			addAttributeChangeListener(Attribute.FILL_MODE,      			onFillModeChange);
			addAttributeChangeListener(Attribute.FILL_STRETCH_GRID,   		onFillStretchGridChange);
			addAttributeChangeListener(Attribute.FILL_ALPHA,          		onFillAlphaChange);
			addAttributeChangeListener(Attribute.FILL_SCALE,          		onFillScaleChange);
			addAttributeChangeListener(Attribute.FILL_BLEND_MODE,			onFillBlendModeChange);
			addAttributeChangeListener(Attribute.FILL_ALIGN,				onFillAlignChange);

			// Common options
			addAttributeChangeListener(Attribute.ID,                        onIDChange);
			addAttributeChangeListener(Attribute.VISIBLE,                   onVisibleChange);
			addAttributeChangeListener(Attribute.FILTER,                    onFilterChange);
			addAttributeChangeListener(Attribute.ALPHA,                     onAlphaChange);
			addAttributeChangeListener(Attribute.BLEND_MODE,                onBlendModeChange);
			addAttributeChangeListener(Attribute.TRANSFORM,					onTransformChange);
			addAttributeChangeListener(Attribute.MESH_STYLE,				onMeshStyleChange);
			addAttributeChangeListener(Attribute.PIVOT,                     onPivotChange);

			// Interactive
			addAttributeChangeListener(Attribute.TOUCH_MODE,                onTouchModeChange);
			addAttributeChangeListener(Attribute.TOUCH_EVENTS,              onTouchEventsChange);
			addAttributeChangeListener(Attribute.CURSOR,                    onCursorChange);
		}

		public function addAttributeChangeListener(attribute:String, listener:Function, immediate:Boolean = false):void
		{
			_node.getOrCreateAttribute(attribute).change.addListener(listener);
			if (immediate) listener(); // Attribute doesn't passed - it is not created yet now
		}

		private function onNodeResize():void
		{
			_background.width = _node.bounds.width;
			_background.height = _node.bounds.height;
		}

		//
		// Invalidation
		//
		// Validation subsystem based on render methods/rules/context etc.
		// thus why I do not include invalidation/validation in Talon core
		//

		public function validate():void
		{
			if (_node.invalidated && (_node.parent == null || !_node.parent.invalidated))
			{
				// isNaN() check for element bounds
				// This may be if current element is topmost in talon hierarchy
				// and there is no user setups of its sizes

				// TODO: Respect percentages & min/max size

				if (_node.bounds.width != _node.bounds.width)
					_node.bounds.width = _node.width.toPixels(_node, 0);

				if (_node.bounds.height != _node.bounds.height)
					_node.bounds.height = _node.height.toPixels(_node, 0);

				_node.commit();
			}
		}

		// Listeners: Background

		private function onFillChange():void
		{
			var value:* = _node.getAttributeCache(Attribute.FILL);
			if (value is Texture)
			{
				_background.texture = value;
				_background.color = Color.WHITE;
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
				Gauge.toPixels(_node.getAttributeCache(Attribute.FILL_STRETCH_GRID_TOP), _node, textureHeight),
				Gauge.toPixels(_node.getAttributeCache(Attribute.FILL_STRETCH_GRID_RIGHT), _node, textureWidth),
				Gauge.toPixels(_node.getAttributeCache(Attribute.FILL_STRETCH_GRID_BOTTOM), _node, textureHeight),
				Gauge.toPixels(_node.getAttributeCache(Attribute.FILL_STRETCH_GRID_LEFT), _node, textureWidth)
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
			if (_target is Mesh)
			{
				var mesh:Mesh = _target as Mesh;
				mesh.style = ParseUtil.parseClass(MeshStyle,
					_node.getAttributeCache(Attribute.MESH_STYLE),
					_node,
					mesh.style
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

			_node.states.lock();

			if (touch == null)
			{
				_node.states.remove("hover");
				_node.states.remove("active");
			}
			else if (touch.phase == TouchPhase.HOVER)
			{
				_node.states.insert("hover");
			}
			else if (touch.phase == TouchPhase.BEGAN && !_node.states.contains("active"))
			{
				_node.states.insert("active");
			}
			else if (touch.phase == TouchPhase.MOVED)
			{
				var isWithinBounds:Boolean = _target.getBounds(_target.stage).contains(touch.globalX, touch.globalY);

				if (_node.states.contains("active") && !isWithinBounds)
				{
					_node.states.remove("hover");
					_node.states.remove("active");
				}
				else if (!_node.states.contains("active") && isWithinBounds)
				{
					_node.states.insert("hover");
					_node.states.insert("active");
				}
			}
			else if (touch.phase == TouchPhase.ENDED)
			{
				_node.states.remove("hover");
				_node.states.remove("active");
			}

			_node.states.unlock();
		}

		// Public methods which must be used in target DisplayObject

		public function renderCustom(render:Function, painter:Painter):void
		{
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
