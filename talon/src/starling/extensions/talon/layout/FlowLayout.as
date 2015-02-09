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
			var flow:Flow = measure(node, width, height);
			return getOrientation(node) == Orientation.HORIZONTAL ? flow.getLength() : flow.getThickness();
		}

		public override function measureAutoHeight(node:Node, width:Number, height:Number):Number
		{
			var flow:Flow = measure(node, width, height);
			return getOrientation(node) == Orientation.VERTICAL ? flow.getLength() : flow.getThickness();
		}

		public override function arrange(node:Node, width:Number, height:Number):void
		{
			var orientation:String = getOrientation(node);
			var flow:Flow = measure(node, width, height);

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);
				var childBounds:Rectangle = flow.getChildBounds(i, orientation);
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

			isHorizontal
				? flow.setSize(width, height)
				: flow.setSize(height, width);



			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);

				flow.beginChild();
				// ...
				flow.setChildLength(child.width.amount);
				flow.setChildThickness(child.height.amount);
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
	private var _length:Number;
	private var _lengthPaddingBegin:Number;
	private var _lengthPaddingEnd:Number;
	private var _gap:Number;

	private var _thickness:Number;
	private var _thicknessPaddingBegin:Number;
	private var _thicknessPaddingEnd:Number;
	private var _interline:Number;

	private var _wrap:Boolean;
	private var _halign:int;
	private var _valign:int;

	private var _lines:Vector.<FlowLine>;
	private var _lineByChildIndex:Dictionary;

	private var _childIndex:int;
	private var _childLength:Number;
	private var _childThickness:Number;

	private var _rectangle:Rectangle;

	public function Flow()
	{
		_rectangle = new Rectangle();
		_lines = new <FlowLine>[new FlowLine()];
		_lineByChildIndex = new Dictionary();
		_childIndex = -1;
	}

	// Phase 0
	public function setSize(length:Number, thickness:Number):void
	{
		_length = length;
		_thickness = thickness;
	}

	// Phase 1
	public function beginChild():void
	{
		_childIndex++;
		_childLength = 0;
		_childThickness = 0;
	}

	public function setChildLength(value:Number):void { _childLength = value; }
	public function setChildThickness(value:Number):void { _childThickness = value; }
	public function endChild():void
	{
		var line:FlowLine = _lines[_lines.length-1];
		_lineByChildIndex[_childIndex] = line;

		line.addChild();
		line.addChildLength(0, _childLength, 0);
		line.addChildThickness(0, _childThickness, 0);
	}

	public function complete():void
	{
		var line:FlowLine = _lines[_lines.length-1];
		line.setMaxASideSum(_length);
		line.complete();

		// HAlign
		// VAlign
		// Padding

		// for each (var line:FlowLine in _lines)
		// {
		//      line.delta = 0;
		//      line.shift = 0;
		// }
	}

	// Phase 2
	public function getChildBounds(index:int, orientation:String):Rectangle
	{
		var line:FlowLine = _lineByChildIndex[index];
		var lineChildIndex:int = index - line.firstChildIndex;
		return line.getChildBounds(lineChildIndex, orientation, _rectangle);
	}

	public function getLength():Number
	{
		var result:Number = _length;

		if (result == Infinity)
		{
			result = _lengthPaddingBegin + _lengthPaddingEnd;
			for each (var line:FlowLine in _lines) result = Math.max(result, line.aSize);
		}

		return result;
	}

	public function getThickness():Number
	{
		var result:Number = _thickness;

		if (result == Infinity)
		{
			result = _thicknessPaddingBegin + _thicknessPaddingEnd;
			if (_lines.length > 0) result += (_lines.length - 1) * _interline;
			for each (var line:FlowLine in _lines) result += line.bSize;
		}

		return result;
	}
}

class FlowLine
{
	private var _children:Vector.<FlowElement> = new <FlowElement>[];
	private var _maxBSide:Number = 0;
	private var _maxASideSum:Number = Infinity;
	private var _aSideSum:Number = 0;
	private var _aSideSumStars:Number = 0;

	public function setMaxASideSum(value:Number):void
	{
		_maxASideSum = value;
	}

	public function addChild():void
	{
		_children.push(new FlowElement());
	}

	public function addChildLength(begin:Number, length:Number, end:Number):void
	{
		var element:FlowElement = _children[_children.length - 1];
		element.aBefore = begin;
		element.aSize = length;
		element.aStar = _children.length == 3;
		element.aAfter = end;

		if (!element.aStar) _aSideSum += length;
		else _aSideSumStars += length;
	}

	public function addChildThickness(begin:Number, thickness:Number, end:Number):void
	{
		var element:FlowElement = _children[_children.length - 1];
		element.bBefore = begin;
		element.bSize = thickness;
		element.bAfter = end;

		_maxBSide = Math.max(_maxBSide, thickness);
	}

	public function complete():void
	{
		var loffset:Number = 0;

		for each (var element:FlowElement in _children)
		{
			element.a = loffset;
			element.b = (_maxBSide-element.bSize)*element.bAlignMultiplier;
			element.bsize = element.bSize;

			if (!element.aStar) element.asize = element.aSize;
			else if (_maxASideSum != Infinity) element.asize = (_maxASideSum-_aSideSum)-(element.aSize/_aSideSumStars);
			else element.asize = 0;

			loffset += element.asize;
		}
	}

	public function getChildBounds(index:int, orientation:String, result:Rectangle):Rectangle
	{
		var child:FlowElement = _children[index];

		orientation == Orientation.HORIZONTAL
			? result.setTo(child.a, child.b, child.asize, child.bsize)
			: result.setTo(child.b, child.a, child.bsize, child.asize);

		return result;
	}

	public function get aSize():int { return 0 }
	public function get bSize():int { return 0 }

	public function set aOffset(value:Number):void { }
	public function set bOffset(value:Number):void { }

	public function get firstChildIndex():int { return 0 }
	public function get index():int { return null }

}

class FlowElement
{
	public var aBefore:Number;
	public var aSize:Number;
	public var aStar:Boolean;
	public var aAfter:Number;

	public var bBefore:Number;
	public var bSize:Number;
	public var bStar:Boolean;
	public var bAfter:Number;

	public var bAlignMultiplier:Number = int(Math.random() * 3)/2;

	//

	public var a:Number;
	public var b:Number;
	public var asize:Number;
	public var bsize:Number;
}