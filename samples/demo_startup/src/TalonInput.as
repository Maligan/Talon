package
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.StageTextInitOptions;
	import flash.utils.getDefinitionByName;

	import starling.core.Starling;
	import starling.display.Quad;
	import starling.events.Event;

	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.display.ITalonTarget;
	import starling.extensions.talon.utils.parseColor;
	import starling.text.TextFieldAutoSize;

	public class TalonInput extends Quad implements ITalonTarget
	{
		private static var AUTO_CACHE_WIDTH:int = 1000;
		private static var AUTO_CACHE_HEIGHT:int = 1000;

		private static var StageText:Class;
		private static var StageTextInitOptions:Class;

		private static var _helper:*;

		private var _node:Node;
		private var _text:*;

		public function TalonInput()
		{
			if (StageText == null)
			{
				StageText = getDefinitionByName("flash.text::StageText") as Class;
				StageTextInitOptions = getDefinitionByName("flash.text::StageTextInitOptions") as Class;
				_helper = new StageText();
			}

			super(1, 1, 0xFFFFFF);
			visible = false;

			_helper.viewPort = new Rectangle(0, 0, 0, 0);
			_helper.stage = Starling.current.nativeStage;

			_node = new Node();
			_node.width.auto = _node.minWidth.auto = _node.maxWidth.auto = getAutoWidth;
			_node.height.auto = _node.minHeight.auto = _node.maxHeight.auto = getAutoHeight;
			_node.addEventListener(Event.CHANGE, onNodeChange);
			_node.addEventListener(Event.RESIZE, onNodeResize);

			_text = new StageText(new StageTextInitOptions(false));
			_text.addEventListener(Event.CHANGE, onTextChange, false, 0, true);

			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}

		private function getAutoWidth():Number { return getStageTextBounds().width + (2+2) + 2; }
		private function getAutoHeight():Number
		{
			var height:Number = getStageTextBounds().height;
			var lineHeight:Number = _text.fontSize + 2;
			height = Math.ceil(height/lineHeight) * lineHeight;
			return height+(2+2);
		}

		private function getStageTextBounds():Rectangle
		{
			var autoSizeAttribute:String = node.getAttribute("autoSize") || TextFieldAutoSize.BOTH_DIRECTIONS;
			var isHorizontal:Boolean = ((autoSizeAttribute==TextFieldAutoSize.HORIZONTAL)||(autoSizeAttribute==TextFieldAutoSize.BOTH_DIRECTIONS));
			var isVertical:Boolean = ((autoSizeAttribute==TextFieldAutoSize.VERTICAL)||(autoSizeAttribute==TextFieldAutoSize.BOTH_DIRECTIONS));

			var width:Number = node.width.isAuto ? AUTO_CACHE_WIDTH : node.width.toPixels(0, 0, node.pppt, 0, 0, 0, width, height);
			var height:Number = node.height.isAuto ? AUTO_CACHE_HEIGHT : node.height.toPixels(0, 0, node.pppt, 0, 0, 0, width, height);

			var prev:Rectangle = _text.viewPort;
			var draw:Rectangle = new Rectangle(0, 0, width, height);

			_helper.assignFocus();

			// Snapshot
			var bitmap:BitmapData = new BitmapData(draw.width, draw.height, true, 0);
			_text.viewPort = draw;
			_text.drawViewPortToBitmapData(bitmap);
			_text.viewPort = prev;

			_text.assignFocus();

			// Crop transparent
			return bitmap.getColorBoundsRect(0xFF000000, 0x00000000, false);
		}

		private function onNodeChange(e:Event):void
		{
			/**/ if (e.data == "fontColor") _text.color = parseColor(node.getAttribute("fontColor"));
			else if (e.data == "fontName") _text.fontFamily = node.getAttribute("fontName");
			else if (e.data == "fontSize") _text.fontSize = node.ppem;
			else if (e.data == "text") _text.text = node.getAttribute("text");
			else if (e.data == "halign") _text.textAlign = node.getAttribute("halign");
			else if (e.data == "multiline")
			{
				var multiline:Boolean = node.getAttribute("multiline") == "true";
				if (multiline)
				{
					var options:* = new StageTextInitOptions(multiline);
					// TODO: Copy properties
					_text.dispose();
					_text = new StageText(options);
					_text.stage = stage ? Starling.current.nativeStage : null;
					_text.addEventListener(Event.CHANGE, onTextChange, false, 0, true);
					onNodeResize(null);
				}
			}
			else if (e.data == "backgroundColor")
			{
				var backgroundColor:String = node.getAttribute("backgroundColor");
				var backgroundColorHex:int = parseColor(node.getAttribute("backgroundColor"));
				visible = backgroundColor != "transparent";
				visible && (color = backgroundColorHex);
			}

			_text.editable = true;
		}

		private function onNodeResize(e:Event):void
		{
			var bounds:Rectangle = node.bounds.clone();
			bounds.left = Math.round(node.bounds.left);
			bounds.right = Math.round(node.bounds.right);
			bounds.top = Math.round(node.bounds.top);
			bounds.bottom = Math.round(node.bounds.bottom);

			// Quad Position
			x = Math.round(node.bounds.x);
			y =  Math.round(node.bounds.y);

			// Quad Size (view vertexData for avoid change scale)
			mVertexData.setPosition(0, 0.0, 0.0);
			mVertexData.setPosition(1, bounds.width, 0.0);
			mVertexData.setPosition(2, 0.0, bounds.height);
			mVertexData.setPosition(3, bounds.width, bounds.height);

			// StageText viewport
			var pivot:Point = bounds.topLeft.clone();
			var viewPortPivot:Point = localToGlobal(pivot);
			viewPortPivot.x = Math.round(viewPortPivot.x);
			viewPortPivot.y = Math.round(viewPortPivot.y);
			var viewPort:Rectangle = new Rectangle(viewPortPivot.x - bounds.x, viewPortPivot.y - bounds.y, bounds.width, bounds.height);
			_text.viewPort = viewPort;
		}

		private function onTextChange(e:*):void
		{
			dispatchEventWith("invalidate", true);
		}

		private function onAddedToStage(e:*):void
		{
			_text.stage = Starling.current.nativeStage;
		}

		private function onRemovedFromStage(e:*):void
		{
			_text.stage = null;
		}

		public function get node():Node
		{
			return _node;
		}

		public override function dispose():void
		{
			_text.dispose();
			super.dispose();
		}
	}
}