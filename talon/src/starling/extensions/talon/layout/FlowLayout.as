package starling.extensions.talon.layout
{
	import flash.geom.Rectangle;
	import starling.extensions.talon.core.Attribute;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.Orientation;

	public class FlowLayout extends Layout
	{
		public override function measureAutoWidth(node:Node, width:Number, height:Number):Number
		{
			return measure(node, width, height).getSize(Orientation.HORIZONTAL);
		}

		public override function measureAutoHeight(node:Node, width:Number, height:Number):Number
		{
			return measure(node, width, height).getSize(Orientation.VERTICAL);
		}

		public override function arrange(node:Node, width:Number, height:Number):void
		{
			var flow:Flow = measure(node, width, height);

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				var childBounds:Rectangle = flow.getChildBounds(i);
				child.bounds.copyFrom(childBounds);
				child.commit();
			}
		}

		//
		// Implementation
		//
		private function measure(node:Node, width:Number, height:Number):Flow
		{
			var orientation:String = getOrientation(node);
			var isHorizontal:Boolean = orientation == Orientation.HORIZONTAL;
			var isVertical:Boolean = orientation == Orientation.VERTICAL;

			var flow:Flow = new Flow();

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);

				flow.beginChild();
				// ...
				flow.setChildLength(100);
				flow.setChildThickness(100);
				// ...
				flow.endChild();
			}

			flow.complete();
			return flow;
		}

		private function getOrientation(node:Node):String { return node.getAttribute(Attribute.ORIENTATION); }
		private function getGap():Number { return 0; }
		private function getInterline():Number { return 0; }
	}
}

import flash.geom.Rectangle;
import flash.utils.Dictionary;

import starling.extensions.talon.utils.Orientation;

class Flow
{
	// Properties
	private var _orientation:Number;
	private var _width:Number;
	private var _height:Number;
	private var _gap:Number;
	private var _interline:Number;
	private var _wrap:Boolean;
	private var _paddingLeft:Number;
	private var _paddingRight:Number;
	private var _paddingTop:Number;
	private var _paddingBottom:Number;
	private var _halign:int;
	private var _valign:int;

	private var _lines:Vector.<FlowLine>;
	private var _lineByChildIndex:Dictionary;

	private var _childIndex:int;
	private var _childWidth:Number;
	private var _childHeight:Number;

	private var _rectangle:Rectangle;

	public function Flow()
	{
		_rectangle = new Rectangle();
		_lines = new <FlowLine>[new FlowLine()];
		_lineByChildIndex = new Dictionary();
		_childIndex = -1;
	}

	// Phase 1
	public function beginChild():void { _childIndex++ }
	public function setChildLength(value:Number):void { _childWidth = value; }
	public function setChildThickness(value:Number):void { _childHeight = value; }

//	public function setChildMarginBefore():void { }
//	public function setChildMarginAfter():void { }
//	public function setChildBreakMode():void { }
//	public function setChildAlign():void { }

	public function endChild():void
	{
		var line:FlowLine = _lines[_lines.length-1];
//		line.
	}

	public function complete():void
	{
		// HAlign
		// VAlign
		// Padding

		for each (var line:FlowLine in _lines)
		{
			line.delta = 0;
			line.shift = 0;
		}
	}

	// Phase 2
	public function getChildBounds(index:int):Rectangle
	{
		_rectangle.setTo(index*100 + 10*index, 10, 100, 50);
		return _rectangle;


//		var line:FlowLine = _lineByChildIndex[index];
//		var lineChildIndex:int = index - line.firstChildIndex;
//		return line.getChildBounds(lineChildIndex, _rectangle);
	}

	public function getSize(orientation:String):Number
	{
		var size:Number = (orientation==Orientation.HORIZONTAL) ? _width : _height;

		if (size == Infinity)
		{
			size = (orientation==Orientation.HORIZONTAL) ? (_paddingLeft+_paddingRight) : (_paddingTop+_paddingBottom);

			var isPrimary:Boolean = _orientation == orientation;

			if (isPrimary === false && _lines.length > 0)
				size += _interline * (_lines.length-1);

			for each (var line:FlowLine in _lines)
				size += isPrimary ? line.length : line.thickness;
		}

		return size;
	}
}

class FlowLine
{
	public function complete():void { }
	public function getChildBounds(index:int, result:Rectangle):Rectangle { return null }
	public function get length():int { return 0 }
	public function get thickness():int { return 0 }

	public function get firstChildIndex():int { return 0 }
	public function get index():int { return null }

	public function set delta(value:Number):void { }
	public function set shift(value:Number):void { }
}