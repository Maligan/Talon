package starling.extensions.talon.layout
{
	import flash.geom.Rectangle;
	import starling.extensions.talon.core.Attribute;
	import starling.extensions.talon.core.Gauge;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.Orientation;

	public class FlowLayout extends Layout
	{
		public override function measureAutoWidth(node:Node, width:Number, height:Number):Number
		{
			var flow:Flow = measure(node, width, height);
			var flowWidth:Number = getOrientation(node) == Orientation.HORIZONTAL ? flow.getLength() : flow.getThickness();
			flow.dispose();
			return flowWidth;
		}

		public override function measureAutoHeight(node:Node, width:Number, height:Number):Number
		{
			var flow:Flow = measure(node, width, height);
			var flowHeight:Number = getOrientation(node) == Orientation.VERTICAL ? flow.getLength() : flow.getThickness();
			flow.dispose();
			return flowHeight;
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

			flow.dispose();
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
				? flow.setSize(node.width.isAuto ? Infinity : width, node.height.isAuto ? Infinity : height)
				: flow.setSize(node.height.isAuto ? Infinity : height, node.width.isAuto ? Infinity : width);

			flow.setSpacings(getGap(node), getInterline(node));

			for (var i:int = 0; i < node.numChildren; i++)
			{
				var child:Node = node.getChildAt(i);

				flow.beginChild();
				// ...
				flow.setChildLength(child.width.amount, child.width.unit == Gauge.STAR);
				flow.setChildThickness(child.height.amount);
				flow.setChildInlineAlign(0.5);
				// ...
				flow.endChild();
			}

			flow.complete();
			return flow;
		}

		private function getOrientation(node:Node):String { return node.getAttribute(Attribute.ORIENTATION); }
		private function getGap(node:Node):Number { return Gauge.toPixels(node.getAttribute(Attribute.GAP), node.ppmm, node.ppem, node.pppt, -1, 0, 0, 0, 0); }
		private function getInterline(node:Node):Number { return Gauge.toPixels(node.getAttribute(Attribute.INTERLINE), node.ppmm, node.ppem, node.pppt, -1, 0, 0, 0, 0); }
	}
}

import flash.geom.Rectangle;
import flash.utils.Dictionary;

import starling.extensions.talon.utils.Orientation;

class Flow
{
	// Properties
	private var _length:Number;
	private var _lengthPaddingBegin:Number = 0;
	private var _lengthPaddingEnd:Number = 0;
	private var _gap:Number;

	private var _thickness:Number;
	private var _thicknessPaddingBegin:Number = 0;
	private var _thicknessPaddingEnd:Number = 0;
	private var _interline:Number;

	private var _wrap:Boolean;
	private var _halign:int;
	private var _valign:int;

	private var _lines:Vector.<FlowLine>;
	private var _lineByChildIndex:Dictionary;

	private var _childIndex:int;
	private var _child:FlowElement;

	private var _rectangle:Rectangle;

	public function Flow()
	{
		_rectangle = new Rectangle();
		_lines = new <FlowLine>[];
		_lineByChildIndex = new Dictionary();
		_childIndex = -1;
	}

	// Phase 0
	public function setSize(length:Number, thickness:Number):void
	{
		_length = length;
		_thickness = thickness;
	}

	public function setSpacings(gap:Number, interline:Number):void
	{
		_gap = gap;
		_interline = interline;
	}

	// Phase 1
	public function beginChild():void
	{
		_childIndex++;
		_child = new FlowElement();

		if (_lines.length == 0)
		{
			_lines[_lines.length] = new FlowLine(_length, _gap);
		}
	}

	public function setChildLength(value:Number, isStar:Boolean):void { _child.length = value; _child.lengthIsStar = isStar }
	public function setChildThickness(value:Number):void { _child.thickness = value; }
	public function setChildInlineAlign(value:Number):void { _child.thicknessAlign = value; }

	public function endChild():void
	{
		var line:FlowLine = _lines[_lines.length-1];
		_lineByChildIndex[_childIndex] = line;
		line.addChild(_child);
		_child = null;
	}

	public function complete():void
	{
		if (_lines.length == 0) return;
		var line:FlowLine = _lines[_lines.length-1];
		line.complete(0, 0);

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
		if (_length == Infinity)
		{
			_length = _lengthPaddingBegin + _lengthPaddingEnd;
			for each (var line:FlowLine in _lines) _length = Math.max(_length, line.length);
		}

		return _length;
	}

	public function getThickness():Number
	{
		if (_thickness == Infinity)
		{
			_thickness = _thicknessPaddingBegin + _thicknessPaddingEnd;
			if (_lines.length > 0) _thickness += (_lines.length - 1) * _interline;
			for each (var line:FlowLine in _lines) _thickness += line.thickness;
		}

		return _thickness;
	}

	// Phase 3
	public function dispose():void
	{

	}
}

class FlowLine
{
	private var _children:Vector.<FlowElement>;

	private var _maxLength:Number;
	private var _gap:Number;

	private var _thickness:Number;
	private var _length:Number;
	private var _lengthStar:Number;

	public function FlowLine(maxLength:Number, gap:Number):void
	{
		_maxLength = maxLength;
		_gap = gap;
		_length = 0;
		_lengthStar = 0;
		_thickness = 0;
		_children = new <FlowElement>[];
	}

	public function addChild(child:FlowElement):void
	{
		_children[_children.length] = child;

		if (child.lengthIsStar) _lengthStar += child.length;
		else _length += child.length;
		if (_children.length > 1) _length += _gap;

		_thickness = Math.max(_thickness, child.thickness);
	}

	public function complete(lshift:Number, tshift:Number):void
	{
		var loffset:Number = 0;

		for each (var element:FlowElement in _children)
		{
			element.l = lshift + loffset;
			element.t = tshift + (_thickness-element.thickness)*element.thicknessAlign;
			element.tsize = element.thickness;

			if (!element.lengthIsStar) element.lsize = element.length;
			else if (_maxLength!=Infinity && _maxLength>_length) element.lsize = (_maxLength-_length)*(element.length/_lengthStar);
			else element.lsize = 0;

			loffset += element.lsize + _gap;
		}
	}

	public function getChildBounds(index:int, orientation:String, result:Rectangle):Rectangle
	{
		var child:FlowElement = _children[index];

		orientation == Orientation.HORIZONTAL
			? result.setTo(child.l, child.t, child.lsize, child.tsize)
			: result.setTo(child.t, child.l, child.tsize, child.lsize);

		return result;
	}

	public function get firstChildIndex():int { return 0 }
	public function get length():Number { return _length }
	public function get thickness():Number { return _thickness }

}

class FlowElement
{
	public var lengthBefore:Number;
	public var lengthAfter:Number;
	public var length:Number;
	public var lengthIsStar:Boolean;

	public var thicknessBefore:Number;
	public var thicknessAfter:Number;
	public var thickness:Number;
	public var thicknessIsStar:Boolean;
	public var thicknessAlign:Number;

	//
	public var l:Number;
	public var lsize:Number;
	public var t:Number;
	public var tsize:Number;
}