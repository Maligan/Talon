package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Attribute;
	import starling.extensions.talon.core.Gauge;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.Orientation;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	public class FlowLayout_OLD extends Layout
	{
		private static const TRUE:String = "true";

		private static const _gaugeHelper:Gauge = new Gauge();

		private static function toPixels(attribute:String, node:Node, target:Number):Number
		{
			var source:String = node.getAttribute(attribute);
			_gaugeHelper.parse(source);
			return _gaugeHelper.toPixels(node.ppmm, node.ppem, node.pppt, target, 0, 0, 0, 0);
		}

		public override function arrange(node:Node, width:Number, height:Number):void
		{
			// Optimization
			if (node.numChildren == 0) return;

			var orientation:String = node.getAttribute(Attribute.ORIENTATION);
			if (Orientation.isValid(orientation) === false) throw new Error("Attribute orientation has invalid origin: " + orientation);

			var paddingLeft:Number = node.padding.left.toPixels(node.ppmm, node.ppem, node.pppt, width, width, height, 0, 0);
			var paddingTop:Number = node.padding.top.toPixels(node.ppmm, node.ppem, node.pppt, height, width, height, 0, 0);

			width -= paddingLeft + node.padding.right.toPixels(node.ppmm, node.ppem, node.pppt, width, width, height, 0, 0);
			height -= paddingTop + node.padding.bottom.toPixels(node.ppmm, node.ppem, node.pppt, height, width, height, 0, 0);

			var gap:Number = toPixels(Attribute.GAP, node, (orientation == Orientation.HORIZONTAL? width : height));
			var interline:Number = toPixels(Attribute.INTERLINE, node, (orientation == Orientation.HORIZONTAL ? width : height));

			var lines:Vector.<Line> = measure(node, width, height);
			var totalLength:Number = orientation==Orientation.HORIZONTAL?width:height;
			var totalThickness:Number = orientation==Orientation.HORIZONTAL?height:width;

			var lengthAlign:Number = 0;
			var thicknessAlign:Number = 0;
			var valign:String = node.getAttribute(Attribute.VALIGN);
			var halign:String = node.getAttribute(Attribute.HALIGN);

			if (orientation == Orientation.HORIZONTAL)
			{
				/**/ if (halign==HAlign.CENTER) lengthAlign = 0.5;
				else if (halign==HAlign.LEFT) lengthAlign = 0;
				else if (halign==HAlign.RIGHT) lengthAlign = 1;

				/**/ if (valign==VAlign.CENTER) thicknessAlign = 0.5;
				else if (valign==VAlign.TOP) thicknessAlign = 0;
				else if (valign==VAlign.BOTTOM) thicknessAlign = 1;
			}
			else
			{
				/**/ if (halign==HAlign.CENTER) thicknessAlign = 0.5;
				else if (halign==HAlign.LEFT) thicknessAlign = 0;
				else if (halign==HAlign.RIGHT) thicknessAlign = 1;

				/**/ if (valign==VAlign.CENTER) lengthAlign = 0.5;
				else if (valign==VAlign.TOP) lengthAlign = 0;
				else if (valign==VAlign.BOTTOM) lengthAlign = 1;
			}

			var sumThickness:Number = 0;
			for each (var line1:Line in lines)
			{
				if (line1 != lines[0]) sumThickness += interline;
				sumThickness += line1.thickness;
			}

			var offsetGap:Number = 0;
			var offsetInterline:Number = 0;

			for each (var line:Line in lines)
			{
				var deltaLength:Number = (totalLength - line.length)*lengthAlign;
				var deltaThickness:Number = (totalThickness - sumThickness)*thicknessAlign;

				offsetGap = 0;

				for (var i:int = line.firstChildIndex; i <= line.lastChildIndex; i++)
				{
					var child:Node = node.getChildAt(i);
					var childIndex:int = line.lastChildIndex - line.firstChildIndex;

					if (orientation == Orientation.HORIZONTAL)
					{
						child.bounds.width = line.childrenLength[childIndex];
						child.bounds.height = line.childrenThickness[childIndex];
						child.bounds.x = line.childrenOffset[childIndex];
						child.bounds.y = offsetInterline + child.margin.top.toPixels(node.ppmm, node.ppem, node.pppt, height, width, height, 0, 0);

						child.bounds.x += deltaLength;
						child.bounds.y += deltaThickness;
					}
					else
					{
						child.bounds.width = getSize(child.width, child.minWidth, child.maxWidth, child.ppmm, child.ppem, child.pppt, width, 0, 0, line.thickness, 1);
						child.bounds.height = getSize(child.height, child.minHeight, child.maxHeight, child.ppmm, node.ppem, child.pppt, height, 0, 0, line.starLength, line.starAmount);
						offsetGap += child.margin.top.toPixels(node.ppmm, node.ppem, node.pppt, width, width, height, 0, 0);
						child.bounds.y = offsetGap;
						offsetGap += child.bounds.height;
						offsetGap += child.margin.bottom.toPixels(node.ppmm, node.ppem, node.pppt, width, width, height, 0, 0);
						offsetGap += gap;
						child.bounds.x = offsetInterline + child.margin.left.toPixels(node.ppmm, node.ppem, node.pppt, width, width, height, 0, 0);

						child.bounds.x += deltaThickness;
						child.bounds.y += deltaLength;
					}

					child.bounds.x += paddingLeft;
					child.bounds.y += paddingTop;
					child.commit();
				}

				offsetInterline += line.thickness + interline;
			}
		}

		public override function measureAutoWidth(node:Node, width:Number, height:Number):Number
		{
			return measureSide(node, Orientation.HORIZONTAL, width, height)
				+ node.padding.left.toPixels(node.ppmm, node.ppem, node.pppt, width, width, height, 0, 0)
				+ node.padding.right.toPixels(node.ppmm, node.ppem, node.pppt, width, width, height, 0, 0)
		}

		public override function measureAutoHeight(node:Node, width:Number, height:Number):Number
		{
			return measureSide(node, Orientation.VERTICAL, width, height)
				+ node.padding.top.toPixels(node.ppmm, node.ppem, node.pppt, height, width, height, 0, 0)
				+ node.padding.bottom.toPixels(node.ppmm, node.ppem, node.pppt, height, width, height, 0, 0);
		}

		private function measureSide(node:Node, side:String, width:Number, height:Number):Number
		{
			var orientation:String = node.getAttribute(Attribute.ORIENTATION);
			if (Orientation.isValid(orientation) === false) throw new Error("Attribute orientation has invalid origin: " + orientation);
			return getMeasureSize(measure(node, width, height), orientation == side, toPixels(Attribute.INTERLINE, node, orientation==Orientation.HORIZONTAL?height:width));
		}

		private function getMeasureSize(lines:Vector.<Line>, primary:Boolean, interline:Number):Number
		{
			var line:Line = null;
			var length:Number = 0;

			if (primary)
			{
				for each (line in lines) length = Math.max(length, line.length);
			}
			else
			{
				for each (line in lines) length = length + line.thickness;
				length += (lines.length>1) ? (lines.length-1)*interline : 0;
			}

			return length;
		}

		private function measure(node:Node, width:Number, height:Number):Vector.<Line>
		{
			var result:Vector.<Line> = new Vector.<Line>();
			var line:Line;

			var orientation:String = node.getAttribute(Attribute.ORIENTATION);
			var isHorizontal:Boolean = orientation == Orientation.HORIZONTAL;
			var isVertical:Boolean = orientation == Orientation.VERTICAL;

			var wrap:Boolean = node.getAttribute(Attribute.WRAP) == TRUE;
			var gap:Number = toPixels(Attribute.GAP, node, (isHorizontal ? width : height));
			var isAuto:Boolean = (isHorizontal ? node.width : node.height).isAuto;

			var i:int = 0;
			var lineLengthLimit:Number = isHorizontal ? width : height;
			var lineThicknessLimit:Number = isVertical ? width : height;

			while (i < node.numChildren)
			{
				line = new Line();

				// ----
				line.firstChildIndex = i;
				line.length = 0;
				line.thickness = 0;
				line.starAmount = 0;
				line.starLength = 0;

				for (i = line.firstChildIndex; i < node.numChildren; i++)
				{
					var child:Node = node.getChildAt(i);

					// If child require new line - break it
					var childIsBreak:Boolean = wrap && (line.firstChildIndex != i) && (child.getAttribute(Attribute.BREAK) == TRUE);
					if (childIsBreak) break;

					var size:Gauge = isHorizontal ? child.width : child.height;
					var minSize:Gauge = isHorizontal ? child.minWidth : child.minHeight;
					var maxSize:Gauge = isHorizontal ? child.maxWidth : child.maxHeight;
					var margin1:Gauge = isHorizontal ? child.margin.left : child.margin.top;
					var margin2:Gauge = isHorizontal ? child.margin.right : child.margin.bottom;

					var availableLength:Number = Math.max(0, lineLengthLimit - line.length);
					var availableThickness:Number = Math.max(0, lineThicknessLimit - line.thickness);

					var availableWidth:Number = isHorizontal ? availableLength : NaN;
					var availableHeight:Number = isVertical ? availableLength : NaN;

					// Define margin
					var margin:Number = 0;
					margin += margin1.toPixels(child.ppmm, child.ppem, node.pppt, lineLengthLimit, width, height, 0, 0);
					margin += margin2.toPixels(child.ppmm, child.ppem, node.pppt, lineLengthLimit, width, height, 0, 0);

					// Star unit doesn't add any length
					if (size.unit == Gauge.STAR)
					{
						line.childrenOffset[line.childrenOffset.length] = line.length;
						line.childrenLength[line.childrenLength.length] = -size.amount;

						line.starAmount += size.amount;
						if (i != line.firstChildIndex) line.length += gap;

					}
					else
					{
						// Define size
						var childLength:Number = getSize(size, minSize, maxSize, child.ppmm, child.ppem, child.pppt, lineLengthLimit, availableWidth, availableHeight, 0, 0) + margin;
						if (i != line.firstChildIndex) childLength += gap;

						if (wrap && (i != line.firstChildIndex) && !isAuto)
						{
							var isOverflow:Boolean = line.length + childLength > lineLengthLimit;
							if (isOverflow) break;
						}

						line.childrenOffset[line.childrenOffset.length] = line.length + gap;
						line.childrenLength[line.childrenLength.length] = childLength - gap;
						line.length += childLength;
					}

					line.lastChildIndex = i;

					// Calculate line thickness
					size = isVertical ? child.width : child.height;
					minSize = isVertical ? child.minWidth : child.minHeight;
					maxSize = isVertical ? child.maxWidth : child.maxHeight;
					margin1 = isVertical ? child.margin.left : child.margin.top;
					margin2 = isVertical ? child.margin.right : child.margin.bottom;

					margin = margin1.toPixels(node.ppmm, node.ppem, node.pppt, lineThicknessLimit, width, height, 0, 0) + margin2.toPixels(node.ppmm, node.ppem, node.pppt, lineThicknessLimit, width, height, 0, 0);
					var childThickness:Number = getSize(size, minSize, maxSize, child.ppmm, child.ppem, child.pppt, lineThicknessLimit, availableWidth, availableHeight, 0, 0);
					line.thickness = Math.max(line.thickness,  childThickness + margin);
					line.childrenThickness[line.childrenThickness.length] = childThickness;
				}

				line.starLength = Math.max(0, lineLengthLimit - line.length);
				result.push(line);
				//-------------
			}

			for each (line in result)
			{
				if (line.starAmount != 0)
				{
					var pps:Number = line.starAmount/line.starLength * line.length;
					for (i = 0; i < line.childrenLength; i++)
						if (line.childrenLength[i] < 0) line.childrenLength[i] *= -pps;
				}
			}

			return result;
		}

		private function getSize(size:Gauge, min:Gauge, max:Gauge, ppmm:Number, ppem:Number, pppt:Number, percentTarget:Number = 0, aw:Number = 0, ah:Number = 0, starTarget:Number = 0, starCount:Number = 0):Number
		{
			var value:Number = size.toPixels(ppmm, ppem, pppt, percentTarget, aw, ah, starTarget, starCount);
			if (!min.isNone) value = Math.max(value, min.toPixels(ppmm, ppem, pppt, percentTarget, aw, ah, starTarget, starCount));
			if (!max.isNone) value = Math.min(value, max.toPixels(ppmm, ppem, pppt, percentTarget, aw, ah, starTarget, starCount));
			return value;
		}
	}
}

import flash.geom.Rectangle;

class Line
{
	public var firstChildIndex:int;
	public var lastChildIndex:int;

	public var length:Number;
	public var thickness:Number;

	public var starLength:Number;
	public var starAmount:Number;

	public const childrenOffset:Vector.<Number> = new <Number>[];
	public const childrenLength:Vector.<Number> = new <Number>[];
	public const childrenThickness:Vector.<Number> = new <Number>[];
}

class FlowBuilder
{
	// Phase 1
	public function begin(width:Number, height:Number, gap:Number, interline:Number, wrap:Boolean):void {}

	public function beginChild():void { }
	public function setChildMarginBefore():void { }
	public function setChildLength():void { }
	public function setChildMarginAfter():void { }
	public function setChildBreakMode():void { }
	public function setChildThickness():void { }

	public function end():void { }

	// Phase 2
	public function getChildBounds(index:int):Rectangle { return null }
	public function get measuredLength():int { return 0 }
	public function get measuredThickness():int { return 0 }
}