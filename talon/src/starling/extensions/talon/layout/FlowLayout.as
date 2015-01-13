package starling.extensions.talon.layout
{
	import starling.extensions.talon.core.Gauge;
	import starling.extensions.talon.core.Node;
	import starling.extensions.talon.utils.Attributes;
	import starling.extensions.talon.utils.Orientation;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	public class FlowLayout extends Layout
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

			var orientation:String = node.getAttribute(Attributes.ORIENTATION);
			if (Orientation.isValid(orientation) === false) throw new Error("Attribute orientation has invalid value: " + orientation);

			var paddingLeft:Number = node.padding.left.toPixels(node.ppmm, node.ppem, node.pppt, width, width, height, 0, 0);
			var paddingTop:Number = node.padding.top.toPixels(node.ppmm, node.ppem, node.pppt, height, width, height, 0, 0);

			width -= paddingLeft + node.padding.right.toPixels(node.ppmm, node.ppem, node.pppt, width, width, height, 0, 0);
			height -= paddingTop + node.padding.bottom.toPixels(node.ppmm, node.ppem, node.pppt, height, width, height, 0, 0);

			var gap:Number = toPixels(Attributes.GAP, node, (orientation == Orientation.HORIZONTAL? width : height));
			var interline:Number = toPixels(Attributes.INTERLINE, node, (orientation == Orientation.HORIZONTAL ? width : height));

			var lines:Vector.<Line> = measure(node, width, height);
			var totalLength:Number = orientation==Orientation.HORIZONTAL?width:height;
			var totalThickness:Number = orientation==Orientation.HORIZONTAL?height:width;

			var lengthAlign:Number = 0;
			var thicknessAlign:Number = 0;
			var valign:String = node.getAttribute(Attributes.VALIGN);
			var halign:String = node.getAttribute(Attributes.HALIGN);

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
				offsetGap = 0;

				var deltaLength:Number = (totalLength - line.length)*lengthAlign;
				var deltaThickness:Number = (totalThickness - sumThickness)*thicknessAlign;

				for (var i:int = line.firstChildIndex; i <= line.lastChildIndex; i++)
				{
					var child:Node = node.getChildAt(i);

					if (orientation == Orientation.HORIZONTAL)
					{
						child.bounds.width = getSize(child.width, child.minWidth, child.maxWidth, child.ppmm, child.ppem, child.pppt, width, line.starLength, line.starAmount);
						child.bounds.height = getSize(child.height, child.minHeight, child.maxHeight, child.ppmm, child.pppt, node.ppem, height, line.thickness, 1);
						offsetGap += child.margin.left.toPixels(node.ppmm, node.ppem, node.pppt, width, width, height, 0, 0);
						child.bounds.x = offsetGap;
						offsetGap += child.bounds.width;
						offsetGap += child.margin.right.toPixels(node.ppmm, node.ppem, node.pppt, width, width, height, 0, 0);
						offsetGap += gap;
						child.bounds.y = offsetInterline + child.margin.top.toPixels(node.ppmm, node.ppem, node.pppt, height, width, height, 0, 0);

						child.bounds.x += deltaLength;
						child.bounds.y += deltaThickness;
					}
					else
					{
						child.bounds.width = getSize(child.width, child.minWidth, child.maxWidth, child.ppmm, child.ppem, child.pppt, width, line.thickness, 1);
						child.bounds.height = getSize(child.height, child.minHeight, child.maxHeight, child.ppmm, node.ppem, child.pppt, height, line.starLength, line.starAmount);
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

		private function measureSide(node, side:String, width:Number, height:Number):Number
		{
			var orientation:String = node.getAttribute(Attributes.ORIENTATION);
			if (Orientation.isValid(orientation) === false) throw new Error("Attribute orientation has invalid value: " + orientation);
			return getMeasureSize(measure(node, width, height), orientation == side, toPixels(Attributes.INTERLINE, node, orientation==Orientation.HORIZONTAL?height:width));
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

			var orientation:String = node.getAttribute(Attributes.ORIENTATION);
			var isHorizontal:Boolean = orientation == Orientation.HORIZONTAL;
			var isVertical:Boolean = orientation == Orientation.VERTICAL;

			var wrap:Boolean = node.getAttribute(Attributes.WRAP) == TRUE;
			var gap:Number = toPixels(Attributes.GAP, node, (isHorizontal ? width : height));
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
					var childIsBreak:Boolean = wrap && (line.firstChildIndex != i) && (child.getAttribute(Attributes.BREAK) == TRUE);
					if (childIsBreak) break;

					var size:Gauge = isHorizontal ? child.width : child.height;
					var minSize:Gauge = isHorizontal ? child.minWidth : child.minHeight;
					var maxSize:Gauge = isHorizontal ? child.maxWidth : child.maxHeight;
					var margin1:Gauge = isHorizontal ? child.margin.left : child.margin.top;
					var margin2:Gauge = isHorizontal ? child.margin.right : child.margin.bottom;

					// Define margin
					var margin:Number = 0;
					margin += margin1.toPixels(child.ppmm, child.ppem, node.pppt, lineLengthLimit, width, height, 0, 0);
					margin += margin2.toPixels(child.ppmm, child.ppem, node.pppt, lineLengthLimit, width, height, 0, 0);

					// Star unit doesn't add any length
					if (size.unit == Gauge.STAR)
					{
						line.starAmount += size.amount;
						if (i != line.firstChildIndex) line.length += gap;
					}
					else
					{
						// Define size
						var childLength:Number = getSize(size, minSize, maxSize, child.ppmm, child.ppem, lineLengthLimit, 0, 0) + margin;
						if (i != line.firstChildIndex) childLength += gap;

						if (wrap && (i != line.firstChildIndex) && !isAuto)
						{
							var isOverflow:Boolean = line.length + childLength > lineLengthLimit;
							if (isOverflow) break;
						}

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
					line.thickness = Math.max(line.thickness, getSize(size, minSize, maxSize, child.ppmm, child.ppem, lineThicknessLimit, 0, 0) + margin);
				}

				line.starLength = Math.max(0, lineLengthLimit - line.length);
				result.push(line);
				//-------------
			}

			return result;
		}

		private function getSize(size:Gauge, min:Gauge, max:Gauge, ppmm:Number, ppem:Number, pppt:Number, percentTarget:Number, starTarget:Number = 0, starCount:Number = 0):Number
		{
			var value:Number = size.toPixels(ppmm, ppem, pppt, percentTarget, 0, 0, starTarget, starCount);
			if (!min.isNone) value = Math.max(value, min.toPixels(ppmm, ppem, pppt, percentTarget, 0, 0, starTarget, starCount));
			if (!max.isNone) value = Math.min(value, max.toPixels(ppmm, ppem, pppt, percentTarget, 0, 0, starTarget, starCount));
			return value;
		}
	}
}

class Line
{
	public var firstChildIndex:int;
	public var lastChildIndex:int;

	public var length:Number;
	public var thickness:Number;

	public var starLength:Number;
	public var starAmount:Number;
}