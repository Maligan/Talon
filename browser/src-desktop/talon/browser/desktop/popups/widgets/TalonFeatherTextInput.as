package talon.browser.desktop.popups.widgets
{
	import feathers.controls.TextInput;
	import feathers.controls.text.BitmapFontTextEditor;
	import feathers.controls.text.BitmapFontTextEditor;
	import feathers.core.ITextEditor;
	import feathers.events.FeathersEventType;
	import feathers.text.BitmapFontTextFormat;

	import flash.geom.Rectangle;

	import starling.events.Event;
	import starling.extensions.ITalonDisplayObject;
	import starling.extensions.TalonDisplayObjectBridge;
	import starling.extensions.TalonQuery;
	import starling.rendering.Painter;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.text.TextFormat;

	import talon.core.Attribute;
	import talon.core.Node;
	import talon.core.Style;
	import talon.enums.State;
	import talon.utils.ParseUtil;

	public class TalonFeatherTextInput extends TextInput implements ITalonDisplayObject
	{
		private var _bridge:TalonDisplayObjectBridge;

		public function TalonFeatherTextInput()
		{
			_bridge = new TalonDisplayObjectBridge(this);
			_bridge.setAttributeChangeListener(Attribute.TEXT, onTextChange);
			_bridge.setAttributeChangeListener(Attribute.PADDING, onPaddingChange);

			node.addListener(Event.RESIZE, onResize);

			restrict = "0-9.,";
			maxChars = 5;
			
			textEditorFactory = editorFactory;
		}

		public override function dispose():void
		{
			removeFocusListeners();
			super.dispose();
		}

		protected override function createTextEditor():void
		{
			removeFocusListeners();
			super.createTextEditor();
			addFocusListeners();
		}

		private function editorFactory():ITextEditor
		{
			var fontName:String = node.getAttributeCache(Attribute.FONT_NAME);
			var fontSize:int = node.metrics.ppem;
			var fontColor:int = ParseUtil.parseColor(node.getAttributeCache(Attribute.FONT_COLOR));
			
			var editor:BitmapFontTextEditor = new BitmapFontTextEditor();
			editor.textFormat = new BitmapFontTextFormat(fontName, fontSize, fontColor);
			return editor;
		}

		// focus

		private function removeFocusListeners():void
		{
			if (nativeFocus)
			{
				nativeFocus.removeEventListener(FeathersEventType.FOCUS_IN, onFocusIn);
				nativeFocus.removeEventListener(FeathersEventType.FOCUS_OUT, onFocusOut);
			}
		}

		private function addFocusListeners():void
		{
			nativeFocus.addEventListener(FeathersEventType.FOCUS_IN, onFocusIn);
			nativeFocus.addEventListener(FeathersEventType.FOCUS_OUT, onFocusOut);
		}

		private function onFocusIn(e:*):void
		{
			node.states.put(State.FOCUS, true);
		}

		private function onFocusOut(e:*):void
		{
			node.states.put(State.FOCUS, false);
		}

		// node

		private function onResize():void
		{
			width = node.bounds.width;
			height = node.bounds.height;
		}

		private function onTextChange():void { text = node.getAttributeCache(Attribute.TEXT); }
		
		private function onPaddingChange():void
		{
			paddingLeft = node.paddingLeft.toPixels();
			paddingRight = node.paddingRight.toPixels();
			paddingTop = node.paddingTop.toPixels();
			paddingBottom = node.paddingBottom.toPixels();
		}


		public override function render(painter:Painter):void
		{
			_bridge.renderCustom(super.render, painter);
		}

		//
		// ITalonDisplayObject
		//

		public function query(selector:String = null):TalonQuery { return new TalonQuery(this).select(selector); }
		public function get rectangle():Rectangle { return node.bounds; }

		public function get node():Node { return _bridge.node; }
		public function setAttribute(name:String, value:String):void { node.setAttribute(name, value); }
		public function getAttribute(name:String):String { return node.getAttributeCache(name); }
		public function setStyles(styles:Vector.<Style>):void { node.setStyles(styles); }
		public function setResources(resources:Object):void { node.setResources(resources); }
	}
}