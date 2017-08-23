package
{
	import flash.events.Event;
	import flash.utils.Dictionary;

	import org.flexunit.Assert;

	import talon.core.Node;
	import talon.utils.TMLParser;

	public class TMLParserTest
	{
		private var _parser:TMLParser;
		private var _result:Node;
		private var _resultTags:Dictionary;

		[Before]
		public function reset():void
		{
			_resultTags = new Dictionary();

			_parser = new TMLParser();
			_parser.addEventListener(TMLParser.EVENT_BEGIN, onBegin);
			_parser.addEventListener(TMLParser.EVENT_END, onEnd);

			_parser.terminals.push("node");

			_parser.templates["NodeWithTag"] = <node />;
			_parser.templates["NodeWithoutTag"] = <node />;
			_parser.setUse("NodeWithTag", "nodeWithTag");
		}

		private function onBegin(e:Event):void
		{
			var node:Node = new Node();

			for each (var attributes:Object in _parser.attributes)
				for (var key:String in attributes)
					node.setAttribute(key, attributes[key]); // NB! Without binding

			_resultTags[node] = _parser.tags.concat();
			_result && _result.addChild(node);
			_result = node;
		}

		private function onEnd(e:Event):void
		{
			if (_result.parent)
				_result = _result.parent;
		}

		[Test]
		public function testWithoutTag():void
		{
			_parser.parse(<node id="testSimple" />);

			Assert.assertEquals("node", _resultTags[_result][0]);
			Assert.assertEquals("testSimple", _result.getAttributeCache("id"));
		}

		[Test]
		public function testWithTag():void
		{
			_parser.parse(<nodeWithTag id="testWithTag" />);

			Assert.assertEquals("testWithTag", _result.getAttributeCache("id"));
			Assert.assertEquals("nodeWithTag", _resultTags[_result][0]);
			Assert.assertEquals("node", _resultTags[_result][1]);
		}

		[Test]
		public function testTree():void
		{
			_parser.parse(
				<node>
					<node id="simple" />
					<use ref="NodeWithoutTag" />
					<use ref="NodeWithTag" />
					<nodeWithTag />
				</node>
			);

			Assert.assertNotNull(_result);
			Assert.assertEquals(4, _result.numChildren);

			// 1
			Assert.assertEquals("node", _resultTags[_result.getChildAt(0)][0]);
			Assert.assertEquals("simple", _result.getChildAt(0).getAttributeCache("id"));

			// 2
			Assert.assertEquals("node", _resultTags[_result.getChildAt(1)][0]);
			Assert.assertEquals(null, _result.getChildAt(1).getAttributeCache("id"));

			// 3
			Assert.assertEquals("nodeWithTag", _resultTags[_result.getChildAt(2)][0]);
			Assert.assertEquals("node", _resultTags[_result.getChildAt(2)][1]);

			// 4
			Assert.assertEquals("nodeWithTag", _resultTags[_result.getChildAt(3)][0]);
			Assert.assertEquals("node", _resultTags[_result.getChildAt(3)][1]);
		}

		[Test]
		public function testUpdateViaUse():void
		{
			_parser.parse(<use ref="NodeWithoutTag" update="id: ID; class: CLASS1 CLASS2 CLASS3;" />);

			Assert.assertEquals("ID", _result.getAttributeCache("id"));
			Assert.assertEquals("CLASS1 CLASS2 CLASS3", _result.getAttributeCache("class"));
		}

		[Test]
		public function testUpdateViaTag():void
		{
			_parser.parse(<nodeWithTag id="ID" class="CLASS1 CLASS2 CLASS3" />);

			Assert.assertEquals("ID", _result.getAttributeCache("id"));
			Assert.assertEquals("CLASS1 CLASS2 CLASS3", _result.getAttributeCache("class"));
		}
	}
}
