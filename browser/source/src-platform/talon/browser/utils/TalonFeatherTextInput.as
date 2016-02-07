package talon.browser.utils
{
	import feathers.controls.TextInput;
	import feathers.controls.text.TextFieldTextEditor;
	import feathers.core.ITextEditor;
	import feathers.events.FeathersEventType;

	import flash.text.Font;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	import starling.events.Event;
	import starling.rendering.Painter;

	import talon.Attribute;
	import talon.Node;
	import talon.starling.DisplayObjectBridge;
	import talon.utils.ITalonElement;
	import talon.utils.StringParseUtil;

	public class TalonFeatherTextInput extends TextInput implements ITalonElement
	{
		private static const STATE_FOCUS:String = "focus";

		private var _node:Node;
		private var _bridge:DisplayObjectBridge;

		public function TalonFeatherTextInput()
		{
			_node = new Node();
			_node.addTriggerListener(Event.RESIZE, onResize);

			_bridge = new DisplayObjectBridge(this, _node);
			_bridge.addAttributeChangeListener(Attribute.FONT_NAME, onFontNameChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_SIZE, onFontSizeChange);
			_bridge.addAttributeChangeListener(Attribute.FONT_COLOR, onFontColorChange);
			_bridge.addAttributeChangeListener(Attribute.TEXT, onTextChange);

			restrict = "0-9.,";
			maxChars = 5;

			// Create textEditor
			textEditorFactory = buildTextEditor;
			validate();

			// Focus
			addEventListener(FeathersEventType.FOCUS_IN, onFocusIn);
			addEventListener(FeathersEventType.FOCUS_OUT, onFocusOut);
		}

		private function onFocusIn(e:Event):void
		{
			node.accessor.states.insert(STATE_FOCUS);
		}

		private function onFocusOut(e:Event):void
		{
			node.accessor.states.remove(STATE_FOCUS);
		}

		private function buildTextEditor():ITextEditor
		{
			var editor:TextFieldTextEditor = new TextFieldTextEditor();
			editor.textFormat = new TextFormat("Source Sans Pro", 14, 0XFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER);
			editor.embedFonts = true;
			editor.sharpness = -400;
			return editor;
		}

		private function onResize():void
		{
			x = node.bounds.x;
			y = node.bounds.y;
			width = node.bounds.width;
			height = node.bounds.height;
		}

		private function onFontNameChange():void
		{
			textFormat.font = node.getAttributeCache(Attribute.FONT_NAME);
			var fonts:Array = Font.enumerateFonts(false).map(getFontName);
			TextFieldTextEditor(textEditor).embedFonts = fonts.indexOf(textFormat.font) != -1;
			validate();
		}

		private function getFontName(font:Font, index:int, array:Array):String
		{
			return font.fontName;
		}

		private function onFontSizeChange():void { textFormat.size = parseFloat(node.getAttributeCache(Attribute.FONT_SIZE)); }
		private function onFontColorChange():void { textFormat.color = StringParseUtil.parseColor(node.getAttributeCache(Attribute.FONT_COLOR)); }
		private function onTextChange():void { text = node.getAttributeCache(Attribute.TEXT); }

		public function get textFormat():TextFormat
		{
			return TextFieldTextEditor(textEditor).textFormat
		}

		public override function render(painter:Painter):void
		{
			_bridge.renderBackground(painter);

			super.render(painter);
		}

		public function get node():Node
		{
			return _node;
		}
	}
}