package talon.browser.desktop.utils
{
	import com.doitflash.Scroller;

	import flash.ui.Keyboard;
	import flash.utils.Dictionary;

	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.TouchEvent;
	import starling.extensions.ITalonDisplayObject;
	import starling.extensions.TalonFactory;
	import starling.extensions.TalonSprite;

	import talon.core.Attribute;
	import talon.core.Node;
	import talon.enums.State;
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
		private var _css:Boolean;
		
		private var _mapToData:Dictionary;
		private var _mapToView:Dictionary;
		private var _parents:Dictionary;
		
		public function Inspector(factory:TalonFactory, view:TalonSprite)
		{
			_factory = factory;
			_view = view; // factory.build(REF_INSPECTOR);

			_view.query("#filter").onTap(function():void
			{
				_css = !_css;
				if (_selection)
					setAttributes(_mapToData[_selection]);
			});
			
			

//			_scroller = new Scroller();
//			_scroller.content = _view;
//			_scroller.orientation = Orientation.VERTICAL;
//			_scroller.easeType = Easing.Linear_easeNone;
//			_scroller.duration = 0.3;
//			_scroller.holdArea = 10;
//			_scroller.isStickTouch = true;
//			_scroller.yPerc = 0;
			
//			_view.node.addListener(Event.RESIZE, function():void
//			{
//				_scroller.boundHeight = DisplayObject(_view).stage.stageHeight;
//				_scroller.content.y = 0;
//				_scroller.computeYPerc(false);
//				trace(_scroller.boundHeight);
//			});

//			DisplayObject(_view).addEventListener(TouchEvent.TOUCH, function(e:TouchEvent):void
//			{
//				var touch:Touch = e.getTouch(_scroller.content);
//				if (touch)
//				{
//					var point:Point = new Point(touch.globalX, touch.globalY);
//
//					if (touch.phase == TouchPhase.BEGAN)
//						_scroller.startScroll(point);
//					else if (touch.phase == TouchPhase.MOVED)
//						_scroller.startScroll(point);
//					else if (touch.phase == TouchPhase.ENDED)
//						_scroller.fling();
//				}
//			});

			view.addEventListener(Event.ADDED_TO_STAGE, onStageChange);
			view.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
//			view.removeFromParent(true);
		}

		private function onStageChange(e:Event):void
		{
			if (e.type == Event.ADDED_TO_STAGE)
				view.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			else
				view.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}

		private function onKeyDown(e:KeyboardEvent):void
		{
			if (_selection)
			{
				switch (e.keyCode)
				{
					case Keyboard.LEFT:
						if (Node(_mapToData[_selection]).numChildren > 0 && ParseUtil.parseBoolean(_selection.getAttributeCache("toggle")) == true)
							toggleNode(_selection, e.shiftKey || e.ctrlKey || e.altKey);
						else if (_parents[_selection])
							setSelection(findVisibleSibling(_selection, -1) || _parents[_selection]);
						break;

					case Keyboard.RIGHT:
						if (ParseUtil.parseBoolean(_selection.getAttributeCache("toggle")) == false)
							toggleNode(_selection, e.shiftKey || e.ctrlKey || e.altKey);
						else if (Node(_mapToData[_selection]).numChildren > 0)
							setSelection(findVisibleSibling(_selection, +1));
						break;

					case Keyboard.ENTER:
						toggleNode(_selection, e.shiftKey || e.ctrlKey || e.altKey);
						break;

					case Keyboard.DOWN:
						var nextChild:Node = findVisibleSibling(_selection, +1);
						if (nextChild) setSelection(nextChild);
						break;

					case Keyboard.UP:
						var prevChild:Node = findVisibleSibling(_selection, -1);
						if (prevChild) setSelection(prevChild);
						break;
				}
			}
		}

		private function findVisibleSibling(node:Node, step:int = +1):Node
		{
			var length:int = node.parent.numChildren;
			var index:int = node.parent.getChildIndex(node);

			for (var i:int=index+step; i>=0 && i<length; i += step)
			{
				var child:Node = node.parent.getChildAt(i);
				var visible:String = child.getAttributeCache(Attribute.VISIBLE);
				if (ParseUtil.parseBoolean(visible)) return child;
			}

			return null;
		}
		
		public function setTree(tree:Node):void
		{
			if (!view.visible) return;
			
			_mapToData = new Dictionary();
			_mapToView = new Dictionary();
			_parents = new Dictionary();
			_tree = tree;

			addTreeItems(_view.query("#tree")[0], _tree);
			_selection = _mapToView[_tree];
			_selection.setAttribute(Attribute.FILL, "$color.blue");
			setAttributes(_tree);
		}
		
		private function addTreeItems(tree:TalonSprite, node:Node, depth:int = 0, parent:Node = null):void
		{
			if (depth == 0)
				tree.removeChildren();

			var item:ITalonDisplayObject = _factory.build(REF_TREE_ITEM);
			var itemName:String = node.getAttributeCache(Attribute.TYPE);

			if (itemName == "div") itemName = "Container";
			if (itemName == "img") itemName = "Image";
			if (itemName == "txt") itemName = "Label";
			itemName = itemName.charAt(0).toUpperCase() + itemName.substr(1);

			item.query()
				.set("text", itemName)
				.set("info", node.getAttributeCache(Attribute.ID))
				.set("depth", depth)
				.set("paddingLeft", depth * 14)
				.set("visible", depth==0)
				.onTap(onTreeItemTap1, 1)
				.onTap(onTreeItemTap2, 2);

			item.node.getChildAt(0).states.set("empty", node.numChildren == 0);

			tree.addChild(item as DisplayObject);
			
			if (parent) _parents[item.node] = parent;
			
			_mapToData[item.node] = node;
			_mapToView[node] = item.node;

			for (var i:int = 0; i < node.numChildren; i++)
				addTreeItems(tree, node.getChildAt(i), depth + 1, item.node);
		}

		private function onTreeItemTap1(e:TouchEvent):void
		{
			if (ITalonDisplayObject(e.target).node.getAttributeCache(Attribute.ID) == "icon")
				onTreeItemTap2(e);
			else
				setSelection(ITalonDisplayObject(e.currentTarget).node)
		}

		private function setSelection(selection:Node):void
		{
			if (_selection != selection)
			{
				if (_selection)
					_selection.setAttribute(Attribute.FILL, null);

				_selection = selection;
				_selection.setAttribute(Attribute.FILL, "$color.blue");
				setAttributes(_mapToData[_selection]);
			}
		}

		private function toggleNode(toggled:Node, deep:Boolean = false):void
		{
			if (Node(_mapToData[toggled]).numChildren == 0) return;

			// Toggle
			var depth:int = toggled.getAttributeCache("depth");
			var index:int = toggled.parent.getChildIndex(toggled);

			var toggle:Boolean = !ParseUtil.parseBoolean(toggled.getAttributeCache("toggle"));

			toggled.setAttribute("toggle", toggle.toString());
			toggled.getChildAt(0).states.set(State.CHECKED, toggle);

			for (var i:int = index+1; i < toggled.parent.numChildren; i++)
			{
				var nextChild:Node = toggled.parent.getChildAt(i);
				var nextChildDepth:int = nextChild.getAttributeCache("depth");
				if (nextChildDepth > depth)
				{
					var nextChildParent:Node = _parents[nextChild];
					var parentToggle:Boolean = ParseUtil.parseBoolean(nextChildParent.getAttributeCache("toggle"));
					var parentVisible:Boolean = ParseUtil.parseBoolean(nextChildParent.getAttributeCache("visible"));

					var expanded:Boolean = (parentVisible && parentToggle);

					nextChild.setAttribute(Attribute.VISIBLE, expanded.toString());
					if (deep)
					{
						nextChild.setAttribute("toggle", expanded.toString());
						nextChild.getChildAt(0).states.set(State.CHECKED, expanded);
					}
				}
				else if (nextChildDepth == depth)
					break;

			}
		}

		private function onTreeItemTap2(e:TouchEvent):void
		{
			var toggled:Node = ITalonDisplayObject(e.currentTarget).node;
			var deep:Boolean = e.shiftKey || e.ctrlKey;
			toggleNode(toggled, deep);
		}
		
		private function setAttributes(node:Node):void
		{
			var attributes:TalonSprite = _view.query("#attributes")[0] as TalonSprite;
			var i:int = 0;

			for each (var attributeName:String in getList(node, _css))
			{
				var attribute:Attribute = node.getOrCreateAttribute(attributeName);
				
				var item:ITalonDisplayObject = null;
				if (i < attributes.numChildren)
				{
					item = attributes.getChildAt(i) as ITalonDisplayObject;
					item.node.setAttribute(Attribute.VISIBLE, "true");
				}
				else
				{
					item = _factory.build(REF_ATTRIBUTE);
					attributes.addChild(item as DisplayObject);
				}

				item.query()
					.set("name", attribute.name)
					.set("value", attribute.isResource ? attribute.value.substr(1) : attribute.value);

				item.node.getChildAt(0).states.set("empty", true);
				item.node.classes.set("setted", attribute.setted != null);

				i++;
			}
			
			for (var j:int = i; j < attributes.numChildren; j++)
				ITalonDisplayObject(attributes.getChildAt(j)).node.setAttribute(Attribute.VISIBLE, "false");
		}

		private function getList(node:Node, styled:Boolean):Vector.<String>
		{
			var result:Vector.<String> = new <String>[];

			for each (var attribute:Attribute in node.attributes)
			{
				if (attribute.name == Attribute.TYPE) continue;
				if (attribute.setted !== null || (styled && attribute.styled !== null))
					result.push(attribute.name)
			}

			result.sort(function(s1:String, s2:String):int
			{
				if (s1 > s2) return +1;
				if (s1 < s2) return -1;
				return 0;
			});

			return result;
		}

		public function get view():DisplayObject
		{
			return _view as DisplayObject;
		}
		
		public function get visible():Boolean { return ParseUtil.parseBoolean(_view.node.getAttributeCache(Attribute.VISIBLE)) }
		public function set visible(value:Boolean):void { view.visible = value; _view.node.setAttribute(Attribute.VISIBLE, value.toString()) }
	}
}
