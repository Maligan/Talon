package talon.browser.desktop.popups.widgets
{
	import feathers.controls.TextInput;
	import feathers.controls.text.BitmapFontTextEditor;
	import feathers.core.ITextEditor;
	import feathers.events.FeathersEventType;
	import feathers.text.BitmapFontTextFormat;

	import starling.events.Event;
	import starling.extensions.ITalonDisplayObject;
	import starling.extensions.TalonDisplayObjectBridge;
	import starling.extensions.TalonQuery;
	import starling.rendering.Painter;
	import starling.text.TextField;

	import talon.core.Attribute;
	import talon.core.Node;
	import talon.enums.State;
	import talon.utils.ParseUtil;

	public class TalonFeatherTextInput extends TextInput implements ITalonDisplayObject
	{
		private var _node:Node;
		private var _bridge:TalonDisplayObjectBridge;

		public function TalonFeatherTextInput()
		{
			_node = new Node();
			_node.addListener(Event.RESIZE, onResize);

			_bridge = new TalonDisplayObjectBridge(this, _node);
			_bridge.setAttributeChangeListener(Attribute.FONT_NAME, onFontNameChange);
			_bridge.setAttributeChangeListener(Attribute.FONT_SIZE, onFontSizeChange);
			_bridge.setAttributeChangeListener(Attribute.FONT_COLOR, onFontColorChange);
			_bridge.setAttributeChangeListener(Attribute.TEXT, onTextChange);
			_bridge.setAttributeChangeListener(Attribute.PADDING, onPaddingChange);

			restrict = "0-9.,";
			maxChars = 5;

			// Create textEditor
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
			var editor:BitmapFontTextEditor = new BitmapFontTextEditor();

			editor.textFormat = new BitmapFontTextFormat(
				node.getAttributeCache(Attribute.FONT_NAME),
				node.getAttributeCache(Attribute.FONT_SIZE),
				ParseUtil.parseColor(node.getAttributeCache(Attribute.FONT_COLOR))
			);

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
			node.states.set(State.FOCUS, true);
		}

		private function onFocusOut(e:*):void
		{
			node.states.set(State.FOCUS, false);
		}

		// node

		private function onResize():void
		{
			x = node.bounds.x;
			y = node.bounds.y;

			width = node.bounds.width;
			height = node.bounds.height;
		}

		private function onFontNameChange():void { if (textFormat) textFormat.font = TextField.getBitmapFont(node.getAttributeCache(Attribute.FONT_NAME)); }
		private function onFontSizeChange():void { if (textFormat) textFormat.size = parseFloat(node.getAttributeCache(Attribute.FONT_SIZE)); }
		private function onFontColorChange():void { if (textFormat) textFormat.color = ParseUtil.parseColor(node.getAttributeCache(Attribute.FONT_COLOR)); }
		private function onTextChange():void { text = node.getAttributeCache(Attribute.TEXT); }
		private function onPaddingChange():void
		{
			paddingLeft = node.paddingLeft.toPixels(node.metrics);
			paddingRight = node.paddingRight.toPixels(node.metrics);
			paddingTop = node.paddingTop.toPixels(node.metrics);
			paddingBottom = node.paddingBottom.toPixels(node.metrics);
		}

		private function get textFormat():BitmapFontTextFormat
		{
			return textEditor ? BitmapFontTextEditor(textEditor).textFormat : null; }

		public override function render(painter:Painter):void
		{
			_bridge.renderCustom(super.render, painter);
		}

		//
		// ITalonDisplayObject
		//
		public function query(selector:String = null):TalonQuery { return new TalonQuery(this).select(selector); }

		public function get node():Node { return _node; }
	}
}