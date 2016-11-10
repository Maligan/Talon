package talon.browser.desktop.popups.widgets
{
	import feathers.controls.TextInput;
	import feathers.controls.text.BitmapFontTextEditor;
	import feathers.controls.text.TextFieldTextEditor;
	import feathers.core.ITextEditor;
	import feathers.events.FeathersEventType;
	import feathers.text.BitmapFontTextFormat;

	import flash.text.Font;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;

	import starling.events.Event;
	import starling.extensions.DisplayObjectBridge;
	import starling.rendering.Painter;
	import starling.text.BitmapFont;
	import starling.text.TextField;
	import starling.text.TextField;
	import starling.utils.Color;

	import talon.Attribute;
	import talon.Node;
	import talon.utils.ITalonElement;
	import talon.utils.ParseUtil;

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
			_bridge.addAttributeChangeListener(Attribute.PADDING, onPaddingChange);

			restrict = "0-9.,";
			maxChars = 5;

			// Create textEditor
			textEditorFactory = editorFactory;

			// Focus
			addEventListener(FeathersEventType.FOCUS_IN, onFocusIn);
			addEventListener(FeathersEventType.FOCUS_OUT, onFocusOut);
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

		private function onFocusIn(e:Event):void
		{
			node.states.insert(STATE_FOCUS);
		}

		private function onFocusOut(e:Event):void
		{
			node.states.remove(STATE_FOCUS);
		}

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
			paddingLeft = node.paddingLeft.toPixels(node.ppem, node.ppem, node.ppdp, 0);
			paddingRight = node.paddingRight.toPixels(node.ppem, node.ppem, node.ppdp, 0);
			paddingTop = node.paddingTop.toPixels(node.ppem, node.ppem, node.ppdp, 0);
			paddingBottom = node.paddingBottom.toPixels(node.ppem, node.ppem, node.ppdp, 0);
		}

		private function get textFormat():BitmapFontTextFormat
		{
			return textEditor ? BitmapFontTextEditor(textEditor).textFormat : null;
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