package talon.browser.desktop.utils
{
	import com.doitflash.Scroller;
	import com.doitflash.consts.Easing;
	import com.doitflash.consts.Orientation;

	import flash.geom.Point;
	import flash.utils.Dictionary;

	import starling.display.DisplayObject;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.ITalonDisplayObject;
	import starling.extensions.TalonFactory;
	import starling.extensions.TalonSprite;

	import talon.core.Attribute;
	import talon.core.Node;
	import talon.utils.ParseUtil;

	public class Inspector
	{
		private static const REF_INSPECTOR:String = "Inspector";
		private static const REF_TREE_ITEM:String = "TreeItem";
		private static const REF_ATTRIBUTE:String = "Attribute";
		
		private var _attCache:Vector.<ITalonDisplayObject> = new <ITalonDisplayObject>[];
		
		private var _factory:TalonFactory;
		private var _view:ITalonDisplayObject;
		private var _scroller:Scroller;
		
		private var _tree:Node;
		private var _selection:Node;
		
		private var _mapToData:Dictionary;
		private var _mapToView:Dictionary;
		private var _parents:Dictionary;
		
		public function Inspector(factory:TalonFactory)
		{
			_factory = factory;
			_view = factory.build(REF_INSPECTOR);

			_scroller = new Scroller();
			_scroller.content = _view;
			_scroller.orientation = Orientation.VERTICAL;
			_scroller.easeType = Easing.Quad_easeOut;
			_scroller.duration = 0.3;
			_scroller.holdArea = 10;
			_scroller.isStickTouch = true;
			_scroller.yPerc = 0;
			_scroller.boundHeight = 600;

			DisplayObject(_view).addEventListener(TouchEvent.TOUCH, function(e:TouchEvent):void
			{
				var touch:Touch = e.getTouch(_scroller.content);
				if (touch)
				{
					var point:Point = new Point(touch.globalX, touch.globalY);

					if (touch.phase == TouchPhase.BEGAN)
						_scroller.startScroll(point);
					else if (touch.phase == TouchPhase.MOVED)
						_scroller.startScroll(point);
					else if (touch.phase == TouchPhase.ENDED)
						_scroller.fling();
				}
			});

		}
		
		public function setTree(tree:Node):void
		{
			_mapToData = new Dictionary();
			_mapToView = new Dictionary();
			_parents = new Dictionary();
			_tree = tree;

			addTreeItems(_view.query("#tree")[0], _tree);
			setAttributes(_tree);
		}
		
		private function addTreeItems(tree:TalonSprite, node:Node, depth:int = 0, parent:Node = null):void
		{
			if (depth == 0)
				tree.removeChildren();

			var item:ITalonDisplayObject = _factory.build(REF_TREE_ITEM);
			var itemOffset:int = (4 + depth*14);
			var itemName:String = node.getAttributeCache(Attribute.TYPE);
			
			if (node.getAttributeCache(Attribute.ID) != null)
				itemName = "#" + node.getAttributeCache(Attribute.ID);

			item.query()
				.set("text", itemName)
				.set("icon", node.numChildren > 0 ? "$drop_right" : "none")
				.set("info", "")
				.set("depth", depth)
				.set("paddingLeft", itemOffset)
				.set("visible", depth==0)
				.onTap(onTreeItemTap, 1);
//				.onTap(onTreeItemTap2, 2);
			
			tree.addChild(item as DisplayObject);
			
			if (parent) _parents[item.node] = parent;
			
			_mapToData[item.node] = node;
			_mapToView[node] = item.node;

			for (var i:int = 0; i < node.numChildren; i++)
				addTreeItems(tree, node.getChildAt(i), depth + 1, item.node);
		}
		
		private function onTreeItemTap(e:TouchEvent):void
		{
			if (_selection) _selection.setAttribute(Attribute.FILL, null);
			_selection = ITalonDisplayObject(e.currentTarget).node;
			_selection.setAttribute(Attribute.FILL, "$color.blue");
			setAttributes(_mapToData[_selection]);
			
			onTreeItemTap2(e);
		}
		
		private function onTreeItemTap2(e:TouchEvent):void
		{
			// Toggle
			var depth:int = _selection.getAttributeCache("depth");
			var index:int = _selection.parent.getChildIndex(_selection);

			var toggle:Boolean = ParseUtil.parseBoolean(_selection.getAttributeCache("toggle"));

			_selection.setAttribute("toggle", String(!toggle));
			_selection.setAttribute("icon", Node(_mapToData[_selection]).numChildren ? (toggle ? "$drop_right" : "$drop_down") : "none");

			for (var i:int = index+1; i < _selection.parent.numChildren; i++)
			{
				var nextChild:Node = _selection.parent.getChildAt(i);
				var nextChildDepth:int = nextChild.getAttributeCache("depth");
				if (nextChildDepth > depth)
				{
					var nextChildParent:Node = _parents[nextChild];
					var parentToggle:Boolean = ParseUtil.parseBoolean(nextChildParent.getAttributeCache("toggle"));
					var parentVisible:Boolean = ParseUtil.parseBoolean(nextChildParent.getAttributeCache("visible"));

					nextChild.setAttribute(
						Attribute.VISIBLE,
						(parentVisible && parentToggle).toString()
					);
				}
				else if (nextChildDepth == depth)
					break;

			}
		}
		
		private function setAttributes(node:Node):void
		{
			var attributes:TalonSprite = _view.query("#attributes")[0] as TalonSprite;
			while (attributes.numChildren > 0) _attCache.push(attributes.removeChildAt(0));

			for each (var attribute:Attribute in node.attributes)
			{
				if (attribute.name == Attribute.TYPE) continue;
				if (attribute.setted || attribute.styled)
				{
					var item:ITalonDisplayObject = _attCache.pop() || _factory.build(REF_ATTRIBUTE);
					
					item.query()
						.set("name", attribute.name)
						.set("value", attribute.value)
						.set("composite", 0);

					item.node.classes.set("setted", attribute.setted);
					
					attributes.addChild(item as DisplayObject);
				}
			}
		}

		public function get view():DisplayObject
		{
			return _view as DisplayObject;
		}
	}
}
