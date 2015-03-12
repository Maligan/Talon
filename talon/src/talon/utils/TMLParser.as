package talon.utils
{
	import flash.events.EventDispatcher;

	public final class TMLParser extends EventDispatcher
	{
		// Events
		public static const EVENT_BEGIN:String = "begin";
		public static const EVENT_END:String = "end";

		// Special keyword-tags
		private static const TAG_DEFINE:String = "define";
		private static const TAG_DEFINITION:String = "definition";
		private static const TAG_REWRITE:String = "rewrite";

		// Special keyword-attributes
		private static const ATT_ID:String = "id";
		private static const ATT_TYPE:String = "type";
		private static const ATT_BASE:String = "base";
		private static const ATT_REF:String = "ref";

		// Types
		private static const TYPE_DEFINE:String = "define";
		private static const TYPE_DEFINE_WITH_BASE:String = "defineWithBase";
		private static const TYPE_DEFINITION:String = "definition";
		private static const TYPE_DEFINITION_WITH_LINKAGE:String = "definitionWithLinkage";
		private static const TYPE_NODE:String = "node";

		//
		// Implementation
		//
		private var _scope:Object;
		private var _stack:TMLTemplateStack;

		public function TMLParser(scope:Object)
		{
			_scope = scope;
			_stack = new TMLTemplateStack();
		}

		public function parse(id:String):void
		{
			_stack.purge();
		}

		private function parseXML(xml:XML, attributes:Object, rewrites:Object):void
		{
			var type:String = getTokenType(xml);

			switch (type)
			{
				case TYPE_DEFINE:
					var templateId:String = getAttributeOrDie(xml, ATT_ID);
					var template:TMLTemplate = new TMLTemplate(templateId);
					var root:XML = xml.*[0];
					_stack.push(template);
					parseXML(root, attributes, rewrites);
					_stack.pop();
					break;

				case TYPE_DEFINE_WITH_BASE:
					var baseId:String = getAttributeOrDie(xml, ATT_BASE);
					var baseXML:XML = getFromScopeOrDie(baseId);
					parseXML(baseXML, attributes, fetchRewrites(xml, rewrites));
					break;

				case TYPE_DEFINITION:
					var refId:String = getAttributeOrDie(xml, ATT_REF);
					var refXML:XML = getFromScopeOrDie(refId);
					parseXML(refXML, fetchAttributes(xml) /* remove ref? */ , fetchRewrites(xml, rewrites));
					break;

				case TYPE_DEFINITION_WITH_LINKAGE:
					var type:String = xml.name();
					var typeXML:XML = getFromScopeOrDie(type);
					parseXML(typeXML, fetchAttributes(xml), fetchRewrites(xml, rewrites));
					break;

				case TYPE_NODE:
					var children:XMLList = xml.*; // Или rewrite
					var attributes:Object = fetchAttributes(xml, attributes); // Или rewrite, add type? (inherit from definition)
					dispatchBegin(attributes);
					for each (var child:XML in children) parseXML(child, null, null);
					dispatchEnd();
					break;

				default:
					throw new Error("Unknown token type");
			}
		}

		private function getTokenType(xml:XML):String
		{

		}

		//
		// Utility methods
		//
		private function getFromScopeOrDie(id:String):XML
		{
			return null;
		}

		private function getAttributeOrDie(xml:XML, attribute:String):String
		{
			return null;
		}

		/** Fetch attributes from XML to key-value pairs. */
		private function fetchAttributes(xml:XML, result:Object = null):Object
		{
			result = result || new Object();
			// merge?

			for each (var attribute:XML in xml.attributes())
			{
				var name:String = attribute.name();
				var value:String = attribute.toString();
				result[name] = value;
			}

			return result;
		}

		private function fetchRewrites(xml:XML, result:Object):Vector.<TMLRewrite>
		{
			return null
		}

		private function dispatchBegin(attributes:Object):void
		{
		}

		private function dispatchEnd():void
		{

		}
	}
}

class TMLTemplateStack
{
	public function push(template:TMLTemplate):void { }
	public function pop():void { }
	public function purge():void { }
}

class TMLTemplate
{
	public var id:String;
	public var rewrites:Vector.<TMLRewrite> = new <TMLRewrite>[];

	public function TMLTemplate(id:String, rewrites:XMLList = null) { }
}

class TMLRewrite
{
	public function apply():void
	{

	}
}